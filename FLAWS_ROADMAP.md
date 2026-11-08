# Flaws Remediation Roadmap (`FLAWS_ROADMAP.md`)

This roadmap provides a structured, step-by-step action plan to resolve every geometric, scripting, verification, web viewer, CI/CD, and documentation flaw documented in `FLAWS.md`.

---

## Phase 1: Fix Z-Orientation & Feature Placement in `src/diffuser.scad`
*Goal: Ensure all PCB-facing cutouts and recesses are located on the LED/PCB side (`z = diffusion_height`) while keeping the optical diffusion layer on the build plate (`z = 0` to `bottom_thickness`) intact.*

- [x] **1. Fix Capacitor Clearance in `cell()` (Flaw 1.1)**
  - **File:** `src/diffuser.scad` (lines 105–111)
  - **Action:**
    - Move the capacitor clearance cutouts from the bottom diffuser face (`-diffusion_height/2 + cap_clearance_height/2`) to the top LED/PCB side (`+diffusion_height/2 - cap_clearance_height/2 + 0.05`).
    - Restrict the cutout length along the wall (e.g., `cap_clearance_length = min(led_pitch * 0.5, 4.0)`) instead of `led_pitch + 0.1` so the walls remain structurally connected around cell corners.
  - **Verification:** `diffuser_16x16_v1.stl`, `diffuser_8x32_v1.stl`, and `diffuser_16x32_v1.stl` export as a single connected mesh (`comps = 1`) with all internal walls resting flat on `z = 0` (or `z = bottom_thickness`).

- [x] **2. Fix Ring Capacitor Clearance in `ring_layout()` (Flaw 1.2)**
  - **File:** `src/diffuser.scad` (lines 597–602)
  - **Action:**
    - Move the ring capacitor cutout Z-center from `cap_clearance_height/2` to `diffusion_height - cap_clearance_height/2 + 0.05`.
    - Constrain the radial width of the capacitor cutout to `ring_width - 2 * wall_thickness` so it only notches the inter-LED dividing walls on the PCB side without piercing the inner or outer perimeter walls of the ring.

- [x] **3. Move Cable Cutouts and Magnet Recesses to the PCB Side (Flaw 1.3)**
  - **File:** `src/diffuser.scad` (lines 294–331, 465–501, 548–565)
  - **Action:**
    - Update magnet recess Z-translations across `matrix_layout()`, `hex_matrix_layout()`, and `ring_layout()` from `z = -0.1` to `z = diffusion_height - magnet_depth`.
    - Update cable cutout Z-translations across all three layouts from `z = cutout_depth/2 - 0.1` to `z = diffusion_height - cutout_depth/2 + 0.1`.

- [x] **4. Fix Frame Labeling Placement, Orientation, and Sizing (Flaw 1.3)**
  - **File:** `src/diffuser.scad` (lines 36–38, 287–292, 458–463)
  - **Action:**
    - Clamp or default `label_size` to fit within `frame_width` (e.g., `min(label_size, frame_width * 0.75)`), or place the label on the outer vertical side wall of the frame (`y = y_min`) so `5mm` text fits within the `10mm` `diffusion_height` without cutting into LED cavities.
    - Guard bottom-frame labeling with `if (row_start == 0)` (or place on an active frame edge for segmented matrices).

---

## Phase 2: Fix Version 3 (`body` & `diffuser` Lid) Architecture in `src/diffuser.scad`
*Goal: Make Version 3 bodies self-supporting on the print bed (`z = 0`) with a proper retaining lip/recess, and ensure Version 3 lids are clean, accurately sized single-piece sheets.*

