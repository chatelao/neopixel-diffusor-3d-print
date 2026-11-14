# Project Flaws & Technical Review

This document lists all architectural, geometric, scripting, CI/CD, and documentation flaws identified in the `neopixel-diffusor-3d-print` repository.

---

## 1. Critical 3D Geometry & OpenSCAD Flaws (`src/diffuser.scad`)

### 1.1 Capacitor Clearance Severs the Diffuser Layer into Hundreds of Floating Islands
- **Location:** `src/diffuser.scad` (lines 105–111)
- **Severity:** Critical (Unprintable / Disconnected Geometry)
- **Description:**
  In `cell()`, the model is oriented upside-down for printability: the thin front diffusion layer (`bottom_thickness = 0.4mm` in V1, `0.7mm` in V2) sits on the build plate (`z = 0` to `bottom_thickness`), and the open LED/PCB side is at the top (`z = diffusion_height = 10mm`).
  However, `cap_clearance` is subtracted at:
  ```openscad
  translate([led_pitch/2, 0, -diffusion_height/2 + cap_clearance_height/2])
  cube([cap_clearance_width, led_pitch + 0.1, cap_clearance_height + 0.1], center=true);
  ```
  1. **Wrong Z-side:** `-diffusion_height/2` corresponds to world `z = 0` (the front diffuser face), not the LED/PCB side (`z = diffusion_height`).
  2. **Full-perimeter cut:** The cutout length is `led_pitch + 0.1` across all four walls (`a = [0, 90, 180, 270]`) and its height (`cap_clearance_height = 1.5mm`) exceeds `bottom_thickness` (`0.4mm` and `0.7mm`).
- **Impact:**
  - Every cell's bottom diffusion face (`7.5 × 7.5mm`) is **completely severed** from the cell walls by a `2.5mm` wide trench running along its entire perimeter.
  - Generated STLs (`stl/diffuser_16x16_v1.stl`, `stl/diffuser_16x16_v2.stl`, `stl/diffuser_8x32_v1.stl`, `stl/diffuser_8x32_v2.stl`, `stl/diffuser_16x32_v1.stl`, `docs/stl/diffuser_16x16.stl`, `docs/stl/diffuser_8x32.stl`) contain **257 (or 513) separate, disconnected mesh shells** (256 or 512 loose squares on the build plate plus 1 hovering grid frame).
  - All internal grid walls start at `z = 1.5mm` in mid-air, requiring unsupported bridging across 80–320mm.

### 1.2 Ring Capacitor Clearance Cuts Through the Front Diffuser Face and Outer Walls
- **Location:** `src/diffuser.scad` (lines 597–602)
- **Severity:** High
- **Description:**
  In `ring_layout()`, `cap_clearance` is placed at `z = cap_clearance_height/2` (`z = 0` to `1.5mm`) with radial length `ring_width + 2`:
  ```openscad
  translate([radius, 0, cap_clearance_height/2])
  cube([ring_width + 2, cap_clearance_width, cap_clearance_height + 0.1], center=true);
  ```
- **Impact:**
  - Cuts 20 radial slots through the front optical diffusion layer (`z = 0..0.4mm`) instead of the PCB-facing side (`z = diffusion_height`).
  - Slices through both the inner and outer ring walls (`ring_width + 2`), leaving visible notches around the bottom perimeter of the ring.

### 1.3 Inverted Z-Placement of Cable Cutouts, Magnet Recesses, and Frame Labels
- **Location:** `src/diffuser.scad` (lines 287–331, 458–501, 548–565)
- **Severity:** High
- **Description:**
  - **Cable cutouts (`cutout_enabled`)** are placed at `z = cutout_depth/2 - 0.1` (`z = 0` to `cutout_depth`), cutting into the front visible diffuser surface rather than the back edge (`z = diffusion_height - cutout_depth` to `diffusion_height`) where the PCB and wires sit.
  - **Magnet recesses (`magnets_enabled`)** are placed at `z = -0.1` (`z = 0` to `magnet_depth`), putting the magnet pockets on the front diffuser surface instead of the rear PCB-facing surface (`z = diffusion_height - magnet_depth`).
  - **Frame labels (`label_text`)** are embossed at `z = diffusion_height - label_depth` (the rear PCB-facing side), where they face the LED panel instead of the exterior, and have default `label_size = 5.0mm` (or `4.0mm` in `hex_full_features`) on a `frame_width = 2.0mm` wall—causing text characters to spill out of the `2.0mm` frame and cut into adjacent LED cavities.

