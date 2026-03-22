# NeoPixel Diffuser Generator

A parametric OpenSCAD generator for 3D-printable NeoPixel diffuser attachments.

## Live Preview
Explore the generated 3D models directly in your browser:
[https://chatelao.github.io/neopixel-diffusor-3d-print/](https://chatelao.github.io/neopixel-diffusor-3d-print/)

## Target Configurations

### 16x16 Matrix (160x160mm / 6.3x6.3")
- **Dimensions:** 160x160mm (6.3 x 6.3 inches)
- **LED Pitch:** 10mm
- **Layout:** 16 rows, 16 columns

![16x16 Diffuser](images/diffuser_16x16.png)

### 8x32 Matrix (80x320mm / 3.15x12.6")
- **Dimensions:** 80x320mm (3.15 x 12.6 inches)
- **LED Pitch:** 10mm
- **Layout:** 8 rows, 32 columns

![8x32 Diffuser](images/diffuser_8x32.png)

### 20-LED NeoPixel Ring (62mm OD)
- **Outer Diameter:** 62mm
- **Inner Diameter:** 47mm
- **LED Count:** 20

![Ring Diffuser](images/diffuser_ring_20.png)

## Usage

### Prerequisites
- OpenSCAD
- Python 3 (for automated generation)
- Xvfb (for headless rendering on Linux)

### Generating Files
To generate all STL and PNG files, run:
```bash
python3 scripts/generate_stl.py
```

To generate a specific panel:
```bash
python3 scripts/generate_stl.py --panel 16x16
```

## Customization
The OpenSCAD script `src/diffuser.scad` provides several parameters for customization:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `type` | `"matrix"` | Layout type: `"matrix"` or `"ring"`. |
| `led_pitch` | `10` | Center-to-center distance between LEDs (mm). |
| `tolerance` | `0.1` | Offset for fit (mm). |
| `wall_thickness` | `0.8` | Width of the dividing walls (mm). |
| `diffusion_height` | `10` | Distance from LED to diffuser top (mm). |
| `bottom_thickness` | `0.4` | Thickness of the top diffusion layer (mm). |
| `cell_shape` | `"square"` | Cavity shape: `"square"` or `"circular"`. |
| `draft_angle` | `0` | Angle of the side walls (degrees) for tapered cavities. |
| `frame_enabled` | `false` | If `true`, adds a reinforced outer frame. |
| `frame_width` | `2.0` | Thickness of the outer frame (mm). |
| `frame_radius` | `0.0` | Radius for rounded corners (mm). |
| `label_text` | `""` | Text to emboss on the frame. |
| `label_size` | `5.0` | Font size (mm) for the label. |
| `label_depth` | `0.5` | Depth of the embossed text (mm). |
| `cutout_enabled` | `false` | If `true`, adds cable cutouts. |
| `cutout_width` | `10` | Width of the cable cutout (mm). |
| `cutout_depth` | `3` | Depth of the cable cutout (mm). |
| `cutout_side` | `"bottom"` | Position of the cutout: `"left"`, `"right"`, `"top"`, `"bottom"` (matrix) or `"inner"`, `"outer"` (ring). |
| `mounting_holes_enabled` | `false` | If `true`, adds mounting tabs and holes. |
| `mounting_hole_dia` | `3.0` | Diameter of the mounting holes (mm). |
| `magnets_enabled` | `false` | If `true`, adds recesses for neodymium magnets in the mounting tabs. |
| `magnet_dia` | `6.1` | Diameter of the magnet recesses (mm). |
| `magnet_depth` | `2.0` | Depth of the magnet recesses (mm). |
| `rows` | `16` | Number of rows (matrix only). |
| `cols` | `16` | Number of columns (matrix only). |
| `num_leds` | `20` | Number of LEDs (ring only). |
| `outer_diameter` | `62` | Outer diameter of the ring (mm). |
| `inner_diameter` | `47` | Inner diameter of the ring (mm). |