- [x] **5. Guard Auxiliary Features Against Bleeding into `part == "diffuser"` (Flaw 1.4.2)**
  - **File:** `src/diffuser.scad` (lines 211–231, 265–331, 391–411, 436–501, 538–565)
  - **Action:**
    - Wrap mounting tabs, mounting holes, magnet recesses, cable cutouts, and frame labels in `if (part == "all" || part == "body")` across `matrix_layout()`, `hex_matrix_layout()`, and `ring_layout()`.
  - **Verification:** `diffuser_16x16_v3_lid.stl`, `diffuser_8x32_v3_lid.stl`, and `diffuser_ring_20_v3_lid.stl` contain only the `1.0mm` diffuser plate (`comps = 1`) with no `10mm` corner cylinders or perimeter cutout notches.

- [x] **6. Preserve Outer Retaining Walls on V3 Bodies (`part == "body"`) (Flaw 1.4.1)**
  - **File:** `src/diffuser.scad` (lines 135–143, 607–614)
  - **Action:**
    - Instead of subtracting `led_pitch + 0.1` from each individual `cell()` at `z = 0..bottom_thickness` (which erases the entire bottom of frameless grids and cuts `0.05mm` too deep to `z = 1.05mm`), keep `cell()` walls extending to `z = 0` or subtract a single interior recess at the layout level inset by `wall_thickness` (or require/auto-enable an outer perimeter wall for `part == "body"`).
    - In `ring_layout()`, recess the lid pocket between `inner_diameter + 2 * wall_thickness` and `outer_diameter - 2 * wall_thickness` (or use `actual_outer` / inner lip) so the ring body rests flat at `z = 0` and retains the lid.
    - Match the lid (`part == "diffuser"`) dimensions to the recessed pocket minus `lid_tolerance`.

- [x] **7. Fix V3 Matrix Lid Double-Translation When `frame_radius > 0` (Flaw 1.4.3)**
  - **File:** `src/diffuser.scad` (lines 421–433)
  - **Action:**
    - Remove the outer `translate([(lx_min+lx_max)/2, (ly_min+ly_max)/2, ...])` when using world coordinates `[lx_min + r, ly_min + r, 0]` inside the `if (frame_radius > 0)` hull, and offset cylinder centers by the actual corner radius `r = max(0.1, frame_radius - frame_width - lid_tolerance)`.

- [x] **8. Fix V3 Hex-Matrix Lid Geometry for Staggered Rows (Flaw 1.4.4)**
  - **File:** `src/diffuser.scad` (lines 241–262)
  - **Action:**
    - Generate the `hex_matrix` lid as the union of all cells at `h = bottom_thickness` inset by `lid_tolerance` (or hull per row/column including odd-row `x_offset = led_pitch / 2`), ensuring complete coverage of staggered odd rows and exact fit into the `body` recess.

---

## Phase 3: Fix Mounting, Hex-Matrix Math, Ring Cavities & Manifold Integrity
*Goal: Eliminate cavity breaches, fix hexagonal bounding box math, and guarantee 100% 2-manifold watertight meshes.*

- [x] **9. Offset Mounting Tabs & Magnet Pockets Outside LED Cavities (Flaw 1.5)**
  - **File:** `src/diffuser.scad` (lines 212–231, 266–313, 392–411, 437–484, 525–554)
  - **Action:**
    - In `ring_layout()`, position mounting tabs, holes, and magnet pockets radially outward at `actual_outer / 2 + tab_offset` (e.g., `actual_outer / 2 + max(mounting_hole_dia, magnets_enabled ? magnet_dia/2 : 0)`) so neither holes nor `6.1mm` magnet pockets intersect the ring's LED cavities.
    - In `matrix_layout()` and `hex_matrix_layout()`, offset corner tab centers outward from the cell boundary or increase corner tab bosses so `magnet_dia` (`6.1mm`) never cuts into corner LED cells.

