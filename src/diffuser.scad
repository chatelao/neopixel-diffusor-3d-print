// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
type = "matrix";          // "matrix", "hex_matrix", or "ring"
part = "all";             // "all", "body", or "diffuser" for multi-material
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
tolerance = 0.1;          // Offset for fit (mm)
lid_tolerance = 0.2;      // Offset for separate lid fit (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)
cell_shape = "square";    // "square", "circular", or "hexagonal"
draft_angle = 0;          // Angle of the side walls (degrees)

// Capacitor clearance
cap_clearance_enabled = false; // Space for SMD capacitors
cap_clearance_width = 2.5;     // Width of the cutout (mm)
cap_clearance_height = 1.5;    // Height of the cutout (mm)

// Stability frame
frame_enabled = false;    // Add a reinforced outer frame
frame_width = 2.0;        // Thickness of the outer frame (mm)
frame_radius = 0.0;       // Radius for rounded corners (mm)

// Cable cutouts
cutout_enabled = false;   // Add cutouts for cables
cutout_width = 10;        // Width of the cable cutout (mm)
cutout_depth = 3;         // Depth of the cable cutout (mm)
cutout_side = "bottom";   // "left", "right", "top", "bottom" or "inner", "outer"

// Mounting holes
mounting_holes_enabled = false;
mounting_hole_dia = 3.0;

// Frame labeling
label_text = "";          // Text to emboss on the frame
label_size = 5.0;         // Font size (mm)
label_depth = 0.5;        // Depth of the emboss (mm)

// Magnet mounts
magnets_enabled = false;
magnet_dia = 6.1;
magnet_depth = 2.0;

// Matrix specific
rows = 16;
cols = 16;
row_start = 0;
row_end = -1;     // -1 means use rows-1
col_start = 0;
col_end = -1;     // -1 means use cols-1

// Ring specific
num_leds = 20;
outer_diameter = 62;
inner_diameter = 47;

// --- Modules ---

// Module for a single diffuser cell
module cell() {
    h = diffusion_height - bottom_thickness;
    // exit_dim is at the diffusion layer (widest part of the cavity)
    exit_dim = led_pitch - wall_thickness + tolerance;

    // draft_angle makes the cavity narrower towards the LED to allow thicker walls at the base
    delta = 2 * h * tan(draft_angle);
    entry_dim = max(1.0, exit_dim - delta); // Ensure it doesn't disappear

    // Small overlap epsilon so adjacent cells in matrix/hex_matrix fuse into a 2-manifold solid
    cell_outer_pitch = led_pitch + 0.02;
    outer_h = (part == "all") ? diffusion_height : ((part == "body") ? h : bottom_thickness);
    outer_z = (part == "all") ? 0 : ((part == "body") ? bottom_thickness/2 : -diffusion_height/2 + bottom_thickness/2);

    difference() {
        translate([0, 0, outer_z])
        if (type == "hex_matrix") {
            rotate([0, 0, 30])
            cylinder(d=cell_outer_pitch / cos(30), h=outer_h, center=true, $fn=6);
        } else {
            cube([cell_outer_pitch, cell_outer_pitch, outer_h], center=true);
        }

        // Subtract the cavity from the body
        if (part == "all" || part == "body") {
            // Capacitor clearance (on the LED/PCB side at +Z, preserving cell corners)
            if (cap_clearance_enabled) {
                for (a = [0, 90, 180, 270]) {
                    rotate([0, 0, a])
                    translate([led_pitch/2, 0, diffusion_height/2 - cap_clearance_height/2 + 0.05])
                    cube([cap_clearance_width, led_pitch/2, cap_clearance_height + 0.1], center=true);
                }
            }

            // Inner cavity (hollow part)
            // For "all", it stops at bottom_thickness. For "body", it goes all the way through the cell walls
            cavity_h = (part == "all" ? h + 0.1 : h + 0.2);
            z_offset = (part == "all" ? bottom_thickness/2 + 0.05 : bottom_thickness/2);

            translate([0, 0, z_offset]) {
                if (cell_shape == "circular") {
                    cylinder(d1=exit_dim, d2=entry_dim, h=cavity_h, center=true, $fn=64);
                } else if (cell_shape == "hexagonal") {
                    hex_scale = (type == "hex_matrix") ? (1 / cos(30)) : 1.0;
                    rotate([0, 0, 30])
                    cylinder(d1=exit_dim * hex_scale, d2=entry_dim * hex_scale, h=cavity_h, center=true, $fn=6);
                } else {
                    sq_scale = (type == "hex_matrix") ? (1 / (cos(30) + sin(30))) : 1.0;
                    hull() {
                        translate([0, 0, -cavity_h/2])
                        cube([exit_dim * sq_scale, exit_dim * sq_scale, 0.01], center=true);
                        translate([0, 0, cavity_h/2])
                        cube([entry_dim * sq_scale, entry_dim * sq_scale, 0.01], center=true);
                    }
                }
            }
        }
    }
}

