import subprocess
import os
import sys

def verify_stl(filepath):
    print(f"Verifying {filepath}...")
    try:
        result = subprocess.run(['admesh', filepath], capture_output=True, text=True, check=True)
        output = result.stdout

        # Extract number of parts
        num_parts = 1
        for line in output.splitlines():
            if "Number of parts" in line:
                # Part count might be followed by volume on the same line in some versions
                parts_str = line.split(":")[1].strip().split()[0]
                num_parts = int(parts_str)
                break

        # Check for integrity markers
        is_manifold = "All facets connected.  No nearby check necessary." in output or "No unconnected need to be removed." in output
        no_holes = "No holes need to be filled." in output

        file_size_kb = os.path.getsize(filepath) / 1024

        # In case admesh had to fix something, it might not have the "No holes" string if it filled them.
        # But we want the original STL from OpenSCAD to be clean.

        status = "PASS"
        if "Total disconnected facets        :     0" not in output or not no_holes:
            status = "FAIL"

        # We flag models with many parts as a warning for print efficiency
        # For a single panel, it should ideally be 1 part.
        # But Version 1 (all-in-one) might have disconnected cells if walls are too thin or no overlap.
        # With the fix, we expect 1 part for matrix layouts.
        part_info = f"Parts: {num_parts}"
        if num_parts > 1:
            part_info += " [!] (Should be 1 for efficiency)"

        print(f"  [{status}] Size: {file_size_kb:.1f} KB, {part_info}")

        if status == "FAIL":
            print(output)
            return False
        return True

    except subprocess.CalledProcessError as e:
        print(f"  [ERROR] Failed to run admesh on {filepath}: {e}")
        return False

def main():
    stl_dir = "stl"
    if not os.path.exists(stl_dir):
        print(f"Error: {stl_dir} directory not found.")
        sys.exit(1)

    stls = [f for f in os.listdir(stl_dir) if f.endswith(".stl")]
    if not stls:
        print("No STL files found to verify.")
        return

    all_passed = True
    for stl in stls:
        if not verify_stl(os.path.join(stl_dir, stl)):
            all_passed = False

    if all_passed:
        print("\nAll STL files passed integrity check.")
    else:
        print("\nSome STL files failed integrity check.")
        sys.exit(1)

if __name__ == "__main__":
    main()
