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
    if config.get("type") in ["matrix", "hex_matrix"]:
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

def config_to_params(config):
    params = []
    for k, v in config.items():
        if isinstance(v, str):
            params.extend(["-D", f'{k}="{v}"'])
        elif isinstance(v, bool):
            params.extend(["-D", f"{k}={'true' if v else 'false'}"])
        else:
            params.extend(["-D", f"{k}={v}"])
    return params

def run_openscad(params, stl_file, png_file, generate_png=True):
    scad_file = "src/diffuser.scad"

    # Base command for STL (using binary format for efficiency)
    stl_cmd = ["openscad", "-o", stl_file, "--export-format", "binstl"]
    stl_cmd.extend(params)
    stl_cmd.append(scad_file)

    # Base command for PNG (with headless support)
    display = os.environ.get("DISPLAY")
    prefix = ["xvfb-run", "--auto-servernum"] if not display else []
    png_cmd = prefix + ["openscad", "-o", png_file, "--render", "--imgsize=1024,768", "--viewall", "--autocenter"]
    png_cmd.extend(params)
    png_cmd.append(scad_file)

    try:
        # Generate STL
        print(f"  Generating {stl_file}...")
        subprocess.run(stl_cmd, check=True)

        # Generate PNG
        if generate_png:
            print(f"  Generating {png_file}...")
            subprocess.run(png_cmd, check=True)

    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error: OpenSCAD failed: {e}")
        raise

def generate_versions(panel_name, config, output_dir="stl", image_dir="images", generate_png=True):
    if not validate_config(panel_name, config):
        raise ValueError(f"Invalid configuration for {panel_name}")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if generate_png and not os.path.exists(image_dir):
        os.makedirs(image_dir)

    # Version 1: Original "all-in-one" (using config values)
    v1_config = config.copy()
    v1_config["part"] = "all"
    run_openscad(config_to_params(v1_config),
                os.path.join(output_dir, f"diffuser_{panel_name}_v1.stl"),
                os.path.join(image_dir, f"diffuser_{panel_name}_v1.png"),
                generate_png)

    # Version 2: Fixed 0.7mm top layer
    v2_config = config.copy()
    v2_config["part"] = "all"
    v2_config["bottom_thickness"] = 0.7
    run_openscad(config_to_params(v2_config),
                os.path.join(output_dir, f"diffuser_{panel_name}_v2.stl"),
                os.path.join(image_dir, f"diffuser_{panel_name}_v2.png"),
                generate_png)

    # Version 3: Separate body and 1.0mm lid
    # Body
    v3_body_cfg = config.copy()
    v3_body_cfg["part"] = "body"
    v3_body_cfg["bottom_thickness"] = 1.0
    run_openscad(config_to_params(v3_body_cfg),
                os.path.join(output_dir, f"diffuser_{panel_name}_v3_body.stl"),
                os.path.join(image_dir, f"diffuser_{panel_name}_v3_body.png"),
                generate_png)

    # Lid
    v3_lid_cfg = config.copy()
    v3_lid_cfg["part"] = "diffuser"
    v3_lid_cfg["bottom_thickness"] = 1.0
    run_openscad(config_to_params(v3_lid_cfg),
                os.path.join(output_dir, f"diffuser_{panel_name}_v3_lid.stl"),
                os.path.join(image_dir, f"diffuser_{panel_name}_v3_lid.png"),
                generate_png)

if __name__ == "__main__":
    configs = load_configs(CONFIG_FILE)

    parser = argparse.ArgumentParser(description="Generate NeoPixel Diffuser STLs and PNGs in 3 versions")
    parser.add_argument("--panel", choices=list(configs.keys()) + ["all"], default="all", help="Panel to generate files for")
    parser.add_argument("--no-png", action="store_true", help="Skip PNG generation")
    args = parser.parse_args()

    try:
        if args.panel == "all":
            for name, cfg in configs.items():
                print(f"Processing panel: {name}")
                generate_versions(name, cfg, generate_png=not args.no_png)
        else:
            print(f"Processing panel: {args.panel}")
            generate_versions(args.panel, configs[args.panel], generate_png=not args.no_png)
    except Exception as e:
        print(f"Execution failed: {e}")
        sys.exit(1)
