import subprocess
import os
import argparse
import sys

# Configuration for the different NeoPixel panels
PANEL_CONFIGS = {
    "16x16": {
        "led_pitch": 10,
        "rows": 16,
        "cols": 16,
        "type": "matrix"
    },
    "8x32": {
        "led_pitch": 10,
        "rows": 8,
        "cols": 32,
        "type": "matrix"
    },
    "ring_20": {
        "led_pitch": 10,  # Pitch here is used as approx arc distance if needed
        "num_leds": 20,
        "outer_diameter": 62,
        "inner_diameter": 47,
        "type": "ring"
    }
}

def generate_stl(panel_name, config, output_dir="stl"):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_file = os.path.join(output_dir, f"diffuser_{panel_name}.stl")
    scad_file = "src/diffuser.scad"

    # Construct OpenSCAD command
    # Passing variables via -D flag
    cmd = [
        "openscad",
        "-o", output_file,
    ]

    # Map config to OpenSCAD variables
    for key, value in config.items():
        # Correctly quote string values for OpenSCAD
        if isinstance(value, str):
            cmd.extend(["-D", f'{key}="{value}"'])
        else:
            cmd.extend(["-D", f"{key}={value}"])

    cmd.append(scad_file)

    print(f"Generating STL for {panel_name}...")
    print(f"Command: {' '.join(cmd)}")

    try:
        # Check if openscad is available
        subprocess.run(["openscad", "-v"], check=True, capture_output=True)
        subprocess.run(cmd, check=True)
        print(f"Successfully generated {output_file}")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error: OpenSCAD failed to run: {e}")
        # Re-raise to ensure script exits with non-zero status in CI
        raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate NeoPixel Diffuser STLs")
    parser.add_argument("--panel", choices=list(PANEL_CONFIGS.keys()) + ["all"], default="all", help="Panel to generate STL for")
    args = parser.parse_args()

    try:
        if args.panel == "all":
            for name, cfg in PANEL_CONFIGS.items():
                generate_stl(name, cfg)
        else:
            generate_stl(args.panel, PANEL_CONFIGS[args.panel])
    except Exception as e:
        sys.exit(1)
