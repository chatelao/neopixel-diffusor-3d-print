# NeoPixel Diffuser Generator

A parametric OpenSCAD generator for 3D-printable NeoPixel diffuser attachments.

## Target Configurations

### 16x16 Matrix (160x160mm)
- **Dimensions:** 160x160mm
- **LED Pitch:** 10mm
- **Layout:** 16 rows, 16 columns

![16x16 Diffuser](images/diffuser_16x16.png)

### 8x32 Matrix (80x320mm)
- **Dimensions:** 80x320mm
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
- `led_pitch`: Distance between LED centers.
- `wall_thickness`: Width of the dividing walls.
- `diffusion_height`: Height of the diffuser cells.
- `cell_shape`: Shape of the cavities ("square" or "circular").