- [x] **10. Fix Hex-Matrix Bounding Box, Frame Fit, and Manifold Overlap (Flaw 1.6)**
  - **File:** `src/diffuser.scad` (lines 74–88, 121–123, 157–209)
  - **Action:**
    - Update `y_min` and `y_max` in `hex_matrix_layout()` to use the true hex circumradius `hex_r = led_pitch / (2 * cos(30))` (`≈ 0.57735 * led_pitch`) instead of `0.5 * led_pitch`.
    - Slightly overlap adjacent hex cells (`d = (led_pitch + 0.002) / cos(30)`) or union them cleanly with the frame, and fill the staggered row side indentations so there are no `5mm` open holes between the rectangular frame and staggered hex rows and zero non-manifold edges.

- [x] **11. Fix Cross-Compatibility of `type` and `cell_shape` & Ring Constants (Flaw 1.6.4)**
  - **File:** `src/diffuser.scad` (lines 119–131, 569–595)
  - **Action:**
    - When `type == "matrix"` and `cell_shape == "hexagonal"`, scale the hex cavity circumdiameter to `exit_dim` (so vertices fit within `led_pitch - wall_thickness`) instead of `exit_dim / cos(30)`.
    - When `type == "ring"` and `cell_shape == "circular"`, bound `exit_d` by `min(led_pitch, ring_width, PI * (outer_diameter + inner_diameter) / (2 * num_leds)) - wall_thickness + tolerance`.
    - Add support for `cell_shape == "hexagonal"` in `ring_layout()` and replace hardcoded `3.14159` with `PI`.

- [x] **12. Fix Rounded Frame Interior Cutout and Segmentation Handling (Flaw 1.7)**
  - **File:** `src/diffuser.scad` (lines 174–186, 354–366)
  - **Action:**
    - Replace the sharp interior `cube()` cutout inside `if (frame_radius > 0)` with a rounded `hull()` of 4 inner cylinders of radius `max(0.01, frame_radius - frame_width)`, preventing large `frame_radius` values from severing the frame corners.
    - Respect `col_start`, `actual_col_end`, `row_start`, and `actual_row_end` when `frame_radius > 0` on segmented matrices.

- [x] **13. Clean Up Dead and Duplicate Code in `cell()` (Flaw 1.8)**
  - **File:** `src/diffuser.scad` (lines 72–99, 115–116)
  - **Action:**
    - Merge the duplicate `if (part == "all")` and `else if (part == "body")` outer-boundary blocks in `cell()`.
    - Simplify `cavity_h = h + 0.1;` and `z_offset = bottom_thickness/2 + 0.05;`.
    - Remove or properly wire up the unreachable `if (part == "diffuser")` block inside `cell()`.

---

## Phase 4: Improve Python Scripts & Mesh Verification (`scripts/`)
*Goal: Enforce strict mesh verification (single-shell manifold check), validate configuration parameters, and speed up asset generation.*

- [ ] **14. Fix `scripts/verify_stls.py` to Catch Multi-Shell Disconnections and Non-Manifold Edges (Flaw 2.1)**
  - **File:** `scripts/verify_stls.py` (lines 5–28)
  - **Action:**
    - Include `is_manifold` in the pass condition.
    - Parse `Number of parts` from `admesh` output and assert `parts == 1` so shattered meshes (e.g., 257 disconnected parts) fail verification.
    - Add a pure-Python fallback/check verifying `0` non-manifold edges (every triangle edge shared by exactly 2 triangles), `1` connected component, and `min(z) == 0.0` (model rests on the build plate).

- [ ] **15. Strengthen Config Validation, Path Resolution, and Rendering Performance in `scripts/generate_stl.py` (Flaw 2.2)**
  - **File:** `scripts/generate_stl.py` (lines 7–140)
  - **Action:**
    - Resolve `CONFIG_FILE`, `src/diffuser.scad`, `stl/`, and `images/` paths relative to the repository root (`Path(__file__).resolve().parent.parent`) so the script works from any working directory.
    - Escape string parameters safely using `json.dumps(v)` in `config_to_params()`.
    - Expand `validate_config()` to check value types and physical constraints (`rows > 0`, `cols > 0`, `led_pitch > wall_thickness`, `outer_diameter > inner_diameter > 0`, `bottom_thickness < diffusion_height`, valid `row_start`/`row_end`/`col_start`/`col_end`).
    - Add parallel execution (`concurrent.futures.ProcessPoolExecutor` / `--jobs`) to speed up batch generation across all panels and versions.

