import subprocess
import os
import sys

def verify_stl(filepath):
    print(f"Verifying {filepath}...")
    try:
        result = subprocess.run(['admesh', filepath], capture_output=True, text=True, check=True)
        output = result.stdout

        # Check for integrity markers
        is_manifold = "All facets connected.  No nearby check necessary." in output or "No unconnected need to be removed." in output
        no_holes = "No holes need to be filled." in output

        # In case admesh had to fix something, it might not have the "No holes" string if it filled them.
        # But we want the original STL from OpenSCAD to be clean.

        if "Total disconnected facets        :     0" in output and no_holes:
            print(f"  [PASS] {filepath} is manifold and has no holes.")
            return True
        else:
            print(f"  [FAIL] {filepath} has issues!")
            print(output)
            return False

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
