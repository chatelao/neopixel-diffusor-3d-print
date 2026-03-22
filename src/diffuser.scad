// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
type = "matrix";            // "matrix", "hex_matrix", or "ring"
led_pitch = 10;             // Center-to-center distance between LEDs (mm)
tolerance = 0.1;            // Offset for fit (mm)
wall_thickness = 0.8;       // Width of the dividing walls (mm)
diffusion_height = 10;      // Total height from LED to top (mm)
diffuser_thickness = 0.4;   // Thickness of the top diffusion layer (mm)
cell_shape = "square";      // "square", "circular", or "hexagonal"
draft_angle = 0;            // Angle of the side walls (degrees)

// Multi-material support
part = "all";               // "all", "body", or "diffuser"

// Capacitor clearance
cap_clearance_enabled = false; // Space for SMD capacitors
cap_clearance_width = 2.5;     // Width of the cutout (mm)
cap_clearance_height = 1.5;    // Height of the cutout (mm)

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

// --- Helper Modules ---

module hexagon(d, h) {
    cylinder(d=d, h=h, $fn=6, center=true);
}

// --- Core Modules ---

// Module for a single diffuser cell
module cell(is_diffuser_part = false) {
    cavity_h = diffusion_height - diffuser_thickness;

    // exit_dim is at the top of the cavity (widest part)
    exit_dim = led_pitch - wall_thickness + tolerance;
    // draft_angle makes the cavity narrower towards the LED (bottom)
    delta = 2 * cavity_h * tan(draft_angle);
    entry_dim = max(1.0, exit_dim - delta);

    if (is_diffuser_part) {
        // Render the diffusion layer for this cell
        if (diffuser_thickness > 0) {
            translate([0, 0, diffusion_height - diffuser_thickness/2])
            if (type == "hex_matrix" || cell_shape == "hexagonal") {
                if (type == "hex_matrix") {
                    hexagon(d = led_pitch / cos(30), h = diffuser_thickness);
                } else {
                    cube([led_pitch, led_pitch, diffuser_thickness], center=true);
                }
            } else {
                cube([led_pitch, led_pitch, diffuser_thickness], center=true);
            }
        }
    } else {
        // Render the body part of the cell (block minus cavity and minus diffuser layer space if in body mode)
        difference() {
            // Outer boundary
            translate([0, 0, diffusion_height/2])
            if (type == "hex_matrix") {
                hexagon(d = led_pitch / cos(30), h = diffusion_height);
            } else {
                cube([led_pitch, led_pitch, diffusion_height], center=true);
            }

            // Cavity (subtracted)
            translate([0, 0, cavity_h/2])
            if (cell_shape == "circular") {
                // d1 is at bottom (entry), d2 is at top (exit)
                cylinder(d1=entry_dim, d2=exit_dim, h=cavity_h + 0.01, center=true, $fn=64);
            } else if (cell_shape == "hexagonal") {
                hull() {
                    translate([0, 0, -cavity_h/2])
                    hexagon(d=entry_dim, h=0.01);
                    translate([0, 0, cavity_h/2])
                    hexagon(d=exit_dim, h=0.01);
                }
            } else {
                hull() {
                    translate([0, 0, -cavity_h/2])
                    cube([entry_dim, entry_dim, 0.01], center=true);
                    translate([0, 0, cavity_h/2])
                    cube([exit_dim, exit_dim, 0.01], center=true);
                }
            }

            // Subtract space for diffuser if we are in body-only mode
            if (part == "body") {
                translate([0, 0, diffusion_height - diffuser_thickness/2 + 0.01])
                if (type == "hex_matrix") {
                    hexagon(d = led_pitch / cos(30) + 0.01, h = diffuser_thickness + 0.02);
                } else {
                    cube([led_pitch + 0.01, led_pitch + 0.01, diffuser_thickness + 0.02], center=true);
                }
            }

            // Capacitor clearance
            if (cap_clearance_enabled) {
                angles = (type == "hex_matrix" || cell_shape == "hexagonal") ? [0, 60, 120, 180, 240, 300] : [0, 90, 180, 270];
                for (a = angles) {
                    rotate([0, 0, a])
                    translate([led_pitch/2, 0, cap_clearance_height/2])
                    cube([cap_clearance_width, led_pitch + 0.1, cap_clearance_height + 0.1], center=true);
                }
            }
        }
    }
}

module matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;

    difference() {
        union() {
            // Frame and Tabs (only for body or all)
            if (part != "diffuser") {
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

                if (mounting_holes_enabled && frame_enabled) {
                    tab_size = mounting_hole_dia * 2;
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
            }

            // Cells
            for (r = [row_start : actual_row_end]) {
                for (c = [col_start : actual_col_end]) {
                    translate([c * led_pitch, r * led_pitch, 0]) {
                        if (part == "all" || part == "body") cell(is_diffuser_part=false);
                        if (part == "all" || part == "diffuser") cell(is_diffuser_part=true);
                    }
                }
            }
        }

        // Subtract from body (Holes and Cutouts)
        if (part != "diffuser") {
            if (mounting_holes_enabled && frame_enabled) {
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
}

module hex_matrix_layout() {
    dx = led_pitch;
    dy = led_pitch * cos(30);

    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;

    for (r = [row_start : actual_row_end]) {
        for (c = [col_start : actual_col_end]) {
            offset = (r % 2) * dx / 2;
            translate([c * dx + offset, r * dy, 0]) {
                if (part == "all" || part == "body") cell(is_diffuser_part=false);
                if (part == "all" || part == "diffuser") cell(is_diffuser_part=true);
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
            if (part != "diffuser") {
                // Ring body
                difference() {
                    cylinder(d=actual_outer, h=diffusion_height, $fn=128);

                    // Subtract diffuser layer space if in body mode
                    if (part == "body" && diffuser_thickness > 0) {
                        translate([0, 0, diffusion_height - diffuser_thickness + 0.01])
                        cylinder(d=outer_diameter + 0.01, h=diffuser_thickness + 0.02, $fn=128);
                    }
                }

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

            if (part == "all" || part == "diffuser") {
                if (diffuser_thickness > 0) {
                    translate([0, 0, diffusion_height - diffuser_thickness])
                    difference() {
                        cylinder(d=outer_diameter, h=diffuser_thickness, $fn=128);
                        translate([0, 0, -1])
                        cylinder(d=inner_diameter, h=diffuser_thickness + 2, $fn=128);
                    }
                }
            }
        }

        if (part != "diffuser") {
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
                cavity_h = diffusion_height - (part == "body" ? 0 : diffuser_thickness);
                // Wait, if part == "body", we already cut out the top thickness above.
                // But the cavity itself still needs to be subtracted from what's left.
                // Actually it's cleaner to keep cavity_h as diffusion_height - diffuser_thickness
                // and just rely on the fact that the body top is already trimmed.
                h_eff = diffusion_height - diffuser_thickness;
                delta = 2 * h_eff * tan(draft_angle);

                // exit_dim is at the top of the cavity
                exit_d = led_pitch - wall_thickness + tolerance;
                entry_d = max(1.0, exit_d - delta);

                rotate([0, 0, angle])
                translate([radius, 0, h_eff/2])
                if (cell_shape == "circular") {
                    cylinder(d1=entry_d, d2=exit_d, h=h_eff + 0.1, center=true, $fn=64);
                } else if (cell_shape == "hexagonal") {
                    hull() {
                        translate([0, 0, -h_eff/2]) hexagon(d=entry_d, h=0.01);
                        translate([0, 0, h_eff/2]) hexagon(d=exit_d, h=0.01);
                    }
                } else {
                    w_exit = ring_width - wall_thickness + tolerance;
                    l_exit = (3.14159 * (outer_diameter+inner_diameter)/2 / num_leds) - wall_thickness + tolerance;
                    w_entry = max(1.0, w_exit - delta);
                    l_entry = max(1.0, l_exit - delta);

                    hull() {
                        translate([0, 0, -h_eff/2])
                        cube([w_entry, l_entry, 0.01], center=true);
                        translate([0, 0, h_eff/2])
                        cube([w_exit, l_exit, 0.01], center=true);
                    }
                }

                // Capacitor clearance for ring
                if (cap_clearance_enabled) {
                    rotate([0, 0, angle + 180/num_leds])
                    translate([radius, 0, cap_clearance_height/2])
                    cube([ring_width + 2, cap_clearance_width, cap_clearance_height + 0.1], center=true);
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
    if (part == "all" || part == "body") cell(is_diffuser_part=false);
    if (part == "all" || part == "diffuser") cell(is_diffuser_part=true);
}
