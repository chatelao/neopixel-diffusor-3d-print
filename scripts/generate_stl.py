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
        "led_pitch": 10,
        "num_leds": 20,
        "outer_diameter": 62,
        "inner_diameter": 47,
        "type": "ring"
    }
}

def generate_output(panel_name, config, output_dir="stl", image_dir="images", generate_png=True):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if generate_png and not os.path.exists(image_dir):
        os.makedirs(image_dir)

    stl_file = os.path.join(output_dir, f"diffuser_{panel_name}.stl")
    png_file = os.path.join(image_dir, f"diffuser_{panel_name}.png")
    scad_file = "src/diffuser.scad"

    # Base command for STL
    stl_cmd = ["openscad", "-o", stl_file]

    # Base command for PNG (with headless support)
    png_cmd = ["xvfb-run", "openscad", "-o", png_file, "--render", "--imgsize=1024,768"]

    # Add parameters
    params = []
    for key, value in config.items():
        if isinstance(value, str):
            params.extend(["-D", f'{key}="{value}"'])
        else:
            params.extend(["-D", f"{key}={value}"])

    stl_cmd.extend(params)
    stl_cmd.append(scad_file)

    png_cmd.extend(params)
    png_cmd.append(scad_file)

    try:
        # Generate STL
        print(f"Generating STL for {panel_name}...")
        subprocess.run(stl_cmd, check=True)
        print(f"Successfully generated {stl_file}")

        # Generate PNG
        if generate_png:
            print(f"Generating PNG for {panel_name}...")
            subprocess.run(png_cmd, check=True)
            print(f"Successfully generated {png_file}")

    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error: OpenSCAD failed to run for {panel_name}: {e}")
        raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate NeoPixel Diffuser STLs and PNGs")
    parser.add_argument("--panel", choices=list(PANEL_CONFIGS.keys()) + ["all"], default="all", help="Panel to generate files for")
    parser.add_argument("--no-png", action="store_true", help="Skip PNG generation")
    args = parser.parse_args()

    try:
        if args.panel == "all":
            for name, cfg in PANEL_CONFIGS.items():
                generate_output(name, cfg, generate_png=not args.no_png)
        else:
            generate_output(args.panel, PANEL_CONFIGS[args.panel], generate_png=not args.no_png)
    except Exception as e:
        sys.exit(1)
