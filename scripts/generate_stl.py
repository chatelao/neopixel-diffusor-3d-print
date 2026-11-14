import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import subprocess
import sys

REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = REPO_ROOT / "configs" / "panels.json"
SCAD_FILE = REPO_ROOT / "src" / "diffuser.scad"


def load_configs(config_path):
    if not os.path.exists(config_path):
        print(f"Error: Configuration file {config_path} not found.")
        sys.exit(1)

    try:
        with open(config_path, "r") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON configuration: {e}")
        sys.exit(1)


def validate_config(name, config):
    panel_type = config.get("type")
    if panel_type in ("matrix", "hex_matrix"):
        required_fields = ["type", "rows", "cols", "led_pitch"]
    elif panel_type == "ring":
        required_fields = ["type", "num_leds", "outer_diameter", "inner_diameter"]
    else:
        print(f"Error: Invalid or missing 'type' in config for {name}")
        return False

    for field in required_fields:
        if field not in config:
            print(f"Error: Missing required field '{field}' in config for {name}")
            return False

    wall_thickness = config.get("wall_thickness", 0.8)
    diffusion_height = config.get("diffusion_height", 10.0)
    bottom_thickness = config.get("bottom_thickness", 0.4)

    if wall_thickness <= 0:
        print(f"Error: 'wall_thickness' must be > 0 in config for {name}")
        return False
    if diffusion_height <= 0 or bottom_thickness < 0 or bottom_thickness >= diffusion_height:
        print(f"Error: Invalid 'bottom_thickness' / 'diffusion_height' in config for {name}")
        return False

    cell_shape = config.get("cell_shape", "square")
    if cell_shape not in ("square", "circular", "hexagonal"):
        print(f"Error: Invalid 'cell_shape' '{cell_shape}' in config for {name}")
        return False

    if panel_type in ("matrix", "hex_matrix"):
        rows = config["rows"]
        cols = config["cols"]
        led_pitch = config["led_pitch"]
        if rows <= 0 or cols <= 0 or led_pitch <= wall_thickness:
            print(f"Error: Invalid matrix dimensions in config for {name}")
            return False
        row_start = config.get("row_start", 0)
        row_end = config.get("row_end", rows - 1)
        if row_end == -1:
            row_end = rows - 1
        col_start = config.get("col_start", 0)
        col_end = config.get("col_end", cols - 1)
        if col_end == -1:
            col_end = cols - 1
        if not (0 <= row_start <= row_end < rows) or not (0 <= col_start <= col_end < cols):
            print(f"Error: Invalid segmentation bounds in config for {name}")
            return False
    elif panel_type == "ring":
        num_leds = config["num_leds"]
        outer_d = config["outer_diameter"]
        inner_d = config["inner_diameter"]
        if num_leds <= 0 or inner_d <= 0 or outer_d <= inner_d + 2 * wall_thickness:
            print(f"Error: Invalid ring dimensions in config for {name}")
            return False

    return True


def config_to_params(config):
    params = []
    for k, v in config.items():
        if isinstance(v, str):
            params.extend(["-D", f"{k}={json.dumps(v)}"])
        elif isinstance(v, bool):
            params.extend(["-D", f"{k}={'true' if v else 'false'}"])
        else:
            params.extend(["-D", f"{k}={v}"])
    return params


def run_openscad(params, stl_file, png_file, generate_png=True):
    scad_file = str(SCAD_FILE)
    stl_file = str(stl_file)
    png_file = str(png_file)

    stl_cmd = ["openscad", "-o", stl_file] + params + [scad_file]

    display = os.environ.get("DISPLAY")
    prefix = ["xvfb-run", "--auto-servernum"] if not display else []
    png_cmd = (
        prefix
        + [
            "openscad",
            "-o",
            png_file,
            "--imgsize=1024,768",
            "--viewall",
            "--autocenter",
        ]
        + params
        + [scad_file]
    )

    try:
        print(f"  Generating {stl_file}...")
        subprocess.run(stl_cmd, check=True)

        if generate_png:
            print(f"  Generating {png_file}...")
            subprocess.run(png_cmd, check=True)

    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error: OpenSCAD failed for {stl_file}: {e}")
        raise