### 1.4 Broken Version 3 (`part = "body"` and `part = "diffuser"`) Geometry and Lid Fit
- **Location:** `src/diffuser.scad` (lines 135–143, 212–262, 392–433, 513–565, 607–614)
- **Severity:** Critical
- **Description:**
  1. **Frameless V3 Bodies Float in Mid-Air & Lack a Retaining Lip:**
     - In `cell()` (lines 135–143), `part == "body"` subtracts `led_pitch + 0.1` across every cell up to `z = bottom_thickness + 0.05` (`1.05mm`). When `frame_enabled == false` (e.g., `hex_sample`), the entire bottom `1.05mm` of the model is erased: `stl/diffuser_hex_sample_v3_body.stl` has a Z bounding box of `1.05mm..10.00mm` (floating above the build plate) and has **no outer wall or lip** to hold the V3 lid.
     - In `ring_layout()` (lines 607–614), when `frame_enabled == false` (true for both `ring_20` and `ring_20_magnets`), subtracting `outer_diameter + 0.1` to `inner_diameter - 0.1` at `z = 0..1.0mm` removes the entire bottom of the ring body while leaving the 4 mounting tabs protruding down to `z = 0`. As seen in `images/diffuser_ring_20_v3_body.png`, the main ring body hovers `1.0mm` in the air on 4 tiny tab legs and has no outer lip to retain the lid.
  2. **Mounting Tabs, Holes, Magnets, and Cutouts Leak into V3 Lids (`part == "diffuser"`):**
     - In `matrix_layout()` (lines 392–411) and `hex_matrix_layout()` (lines 212–231), the mounting tab cylinders (`h = diffusion_height = 10mm`) are created outside `if (part == "all" || part == "body")`. Consequently, `diffuser_16x16_v3_lid.stl` (a `1.0mm` flat sheet) has **four `10mm` tall hollow cylinders** at its corners that are completely detached from the `lid_tolerance`-shrunk sheet (`comps = 5` disconnected parts, visible in `images/diffuser_16x16_v3_lid.png`).
     - In all three layout modules, `mounting_holes`, `magnets`, `cutout`, and `label_text` subtractions are not guarded by `if (part == "all" || part == "body")`. As a result:
       - `diffuser_ring_20_v3_lid.stl` has 4 semicircular mounting-hole notches bitten out of its outer perimeter (`images/diffuser_ring_20_v3_lid.png`).
       - `diffuser_8x32_v3_lid.stl` has the cable cutout (`frame_width + 2` deep) gouged out of its bottom edge (`images/diffuser_8x32_v3_lid.png`).
  3. **Matrix V3 Lid with `frame_radius > 0` Is Double-Translated:**
     - In `matrix_layout()` (lines 422–430), `translate([(lx_min+lx_max)/2, (ly_min+ly_max)/2, bottom_thickness/2])` translates to the lid center, and then the `if (frame_radius > 0)` branch translates again by `[lx_min + frame_radius, ly_min + frame_radius, 0]` (world coordinates instead of local coordinates), shifting the rounded lid completely off-center.
  4. **Hex-Matrix V3 Lid (`hex_matrix_layout()` lines 241–262) Misses Staggered Odd Rows:**
     - The `hull()` only loops over `for (r = [row_start, actual_row_end])` and `for (c = [col_start, actual_col_end])` (the 4 corner cells). When `actual_row_end` is even (e.g., `rows = 5` in `hex_sample`, where `actual_row_end = 4`), both corner rows have `x_offset = 0`, so the lid fails to cover the `+led_pitch / 2` horizontal stagger of all odd rows (`r = 1, 3`), leaving the rightmost odd-row cells half uncovered (`lx_max` in `diffuser_hex_sample_v3_lid.stl` stops at `44.80mm` while the body extends to `50.00mm`).