---

## Phase 5: Align Web Viewer, CI/CD, Repository Assets & Documentation
*Goal: Synchronize generated filenames across scripts, docs, and GitHub Pages, fix the 3D viewer clipping bug, and clean up repository artifacts.*

- [ ] **16. Synchronize Asset Filenames Across `generate_stl.py`, `docs/index.html`, and `README.md` (Flaw 3.1)**
  - **Files:** `scripts/generate_stl.py`, `docs/index.html`, `README.md`, `.github/workflows/generate_stls.yml`
  - **Action:**
    - Update `docs/index.html` and `README.md` to reference the versioned filenames (`_v1.stl` / `_v1.png`, or provide a version/panel selector in `docs/index.html`).
    - Remove stale unsuffixed or orphaned files (`stl/diffuser_hex_sample_body.stl`, `stl/diffuser_hex_sample_diffuser.stl`, etc.) and regenerate all configured panels (`16x16`, `8x32`, `ring_20`, `hex_sample`, `16x32`, `16x16_segmented`, `ring_20_magnets`, `hex_full_features`) across V1, V2, V3 body, and V3 lid.

- [ ] **17. Fix Camera Far-Plane Clipping, GitHub Link, and Model Selector in `docs/index.html` (Flaws 3.2 & 3.3)**
  - **File:** `docs/index.html` (lines 72–175)
  - **Action:**
    - Increase `PerspectiveCamera` `far` plane from `1000` to `5000` (or dynamically set `camera.far = cameraZ * 5; camera.updateProjectionMatrix();`) so large panels like `8x32` and `16x32` are never clipped on initial load.
    - Fix the footer GitHub link to `https://github.com/chatelao/neopixel-diffusor-3d-print`.
    - Add support in the web UI to browse all panels and versions (`v1`, `v2`, `v3_body`, `v3_lid`).

- [ ] **18. Integrate `verify_stls.py` into GitHub Actions Workflow (`.github/workflows/generate_stls.yml`) (Flaw 2.1)**
  - **File:** `.github/workflows/generate_stls.yml` (lines 21–40)
  - **Action:**
    - Install `admesh` in the `Install OpenSCAD and dependencies` step (`sudo apt-get install openscad xvfb admesh -y`).
    - Add a `Verify STLs` step running `python3 scripts/verify_stls.py` after `generate_stl.py` so broken or non-manifold geometries fail CI immediately.

- [ ] **19. Clean Up Root Scratch Files and Add `.gitignore` (Flaw 3.4)**
  - **Files:** `.gitignore`, `test_body.png`, `test_lid.png`, `test_v1.png`
  - **Action:**
    - Create a `.gitignore` covering Python cache files (`__pycache__/`, `*.pyc`, `.venv/`), OS/editor files (`.DS_Store`, `*.swp`), and temporary test outputs (`test_*.png`, `test_*.stl`).
    - Remove committed scratch files `test_body.png`, `test_lid.png`, and `test_v1.png` from the repository root.

- [ ] **20. Update `README.md` Parameter Table and Usage Documentation (Flaw 3.5)**
  - **File:** `README.md` (lines 39–83)
  - **Action:**
    - Document all missing OpenSCAD parameters (`part`, `lid_tolerance`, `cap_clearance_enabled`, `cap_clearance_width`, `cap_clearance_height`, `row_start`, `row_end`, `col_start`, `col_end`).
    - Update `type` values (`"matrix"`, `"hex_matrix"`, `"ring"`) and `cell_shape` values (`"square"`, `"circular"`, `"hexagonal"`).
    - Document the 3 diffuser versions (`v1`, `v2`, `v3_body` + `v3_lid`) and CLI flags (`--panel`, `--no-png`).