module hex_matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;
    has_frame = frame_enabled || (part == "body");

    // Hexagonal packing math (flat-to-flat = led_pitch):
    // Horizontal distance = led_pitch
    // Vertical distance = led_pitch * cos(30) = led_pitch * 0.8660254
    // Circumradius (center to top/bottom vertex) = led_pitch / (2 * cos(30)) = 0.57735 * led_pitch
    // Odd rows are staggered horizontally by led_pitch / 2

    row_dist = led_pitch * cos(30);
    hex_r = led_pitch / (2 * cos(30));
    has_odd_row = (actual_row_end > row_start) || (row_start % 2 == 1);

    inner_x_min = (col_start - 0.5) * led_pitch;
    inner_x_max = (actual_col_end + 0.5) * led_pitch + (has_odd_row ? led_pitch/2 : 0);
    inner_y_min = row_start * row_dist - hex_r;
    inner_y_max = actual_row_end * row_dist + hex_r;

    x_min = inner_x_min - frame_width;
    x_max = inner_x_max + frame_width;
    y_min = inner_y_min - frame_width;
    y_max = inner_y_max + frame_width;

    // Interior bounds for the lid
    lx_min = inner_x_min + lid_tolerance;
    lx_max = inner_x_max - lid_tolerance;
    ly_min = inner_y_min + lid_tolerance;
    ly_max = inner_y_max - lid_tolerance;

    difference() {
        union() {
            // Outer frame (enabled explicitly or required to retain V3 lid in "body" mode)
            if (has_frame && (part == "all" || part == "body")) {
                is_full_panel = (col_start == 0 && actual_col_end == cols - 1 && row_start == 0 && actual_row_end == rows - 1);
                if (frame_radius > 0 && (is_full_panel || part == "body")) {
                    // Rounded outer frame with matching rounded interior cutout
                    inner_r = max(0.01, frame_radius - frame_width);
                    difference() {
                        hull() {
                            translate([x_min + frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_min + frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                        }
                        // Subtract rounded interior (with 0.01mm overlap into inner grid)
                        translate([0, 0, -1])
                        hull() {
                            translate([inner_x_min + inner_r + 0.01, inner_y_min + inner_r + 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_max - inner_r - 0.01, inner_y_min + inner_r + 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_min + inner_r + 0.01, inner_y_max - inner_r - 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_max - inner_r - 0.01, inner_y_max - inner_r - 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                        }
                    }
                } else {
                    // Left frame
                    if (col_start == 0 || part == "body") {
                        translate([x_min, y_min, 0])
                        cube([frame_width + 0.01, y_max - y_min, diffusion_height]);
                    }
                    // Right frame
                    if (actual_col_end == cols - 1 || part == "body") {
                        translate([x_max - frame_width - 0.01, y_min, 0])
                        cube([frame_width + 0.01, y_max - y_min, diffusion_height]);
                    }
                    // Bottom frame
                    if (row_start == 0 || part == "body") {
                        translate([x_min, y_min, 0])
                        cube([x_max - x_min, frame_width + 0.01, diffusion_height]);
                    }
                    // Top frame
                    if (actual_row_end == rows - 1 || part == "body") {
                        translate([x_min, y_max - frame_width - 0.01, 0])
                        cube([x_max - x_min, frame_width + 0.01, diffusion_height]);
                    }
                }

                // Fill the staggered hex boundary gaps inside the frame above the lid recess
                fill_z = (part == "body") ? bottom_thickness : 0;
                fill_h = diffusion_height - fill_z;
                difference() {
                    translate([inner_x_min - 0.01, inner_y_min - 0.01, fill_z])
                    cube([inner_x_max - inner_x_min + 0.02, inner_y_max - inner_y_min + 0.02, fill_h]);
                    for (r = [row_start : actual_row_end]) {
                        x_offset = (r % 2 == 0) ? 0 : led_pitch / 2;
                        for (c = [col_start : actual_col_end]) {
                            translate([c * led_pitch + x_offset, r * row_dist, fill_z + fill_h/2])
                            rotate([0, 0, 30])
                            cylinder(d=(led_pitch - 0.02) / cos(30), h=fill_h + 2, center=true, $fn=6);
                        }
                    }
                }
            }

            // Mounting tabs
            if (mounting_holes_enabled && frame_enabled && (part == "all" || part == "body")) {
                tab_size = magnets_enabled ? max(mounting_hole_dia * 2, magnet_dia + 2) : mounting_hole_dia * 2;
                hole_or_magnet_r = max(mounting_hole_dia / 2, magnets_enabled ? magnet_dia / 2 : 0);
                tab_offset = max(0, hole_or_magnet_r - frame_width);
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }

            if (part == "all" || part == "body") {
                for (r = [row_start : actual_row_end]) {
                    x_offset = (r % 2 == 0) ? 0 : led_pitch / 2;
                    for (c = [col_start : actual_col_end]) {
                        translate([c * led_pitch + x_offset, r * row_dist, diffusion_height/2])
                        cell();
                    }
                }
            } else if (part == "diffuser") {
                // One-piece solid lid for the hex matrix (covering all staggered rows inside the frame recess)
                if (frame_radius > 0) {
                    lid_r = max(0.1, frame_radius - frame_width - lid_tolerance);
                    translate([0, 0, bottom_thickness/2])
                    hull() {
                        translate([lx_min + lid_r, ly_min + lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_max - lid_r, ly_min + lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_min + lid_r, ly_max - lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_max - lid_r, ly_max - lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                    }
                } else {
                    translate([(lx_min+lx_max)/2, (ly_min+ly_max)/2, bottom_thickness/2])
                    cube([lx_max-lx_min, ly_max-ly_min, bottom_thickness], center=true);
                }
            }
        }

        if (part == "all" || part == "body") {
            hole_or_magnet_r = max(mounting_hole_dia / 2, magnets_enabled ? magnet_dia / 2 : 0);
            tab_offset = max(0, hole_or_magnet_r - frame_width);

            // Mounting holes
            if (mounting_holes_enabled && frame_enabled) {
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
            }

            // Frame Labeling (embossed on the outer vertical wall of the bottom frame)
            if (label_text != "" && frame_enabled && (row_start == 0 || frame_radius > 0)) {
                actual_label_size = min(label_size, diffusion_height * 0.6);
                actual_label_depth = min(label_depth, frame_width * 0.5);
                translate([(x_max+x_min)/2, y_min + actual_label_depth, diffusion_height/2])
                rotate([90, 0, 0])
                linear_extrude(height = actual_label_depth + 0.1)
                text(label_text, size = actual_label_size, halign = "center", valign = "center");
            }

            // Magnet recesses (on the PCB side at +Z)
            if (magnets_enabled && mounting_holes_enabled && frame_enabled) {
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
            }

            // Cable cutout (on the PCB side at +Z)
            if (cutout_enabled) {
                if (cutout_side == "bottom" && row_start == 0) {
                    translate([(x_max+x_min)/2, y_min + frame_width/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "top" && actual_row_end == rows - 1) {
                    translate([(x_max+x_min)/2, y_max - frame_width/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "left" && col_start == 0) {
                    translate([x_min + frame_width/2, (y_max+y_min)/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "right" && actual_col_end == cols - 1) {
                    translate([x_max - frame_width/2, (y_max+y_min)/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
                }
            }
        }
    }
}

module matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;
    has_frame = frame_enabled || (part == "body");

    inner_x_min = (col_start - 0.5) * led_pitch;
    inner_x_max = (actual_col_end + 0.5) * led_pitch;
    inner_y_min = (row_start - 0.5) * led_pitch;
    inner_y_max = (actual_row_end + 0.5) * led_pitch;

    x_min = inner_x_min - frame_width;
    x_max = inner_x_max + frame_width;
    y_min = inner_y_min - frame_width;
    y_max = inner_y_max + frame_width;

    // Interior bounds for the lid
    lx_min = inner_x_min + lid_tolerance;
    lx_max = inner_x_max - lid_tolerance;
    ly_min = inner_y_min + lid_tolerance;
    ly_max = inner_y_max - lid_tolerance;

    difference() {
        union() {
            // Outer frame (enabled explicitly or required to retain V3 lid in "body" mode)
            if (has_frame && (part == "all" || part == "body")) {
                is_full_panel = (col_start == 0 && actual_col_end == cols - 1 && row_start == 0 && actual_row_end == rows - 1);
                if (frame_radius > 0 && (is_full_panel || part == "body")) {
                    // Rounded outer frame with matching rounded interior cutout
                    inner_r = max(0.01, frame_radius - frame_width);
                    difference() {
                        hull() {
                            translate([x_min + frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_min + frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                        }
                        // Subtract rounded interior (with 0.01mm overlap into inner grid)
                        translate([0, 0, -1])
                        hull() {
                            translate([inner_x_min + inner_r + 0.01, inner_y_min + inner_r + 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_max - inner_r - 0.01, inner_y_min + inner_r + 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_min + inner_r + 0.01, inner_y_max - inner_r - 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                            translate([inner_x_max - inner_r - 0.01, inner_y_max - inner_r - 0.01, 0]) cylinder(r=inner_r, h=diffusion_height + 2, $fn=32);
                        }
                    }
                } else {
                    // Left frame
                    if (col_start == 0 || part == "body") {
                        translate([x_min, y_min, 0])
                        cube([frame_width + 0.01, y_max - y_min, diffusion_height]);
                    }
                    // Right frame
                    if (actual_col_end == cols - 1 || part == "body") {
                        translate([x_max - frame_width - 0.01, y_min, 0])
                        cube([frame_width + 0.01, y_max - y_min, diffusion_height]);
                    }
                    // Bottom frame
                    if (row_start == 0 || part == "body") {
                        translate([x_min, y_min, 0])
                        cube([x_max - x_min, frame_width + 0.01, diffusion_height]);
                    }
                    // Top frame
                    if (actual_row_end == rows - 1 || part == "body") {
                        translate([x_min, y_max - frame_width - 0.01, 0])
                        cube([x_max - x_min, frame_width + 0.01, diffusion_height]);
                    }
                }
            }

            // Mounting tabs
            if (mounting_holes_enabled && frame_enabled && (part == "all" || part == "body")) {
                tab_size = magnets_enabled ? max(mounting_hole_dia * 2, magnet_dia + 2) : mounting_hole_dia * 2;
                hole_or_magnet_r = max(mounting_hole_dia / 2, magnets_enabled ? magnet_dia / 2 : 0);
                tab_offset = max(0, hole_or_magnet_r - frame_width);
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }

            if (part == "all" || part == "body") {
                for (r = [row_start : actual_row_end]) {
                    for (c = [col_start : actual_col_end]) {
                        translate([c * led_pitch, r * led_pitch, diffusion_height/2])
                        cell();
                    }
                }
            } else if (part == "diffuser") {
                // One piece solid lid for version 3
                if (frame_radius > 0) {
                    lid_r = max(0.1, frame_radius - frame_width - lid_tolerance);
                    translate([0, 0, bottom_thickness/2])
                    hull() {
                        translate([lx_min + lid_r, ly_min + lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_max - lid_r, ly_min + lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_min + lid_r, ly_max - lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                        translate([lx_max - lid_r, ly_max - lid_r, 0]) cylinder(r=lid_r, h=bottom_thickness, center=true, $fn=32);
                    }
                } else {
                    translate([(lx_min+lx_max)/2, (ly_min+ly_max)/2, bottom_thickness/2])
                    cube([lx_max-lx_min, ly_max-ly_min, bottom_thickness], center=true);
                }
            }
        }

        if (part == "all" || part == "body") {
            hole_or_magnet_r = max(mounting_hole_dia / 2, magnets_enabled ? magnet_dia / 2 : 0);
            tab_offset = max(0, hole_or_magnet_r - frame_width);

            // Mounting holes
            if (mounting_holes_enabled && frame_enabled) {
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
            }

            // Frame Labeling (embossed on the outer vertical wall of the bottom frame)
            if (label_text != "" && frame_enabled && (row_start == 0 || frame_radius > 0)) {
                actual_label_size = min(label_size, diffusion_height * 0.6);
                actual_label_depth = min(label_depth, frame_width * 0.5);
                translate([(x_max+x_min)/2, y_min + actual_label_depth, diffusion_height/2])
                rotate([90, 0, 0])
                linear_extrude(height = actual_label_depth + 0.1)
                text(label_text, size = actual_label_size, halign = "center", valign = "center");
            }

            // Magnet recesses (on the PCB side at +Z)
            if (magnets_enabled && mounting_holes_enabled && frame_enabled) {
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min - tab_offset, y_min - tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max + tab_offset, y_min - tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min - tab_offset, y_max + tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max + tab_offset, y_max + tab_offset, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
            }

            // Cable cutout (on the PCB side at +Z)
            if (cutout_enabled) {
                if (cutout_side == "bottom" && row_start == 0) {
                    translate([(x_max+x_min)/2, y_min + frame_width/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "top" && actual_row_end == rows - 1) {
                    translate([(x_max+x_min)/2, y_max - frame_width/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "left" && col_start == 0) {
                    translate([x_min + frame_width/2, (y_max+y_min)/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "right" && actual_col_end == cols - 1) {
                    translate([x_max - frame_width/2, (y_max+y_min)/2, diffusion_height - cutout_depth/2 + 0.1])
                    cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
                }
            }
        }
    }
}

module ring_layout() {
    radius = (outer_diameter + inner_diameter) / 4;
    ring_width = (outer_diameter - inner_diameter) / 2;
    actual_outer = frame_enabled ? outer_diameter + 2*frame_width : outer_diameter;
    // Recessed pocket bounds for Version 3 ring lid (retaining inner & outer walls at z=0)
    recess_outer = frame_enabled ? outer_diameter : outer_diameter - 2*wall_thickness;
    recess_inner = inner_diameter + 2*wall_thickness;
    // Offset mounting tabs outward so holes and magnets never cut into LED cavities
    hole_or_magnet_r = max(mounting_hole_dia / 2, magnets_enabled ? magnet_dia / 2 : 0);
    tab_r = actual_outer / 2 + hole_or_magnet_r;

    difference() {
        union() {
            // Ring body
            if (part == "all" || part == "body") {
                cylinder(d=actual_outer, h=diffusion_height, $fn=128);
            } else if (part == "diffuser") {
                // Lid for the ring (fits into the recessed annular pocket)
                difference() {
                    cylinder(d=recess_outer - 2*lid_tolerance, h=bottom_thickness, $fn=128);
                    translate([0, 0, -1])
                    cylinder(d=recess_inner + 2*lid_tolerance, h=bottom_thickness + 2, $fn=128);
                }
            }

            // Mounting tabs for ring
            if (mounting_holes_enabled && (part == "all" || part == "body")) {
                tab_size = magnets_enabled ? max(mounting_hole_dia * 2, magnet_dia + 2) : mounting_hole_dia * 2;
                for (a = [0, 90, 180, 270]) {
                    rotate([0, 0, a])
                    translate([tab_r, 0, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }
        }

        if (part == "all" || part == "body") {
            translate([0, 0, -1])
            cylinder(d=inner_diameter, h=diffusion_height + 2, $fn=128);

            // Mounting holes for ring
            if (mounting_holes_enabled) {
                for (a = [0, 90, 180, 270]) {
                    rotate([0, 0, a])
                    translate([tab_r, 0, -1])
                    cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
                }
            }

            // Magnet recesses for ring (on the PCB side at +Z)
            if (magnets_enabled && mounting_holes_enabled) {
                for (a = [0, 90, 180, 270]) {
                    rotate([0, 0, a])
                    translate([tab_r, 0, diffusion_height - magnet_depth])
                    cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
                }
            }

            // Cable cutout (on the PCB side at +Z)
            if (cutout_enabled) {
                if (cutout_side == "inner") {
                    translate([inner_diameter/2, 0, diffusion_height - cutout_depth/2 + 0.1])
                    cube([wall_thickness * 2 + 1, cutout_width, cutout_depth + 0.2], center=true);
                } else if (cutout_side == "outer") {
                    translate([actual_outer/2, 0, diffusion_height - cutout_depth/2 + 0.1])
                    cube([(frame_enabled ? frame_width : wall_thickness) * 2 + 1, cutout_width, cutout_depth + 0.2], center=true);
                }
            }
        }

        // Subtract cavities
        if (part == "all" || part == "body") {
            arc_pitch = PI * (outer_diameter + inner_diameter) / (2 * num_leds);
            for (i = [0 : num_leds - 1]) {
                angle = i * 360 / num_leds;
                h = diffusion_height - bottom_thickness;
                cavity_h = (part == "all") ? h + 0.1 : h + 0.2;
                z_pos = (part == "all") ? (bottom_thickness + h/2 + 0.05) : (bottom_thickness + h/2);
                delta = 2 * h * tan(draft_angle);

                rotate([0, 0, angle])
                translate([radius, 0, z_pos])
                if (cell_shape == "circular") {
                    exit_d = min(led_pitch, min(ring_width, arc_pitch)) - wall_thickness + tolerance;
                    entry_d = max(1.0, exit_d - delta);
                    cylinder(d1=exit_d, d2=entry_d, h=cavity_h, center=true, $fn=64);
                } else if (cell_shape == "hexagonal") {
                    exit_d = min(led_pitch, min(ring_width, arc_pitch)) - wall_thickness + tolerance;
                    entry_d = max(1.0, exit_d - delta);
                    cylinder(d1=exit_d, d2=entry_d, h=cavity_h, center=true, $fn=6);
                } else {
                    // For square cells in a ring, we rotate them to align with the radius
                    // Width is radial, height is tangential (arc-like)
                    w_exit = ring_width - wall_thickness + tolerance;
                    l_exit = arc_pitch - wall_thickness + tolerance;
                    w_entry = max(1.0, w_exit - delta);
                    l_entry = max(1.0, l_exit - delta);

                    hull() {
                        translate([0, 0, -cavity_h/2])
                        cube([w_exit, l_exit, 0.01], center=true);
                        translate([0, 0, cavity_h/2])
                        cube([w_entry, l_entry, 0.01], center=true);
                    }
                }

                // Capacitor clearance for ring (on the LED/PCB side at +Z, preserving inner/outer ring walls)
                if (cap_clearance_enabled) {
                    // We place cutouts between LEDs along the ring path
                    rotate([0, 0, angle + 180/num_leds])
                    translate([radius, 0, diffusion_height - cap_clearance_height/2 + 0.05])
                    cube([max(1.0, ring_width - 2*wall_thickness), cap_clearance_width, cap_clearance_height + 0.1], center=true);
                }
            }
        }

        // For Version 3 "body", subtract the recessed annular pocket for the lid while preserving inner and outer walls at z=0
        if (part == "body") {
            translate([0, 0, -0.1])
            difference() {
                cylinder(d=recess_outer, h=bottom_thickness + 0.1, $fn=128);
                translate([0, 0, -0.1])
                cylinder(d=recess_inner, h=bottom_thickness + 0.3, $fn=128);
            }
        }
    }
}

// --- Render Logic ---
if (type == "matrix") {
    matrix_layout();
} else if (type == "hex_matrix") {
    hex_matrix_layout();
} else if (type == "ring") {
    ring_layout();
} else {
    // Fallback to single cell
    translate([0, 0, diffusion_height/2]) cell();
}