### 1.5 Mounting Holes and Magnet Recesses Breach LED Cavities
- **Location:** `src/diffuser.scad` (lines 212–231, 266–313, 392–411, 437–484, 525–554)
- **Severity:** High
- **Description:**
  - **Ring layout (`ring_20`, `ring_20_magnets`):** When `frame_enabled == false`, mounting tabs, `3.0mm` mounting holes, and `6.1mm` magnet pockets are centered at `actual_outer / 2 = 31.0mm`. The LED cavities extend radially to `r = 27.25 + 6.8/2 = 30.65mm`. Both the mounting holes (reaching `r = 29.5mm`) and magnet recesses (reaching `r = 27.95mm`) **cut directly into the 4 cardinal LED cavities** (clearly visible in `images/diffuser_ring_20_v3_body.png` and `images/diffuser_ring_20_magnets.png`).
  - **Matrix & Hex-Matrix layouts:** Mounting tabs and magnet recesses (`magnet_dia = 6.1mm`, radius `3.05mm`) are centered at `[x_min, y_min]`, which is only `frame_width = 2.0mm` (`2.83mm` diagonally) from the outer cell boundary, causing the `6.1mm` magnet pockets to cut through the inner frame boundary into the corner cells.

### 1.6 Hexagonal Matrix Frame & Cavity Math Errors and Non-Manifold Mesh Generation
- **Location:** `src/diffuser.scad` (lines 74–76, 121–123, 159–209)
- **Severity:** High
- **Description:**
  1. **Incorrect Y-bounds in `hex_matrix_layout()`:** A flat-to-flat hexagon of width `led_pitch` rotated by 30° has circumdiameter `led_pitch / cos(30) ≈ 1.1547 * led_pitch`, so its top and bottom vertices extend to `±0.57735 * led_pitch`. Lines 161–162 use `0.5 * led_pitch` instead of `0.5 / cos(30) * led_pitch`, causing hex cells to poke `0.77mm` into/through the top and bottom frames.
  2. **5mm Open Gaps Between Rectangular Frame and Staggered Hex Rows:** Because the frame is a straight rectangle spanning `x_min` to `x_max` while odd/even hex rows are staggered by `led_pitch / 2` (`5mm`), there is an unenclosed `5mm` void between the left frame and odd rows, and between the right frame and even rows.
  3. **Non-Manifold Edges (`bad_edges > 0`):** Every generated `hex_matrix` and `ring` STL in `stl/` (`diffuser_hex_sample*.stl` with 112 non-manifold edges, `diffuser_hex_full_features.stl` with 232 non-manifold edges, and `diffuser_ring_20*.stl` with 32 non-manifold edges) contains non-manifold edges due to exact face/edge coincidence without boolean overlap epsilon.
  4. **Incompatible `type` and `cell_shape` combinations:**
     - Using `cell_shape = "hexagonal"` with `type = "matrix"` creates a hex cavity of diameter `exit_dim / cos(30) = 10.74mm` inside a `10.0mm` square cell, slicing through the cell walls into neighboring cells.
     - Using `cell_shape = "circular"` with `type = "ring"` (line 577) uses `led_pitch` (`10mm`) instead of `ring_width` (`7.5mm`), creating `9.3mm` cavities that burst through the `7.5mm` wide ring walls.
     - Using `cell_shape = "hexagonal"` with `type = "ring"` is silently ignored and falls back to rectangular cavities.