def build_panel_tasks(panel_name, config, output_dir, image_dir, generate_png=True):
    if not validate_config(panel_name, config):
        raise ValueError(f"Invalid configuration for {panel_name}")

    os.makedirs(output_dir, exist_ok=True)
    if generate_png:
        os.makedirs(image_dir, exist_ok=True)

    tasks = []

    # Version 1: Original "all-in-one" (using config values)
    v1_config = config.copy()
    v1_config["part"] = "all"
    tasks.append(
        (
            config_to_params(v1_config),
            os.path.join(output_dir, f"diffuser_{panel_name}_v1.stl"),
            os.path.join(image_dir, f"diffuser_{panel_name}_v1.png"),
            generate_png,
        )
    )

    # Version 2: Fixed 0.7mm top layer
    v2_config = config.copy()
    v2_config["part"] = "all"
    v2_config["bottom_thickness"] = 0.7
    tasks.append(
        (
            config_to_params(v2_config),
            os.path.join(output_dir, f"diffuser_{panel_name}_v2.stl"),
            os.path.join(image_dir, f"diffuser_{panel_name}_v2.png"),
            generate_png,
        )
    )

    # Version 3: Separate body and 1.0mm lid
    v3_body_cfg = config.copy()
    v3_body_cfg["part"] = "body"
    v3_body_cfg["bottom_thickness"] = 1.0
    tasks.append(
        (
            config_to_params(v3_body_cfg),
            os.path.join(output_dir, f"diffuser_{panel_name}_v3_body.stl"),
            os.path.join(image_dir, f"diffuser_{panel_name}_v3_body.png"),
            generate_png,
        )
    )

    v3_lid_cfg = config.copy()
    v3_lid_cfg["part"] = "diffuser"
    v3_lid_cfg["bottom_thickness"] = 1.0
    tasks.append(
        (
            config_to_params(v3_lid_cfg),
            os.path.join(output_dir, f"diffuser_{panel_name}_v3_lid.stl"),
            os.path.join(image_dir, f"diffuser_{panel_name}_v3_lid.png"),
            generate_png,
        )
    )

    return tasks


def generate_versions(
    panel_name,
    config,
    output_dir=None,
    image_dir=None,
    generate_png=True,
    jobs=1,
):
    output_dir = str(output_dir or (REPO_ROOT / "stl"))
    image_dir = str(image_dir or (REPO_ROOT / "images"))
    tasks = build_panel_tasks(panel_name, config, output_dir, image_dir, generate_png)
    if jobs > 1:
        with ThreadPoolExecutor(max_workers=jobs) as executor:
            futures = [executor.submit(run_openscad, *t) for t in tasks]
            for fut in as_completed(futures):
                fut.result()
    else:
        for t in tasks:
            run_openscad(*t)


if __name__ == "__main__":
    configs = load_configs(CONFIG_FILE)

    parser = argparse.ArgumentParser(
        description="Generate NeoPixel Diffuser STLs and PNGs in 3 versions"
    )
    parser.add_argument(
        "--panel",
        choices=list(configs.keys()) + ["all"],
        default="all",
        help="Panel to generate files for",
    )
    parser.add_argument("--no-png", action="store_true", help="Skip PNG generation")
    parser.add_argument(
        "--jobs",
        type=int,
        default=os.cpu_count() or 4,
        help="Number of parallel OpenSCAD jobs",
    )
    args = parser.parse_args()

    output_dir = str(REPO_ROOT / "stl")
    image_dir = str(REPO_ROOT / "images")

    try:
        all_tasks = []
        selected = (
            configs.items() if args.panel == "all" else [(args.panel, configs[args.panel])]
        )
        for name, cfg in selected:
            print(f"Preparing tasks for panel: {name}")
            all_tasks.extend(
                build_panel_tasks(
                    name, cfg, output_dir, image_dir, generate_png=not args.no_png
                )
            )

        with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
            futures = [executor.submit(run_openscad, *t) for t in all_tasks]
            for fut in as_completed(futures):
                fut.result()
    except Exception as e:
        print(f"Execution failed: {e}")
        sys.exit(1)
