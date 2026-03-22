import subprocess
import os
import argparse
import sys
import json

CONFIG_FILE = "configs/panels.json"

def load_configs(config_path):
    if not os.path.exists(config_path):
        print(f"Error: Configuration file {config_path} not found.")
        sys.exit(1)

    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON configuration: {e}")
        sys.exit(1)

def validate_config(name, config):
    required_fields = ["type"]
    if config.get("type") == "matrix" or config.get("type") == "hex_matrix":
        required_fields.extend(["rows", "cols", "led_pitch"])
    elif config.get("type") == "ring":
        required_fields.extend(["num_leds", "outer_diameter", "inner_diameter"])
    else:
        print(f"Error: Invalid or missing 'type' in config for {name}")
        return False

    for field in required_fields:
        if field not in config:
            print(f"Error: Missing required field '{field}' in config for {name}")
            return False
    return True

def generate_output(panel_name, config, output_dir="stl", image_dir="images", generate_png=True):
    if not validate_config(panel_name, config):
        raise ValueError(f"Invalid configuration for {panel_name}")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if generate_png and not os.path.exists(image_dir):
        os.makedirs(image_dir)

    part = config.get("part", "all")
    part_suffix = f"_{part}" if part != "all" else ""
    stl_file = os.path.join(output_dir, f"diffuser_{panel_name}{part_suffix}.stl")
    png_file = os.path.join(image_dir, f"diffuser_{panel_name}{part_suffix}.png")
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
        elif isinstance(value, bool):
            params.extend(["-D", f"{key}={'true' if value else 'false'}"])
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
    configs = load_configs(CONFIG_FILE)

    parser = argparse.ArgumentParser(description="Generate NeoPixel Diffuser STLs and PNGs")
    parser.add_argument("--panel", choices=list(configs.keys()) + ["all"], default="all", help="Panel to generate files for")
    parser.add_argument("--no-png", action="store_true", help="Skip PNG generation")
    args = parser.parse_args()

    try:
        if args.panel == "all":
            for name, cfg in configs.items():
                generate_output(name, cfg, generate_png=not args.no_png)
        else:
            generate_output(args.panel, configs[args.panel], generate_png=not args.no_png)
    except Exception as e:
        print(f"Execution failed: {e}")
        sys.exit(1)