### 1.7 Rounded Frame Corners (`frame_radius > 0`) Ignore Segmentation and Can Sever Corners
- **Location:** `src/diffuser.scad` (lines 174–186, 354–366)
- **Severity:** Medium
- **Description:**
  - When `frame_radius > 0`, the outer frame is a rounded `hull()`, but the subtracted interior (lines 185, 365) is a sharp-cornered `cube()`. If `frame_radius > frame_width / (1 - 1/sqrt(2)) ≈ 3.41 * frame_width`, the sharp interior cube cuts completely through the rounded outer corners.
  - Unlike the `frame_radius == 0` branch (which checks `col_start == 0`, `actual_col_end == cols - 1`, `row_start == 0`, `actual_row_end == rows - 1`), the `frame_radius > 0` branch wraps all four sides of a segmented panel, adding unwanted internal frame walls between segments.

### 1.8 Dead and Duplicate Code in `src/diffuser.scad`
- **Location:** `src/diffuser.scad` (lines 72–99, 115–116)
- **Severity:** Low
- **Description:**
  - Lines 72–79 (`if (part == "all")`) and lines 80–88 (`else if (part == "body")`) contain identical geometry blocks.
  - Lines 89–99 (`if (part == "diffuser")` inside `cell()`) are unreachable from `matrix_layout()` and `hex_matrix_layout()`, which only call `cell()` when `part == "all" || part == "body"`.
  - Lines 115–116 have identical ternary branches:
    ```openscad
    cavity_h = (part == "all" ? h + 0.1 : h + 0.1);
    z_offset = (part == "all" ? bottom_thickness/2 + 0.05 : bottom_thickness/2 + 0.05);
    ```

---

## 2. Python Automation & Verification Flaws (`scripts/`)

### 2.1 `scripts/verify_stls.py` Fails to Detect Disconnected Parts or Non-Manifold Edges (and Is Unused in CI)
- **Location:** `scripts/verify_stls.py` (lines 11–25)
- **Severity:** High
- **Description:**
  - `is_manifold` is computed on line 12 (`is_manifold = ...`) and **never referenced** in the `if` statement on line 18.
  - Checking `"Total disconnected facets : 0"` in `admesh` only checks for single unshared facets, not whether the mesh has shattered into 257 separate floating shells (`Number of parts` in `admesh`).
  - `verify_stls.py` is never executed in `.github/workflows/generate_stls.yml`.

### 2.2 Redundant Double-Rendering and Sequential Bottleneck in `scripts/generate_stl.py`
- **Location:** `scripts/generate_stl.py` (lines 48–75, 130–137)
- **Severity:** Medium
- **Description:**
  - `run_openscad()` invokes OpenSCAD twice for every single variant: once to build the `.stl` and a second time from scratch with `--render` to build the `.png`. With 8 panels × 4 versions = 32 variants, OpenSCAD runs 64 sequential full CGAL renders.
  - `CONFIG_FILE = "configs/panels.json"` and `scad_file = "src/diffuser.scad"` use relative paths tied to the current working directory instead of resolving relative to ` os.path.dirname(__file__)`.
  - `config_to_params()` (line 41) interpolates string values via `f'{k}="{v}"'` without escaping embedded quotes or backslashes.
  - `validate_config()` (lines 21–35) only checks key existence and does not validate value types, positivity, `inner_diameter < outer_diameter`, `bottom_thickness < diffusion_height`, or segmentation bounds (`row_start <= row_end < rows`).

---

## 3. Web Viewer, CI/CD, and Repository Consistency Flaws

