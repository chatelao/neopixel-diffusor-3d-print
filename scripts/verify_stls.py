import collections
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent


def parse_stl(filepath):
    """Parse an ASCII or binary STL file and return (vertices, triangles)."""
    with open(filepath, "rb") as f:
        data = f.read()

    verts = []
    tris = []
    vmap = {}

    def get_vid(pt):
        key = (round(pt[0], 4), round(pt[1], 4), round(pt[2], 4))
        if key not in vmap:
            vmap[key] = len(verts)
            verts.append(key)
        return vmap[key]

    # Check if binary STL: 80-byte header + 4-byte uint32 count + 50 bytes per triangle
    if len(data) >= 84:
        num_tris = struct.unpack("<I", data[80:84])[0]
        if 84 + num_tris * 50 == len(data) and not data.startswith(b"solid"):
            offset = 84
            for _ in range(num_tris):
                floats = struct.unpack("<12fH", data[offset : offset + 50])
                v1 = get_vid(floats[3:6])
                v2 = get_vid(floats[6:9])
                v3 = get_vid(floats[9:12])
                tris.append((v1, v2, v3))
                offset += 50
            return verts, tris

    # Parse ASCII STL
    cur = []
    for line in data.decode("utf-8", errors="ignore").splitlines():
        parts = line.strip().split()
        if len(parts) == 4 and parts[0] == "vertex":
            cur.append(get_vid((float(parts[1]), float(parts[2]), float(parts[3]))))
            if len(cur) == 3:
                tris.append(tuple(cur))
                cur = []
    return verts, tris


def analyze_mesh_topology(filepath):
    """Verify manifoldness, single connected component, and Z=0 build plate contact."""
    verts, tris = parse_stl(filepath)
    if not tris or not verts:
        return False, "Mesh is empty (0 triangles)."

    # 1. Check edge valence (every edge in a closed manifold must have even valence >= 2)
    edge_counts = collections.Counter()
    adj = collections.defaultdict(list)
    for a, b, c in tris:
        for u, v in ((a, b), (b, c), (c, a)):
            edge_counts[(min(u, v), max(u, v))] += 1
        adj[a].extend((b, c))
        adj[b].extend((a, c))
        adj[c].extend((a, b))

    open_edges = sum(1 for cnt in edge_counts.values() if cnt == 1)
    odd_edges = sum(1 for cnt in edge_counts.values() if cnt % 2 != 0)
    if open_edges > 0 or odd_edges > 0:
        return False, f"Mesh has {open_edges} open boundary edges and {odd_edges} non-manifold edges."

    # 2. Check connected components (must be 1 connected shell, not floating islands)
    visited = set()
    components = 0
    for idx in range(len(verts)):
        if idx not in visited and idx in adj:
            components += 1
            queue = collections.deque([idx])
            visited.add(idx)
            while queue:
                curr = queue.popleft()
                for nxt in adj[curr]:
                    if nxt not in visited:
                        visited.add(nxt)
                        queue.append(nxt)

    if components != 1:
        return False, f"Mesh is split into {components} disconnected parts (expected 1)."

    # 3. Check build plate contact (min Z should be ~0.0)
    min_z = min(v[2] for v in verts)
    if abs(min_z) > 0.05:
        return False, f"Mesh does not rest on build plate (min_z = {min_z:.2f}mm, expected 0.00mm)."

    return True, f"tris={len(tris)}, parts={components}, min_z={min_z:.2f}mm"


def verify_stl(filepath):
    print(f"Verifying {filepath}...")
    topo_ok, topo_msg = analyze_mesh_topology(filepath)
    if not topo_ok:
        print(f"  [FAIL] {filepath}: {topo_msg}")
        return False

    if shutil.which("admesh"):
        try:
            result = subprocess.run(
                ["admesh", str(filepath)], capture_output=True, text=True, check=True
            )
            output = result.stdout

            is_manifold = (
                "All facets connected.  No nearby check necessary." in output
                or "No unconnected need to be removed." in output
            )
            no_holes = "No holes need to be filled." in output
            no_disconnected = "Total disconnected facets        :     0" in output
            parts_match = re.search(r"Number of parts\s*:\s*(\d+)", output)
            num_parts = int(parts_match.group(1)) if parts_match else 1

            if is_manifold and no_holes and no_disconnected and num_parts == 1:
                print(f"  [PASS] {filepath} is manifold, 1 part, and has no holes ({topo_msg}).")
                return True
            else:
                print(f"  [FAIL] {filepath} failed admesh check (parts={num_parts})!")
                print(output)
                return False
        except subprocess.CalledProcessError as e:
            print(f"  [ERROR] Failed to run admesh on {filepath}: {e}")
            return False

    print(f"  [PASS] {filepath} passed topology check ({topo_msg}).")
    return True


def main():
    stl_dir = REPO_ROOT / "stl"
    if not stl_dir.exists():
        print(f"Error: {stl_dir} directory not found.")
        sys.exit(1)

    stls = sorted(f for f in os.listdir(stl_dir) if f.endswith(".stl"))
    if not stls:
        print("No STL files found to verify.")
        sys.exit(1)

    all_passed = True
    for stl in stls:
        if not verify_stl(stl_dir / stl):
            all_passed = False

    if all_passed:
        print("\nAll STL files passed integrity check.")
    else:
        print("\nSome STL files failed integrity check.")
        sys.exit(1)


if __name__ == "__main__":
    main()
