// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
type = "matrix";          // "matrix" or "ring"
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
tolerance = 0.1;          // Offset for fit (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)
cell_shape = "square";    // "square", "circular" or "hexagonal"
draft_angle = 0;          // Angle of the side walls (degrees)

// Multi-Material
part = "all";             // "all", "body", "diffuser"

// Stability frame
frame_enabled = false;    // Add a reinforced outer frame
frame_width = 2.0;        // Thickness of the outer frame (mm)

// Cable cutouts
cutout_enabled = false;   // Add cutouts for cables
cutout_width = 10;        // Width of the cable cutout (mm)
cutout_depth = 3;         // Depth of the cable cutout (mm)
cutout_side = "bottom";   // "left", "right", "top", "bottom" or "inner", "outer"

// Mounting holes
mounting_holes_enabled = false;
mounting_hole_dia = 3.0;

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

    if (part == "all" || part == "body") {
        difference() {
            // Outer boundary of the cell
            cube([led_pitch, led_pitch, diffusion_height], center=true);

            // Inner cavity (hollow part)
            // d1 is at diffusion layer, d2 is at LED side
            translate([0, 0, bottom_thickness/2])
            if (cell_shape == "circular") {
                cylinder(d1=exit_dim, d2=entry_dim, h=h + 0.1, center=true, $fn=64);
            } else if (cell_shape == "hexagonal") {
                // d = 2 * r_inscribed; exit_dim is roughly the width
                cylinder(d1=exit_dim/cos(30), d2=entry_dim/cos(30), h=h + 0.1, center=true, $fn=6);
            } else {
                hull() {
                    translate([0, 0, -h/2])
                    cube([exit_dim, exit_dim, 0.01], center=true);
                    translate([0, 0, h/2])
                    cube([entry_dim, entry_dim, 0.01], center=true);
                }
            }

            // If we are printing only the body, remove the diffusion layer area
            if (part == "body") {
                translate([0, 0, -diffusion_height/2 + bottom_thickness/2])
                cube([led_pitch + 0.1, led_pitch + 0.1, bottom_thickness + 0.01], center=true);
            }
        }
    }

    if (part == "diffuser") {
        translate([0, 0, -diffusion_height/2 + bottom_thickness/2])
        cube([led_pitch, led_pitch, bottom_thickness], center=true);
    }
}

module hex_matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;

    // In a hex grid, vertical pitch is pitch * sin(60)
    v_pitch = led_pitch * sqrt(3) / 2;

    difference() {
        union() {
            for (r = [row_start : actual_row_end]) {
                row_offset = (r % 2 == 1) ? led_pitch / 2 : 0;
                for (c = [col_start : actual_col_end]) {
                    translate([c * led_pitch + row_offset, r * v_pitch, diffusion_height/2])
                    cell();
                }
            }
        }
        // Frame/Mounting logic for hex can be complex, skipping for now unless needed
    }
}

module matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;

    total_width = cols * led_pitch;
    total_height = rows * led_pitch;

    difference() {
        union() {
            // Optional frame
            if (frame_enabled) {
                // Left frame
                if (col_start == 0) {
                    translate([-led_pitch/2 - frame_width, (row_start-0.5)*led_pitch, 0])
                    cube([frame_width, (actual_row_end - row_start + 1) * led_pitch, diffusion_height]);
                }
                // Right frame
                if (actual_col_end == cols - 1) {
                    translate([(actual_col_end+0.5)*led_pitch, (row_start-0.5)*led_pitch, 0])
                    cube([frame_width, (actual_row_end - row_start + 1) * led_pitch, diffusion_height]);
                }
                // Bottom frame
                if (row_start == 0) {
                    translate([(col_start-0.5)*led_pitch - (col_start == 0 ? frame_width : 0), -led_pitch/2 - frame_width, 0])
                    cube([(actual_col_end - col_start + 1) * led_pitch + (col_start == 0 ? frame_width : 0) + (actual_col_end == cols - 1 ? frame_width : 0), frame_width, diffusion_height]);
                }
                // Top frame
                if (actual_row_end == rows - 1) {
                    translate([(col_start-0.5)*led_pitch - (col_start == 0 ? frame_width : 0), (actual_row_end+0.5)*led_pitch, 0])
                    cube([(actual_col_end - col_start + 1) * led_pitch + (col_start == 0 ? frame_width : 0) + (actual_col_end == cols - 1 ? frame_width : 0), frame_width, diffusion_height]);
                }
            }

            // Mounting tabs
            if (mounting_holes_enabled && frame_enabled) {
                tab_size = mounting_hole_dia * 2;
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([-led_pitch/2 - frame_width, -led_pitch/2 - frame_width, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([(cols-1)*led_pitch + led_pitch/2 + frame_width, -led_pitch/2 - frame_width, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([-led_pitch/2 - frame_width, (rows-1)*led_pitch + led_pitch/2 + frame_width, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([(cols-1)*led_pitch + led_pitch/2 + frame_width, (rows-1)*led_pitch + led_pitch/2 + frame_width, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }

            for (r = [row_start : actual_row_end]) {
                for (c = [col_start : actual_col_end]) {
                    translate([c * led_pitch, r * led_pitch, diffusion_height/2])
                    cell();
                }
            }
        }

        // Mounting holes
        if (mounting_holes_enabled && frame_enabled) {
            // Corners
            if (col_start == 0 && row_start == 0) {
                translate([-led_pitch/2 - frame_width, -led_pitch/2 - frame_width, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (actual_col_end == cols - 1 && row_start == 0) {
                translate([(cols-1)*led_pitch + led_pitch/2 + frame_width, -led_pitch/2 - frame_width, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (col_start == 0 && actual_row_end == rows - 1) {
                translate([-led_pitch/2 - frame_width, (rows-1)*led_pitch + led_pitch/2 + frame_width, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                translate([(cols-1)*led_pitch + led_pitch/2 + frame_width, (rows-1)*led_pitch + led_pitch/2 + frame_width, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
        }

        // Cable cutout
        if (cutout_enabled) {
            if (cutout_side == "bottom" && row_start == 0) {
                translate([(cols-1)*led_pitch/2, -led_pitch/2 - frame_width/2, cutout_depth/2 - 0.1])
                cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "top" && actual_row_end == rows - 1) {
                translate([(cols-1)*led_pitch/2, (rows-1)*led_pitch + led_pitch/2 + frame_width/2, cutout_depth/2 - 0.1])
                cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "left" && col_start == 0) {
                translate([-led_pitch/2 - frame_width/2, (rows-1)*led_pitch/2, cutout_depth/2 - 0.1])
                cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "right" && actual_col_end == cols - 1) {
                translate([(cols-1)*led_pitch + led_pitch/2 + frame_width/2, (rows-1)*led_pitch/2, cutout_depth/2 - 0.1])
                cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
            }
        }
    }
}

module ring_layout() {
    radius = (outer_diameter + inner_diameter) / 4;
    ring_width = (outer_diameter - inner_diameter) / 2;
    actual_outer = frame_enabled ? outer_diameter + 2*frame_width : outer_diameter;

    difference() {
        union() {
            // Ring body
            cylinder(d=actual_outer, h=diffusion_height, $fn=128);

            // Mounting tabs for ring
            if (mounting_holes_enabled) {
                tab_size = mounting_hole_dia * 2;
                for (a = [0, 90, 180, 270]) {
                    rotate([0, 0, a])
                    translate([actual_outer/2, 0, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }
        }

        translate([0, 0, -1])
        cylinder(d=inner_diameter, h=diffusion_height + 2, $fn=128);

        // Mounting holes for ring
        if (mounting_holes_enabled) {
            for (a = [0, 90, 180, 270]) {
                rotate([0, 0, a])
                translate([actual_outer/2, 0, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
        }

        // Cable cutout
        if (cutout_enabled) {
            if (cutout_side == "inner") {
                translate([inner_diameter/2, 0, cutout_depth/2 - 0.1])
                cube([frame_width + 5, cutout_width, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "outer") {
                translate([actual_outer/2, 0, cutout_depth/2 - 0.1])
                cube([frame_width + 5, cutout_width, cutout_depth + 0.2], center=true);
            }
        }

        // Subtract cavities
        for (i = [0 : num_leds - 1]) {
            angle = i * 360 / num_leds;
            h = diffusion_height - bottom_thickness;
            delta = 2 * h * tan(draft_angle);

            rotate([0, 0, angle])
            translate([radius, 0, bottom_thickness + h/2])
            if (cell_shape == "circular") {
                exit_d = led_pitch - wall_thickness + tolerance;
                entry_d = max(1.0, exit_d - delta);
                cylinder(d1=exit_d, d2=entry_d, h=h + 0.1, center=true, $fn=64);
            } else {
                // For square cells in a ring, we rotate them to align with the radius
                // Width is radial, height is tangential (arc-like)
                w_exit = ring_width - wall_thickness + tolerance;
                l_exit = (3.14159 * (outer_diameter+inner_diameter)/2 / num_leds) - wall_thickness + tolerance;
                w_entry = max(1.0, w_exit - delta);
                l_entry = max(1.0, l_exit - delta);

                hull() {
                    translate([0, 0, -h/2])
                    cube([w_exit, l_exit, 0.01], center=true);
                    translate([0, 0, h/2])
                    cube([w_entry, l_entry, 0.01], center=true);
                }
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