### 3.1 Broken Asset Naming Contract Between `generate_stl.py`, `docs/index.html`, and `README.md`
- **Location:** `scripts/generate_stl.py` (lines 89–120), `docs/index.html` (lines 74, 84, 94), `README.md` (lines 16, 23, 30)
- **Severity:** High
- **Description:**
  - `scripts/generate_stl.py` only outputs version-suffixed files (`diffuser_<name>_v1.stl`, `_v2.stl`, `_v3_body.stl`, `_v3_lid.stl` and matching `.png`s).
  - However, `docs/index.html` loads unsuffixed `stl/diffuser_16x16.stl`, `stl/diffuser_8x32.stl`, and `stl/diffuser_ring_20.stl`, and `README.md` links to unsuffixed `images/diffuser_16x16.png`, `images/diffuser_8x32.png`, and `images/diffuser_ring_20.png`.
  - The unsuffixed files in `stl/`, `docs/stl/`, and `images/` are stale leftovers from earlier commits and are no longer updated when `generate_stl.py` runs. Notably, `stl/diffuser_16x16.stl` (458 KB binary STL) does not even match `docs/stl/diffuser_16x16.stl` (1.45 MB ASCII STL).

### 3.2 `8x32` Model Clipped by Camera Far Plane in 3D Web Viewer (`docs/index.html`)
- **Location:** `docs/index.html` (lines 130, 166–170)
- **Severity:** Medium
- **Description:**
  - `PerspectiveCamera` is initialized with `far = 1000` (line 130).
  - For the `8x32` panel (`maxDim = 324mm`), `cameraZ` is computed as `(324 / 2 / tan(22.5°)) * 1.5 ≈ 586.7`, and the camera is placed at `(cameraZ, cameraZ, cameraZ)`.
  - The Euclidean distance from `(586.7, 586.7, 586.7)` to the origin `(0, 0, 0)` is `sqrt(3) * 586.7 ≈ 1016.1mm > 1000mm`, placing the model past the camera's far clipping plane on initial load.

### 3.3 Wrong GitHub Repository URL and Missing Panels in `docs/index.html`
- **Location:** `docs/index.html` (lines 72–106)
- **Severity:** Low
- **Description:**
  - Line 105 links to `https://github.com/jules-software-engineer/neopixel-diffuser` instead of `https://github.com/chatelao/neopixel-diffusor-3d-print`.
  - Only 3 panels are shown in `docs/index.html`, with no selector for the other 5 configurations in `configs/panels.json` or for V1 / V2 / V3 body / V3 lid variants, even though `.github/workflows/generate_stls.yml` copies all `stl/*.stl` files into `docs/stl/`.

### 3.4 Incomplete/Stale Generated Assets, Scratch Files in Root, and Missing `.gitignore`
- **Location:** Repository root, `stl/`, `images/`
- **Severity:** Medium
- **Description:**
  - **Missing `.gitignore`:** There is no `.gitignore` file in the repository (e.g., for `__pycache__/`, `.DS_Store`, temporary renders, or build artifacts).
  - **Leftover scratch files committed to root:** `test_body.png`, `test_lid.png`, and `test_v1.png` are committed directly in the repository root.
  - **Incomplete `stl/` and `images/` directories:**
    - `16x32` only has `_v1` generated (`_v2`, `_v3_body`, and `_v3_lid` are missing).
    - `16x16_segmented`, `ring_20_magnets`, and `hex_full_features` are completely missing all `_v1`, `_v2`, `_v3_body`, and `_v3_lid` STL and PNG files.
    - `images/diffuser_hex_full_features*.png` does not exist at all.
    - Orphan files from deprecated naming schemes (`stl/diffuser_hex_sample_body.stl`, `stl/diffuser_hex_sample_diffuser.stl`) remain committed in `stl/`.

### 3.5 Incomplete Documentation (`README.md`)
- **Location:** `README.md` (lines 50–83)
- **Severity:** Low
- **Description:**
  - The customization parameter table omits `part`, `lid_tolerance`, `cap_clearance_enabled`, `cap_clearance_width`, `cap_clearance_height`, `row_start`, `row_end`, `col_start`, and `col_end`.
  - The documented values for `type` omit `"hex_matrix"`, and `cell_shape` omits `"hexagonal"`.
  - The multi-version output behavior (`v1`, `v2`, `v3_body`, `v3_lid`) and CLI flag `--no-png` are undocumented.
