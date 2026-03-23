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

    difference() {
        union() {
            if (part == "all" || part == "body") {
                // Outer boundary of the cell with a tiny overlap to ensure manifold union
                overlap = 0.1;
                if (type == "hex_matrix") {
                    rotate([0, 0, 30])
                    cylinder(d=led_pitch / cos(30) + overlap, h=diffusion_height, center=true, $fn=6);
                } else {
                    cube([led_pitch + overlap, led_pitch + overlap, diffusion_height], center=true);
                }
            }
            // "diffuser" part as individual cells is handled differently in layouts for Version 3 (single lid)
            // but we keep this for backward compatibility with multi-material (Version 1 style)
            if (part == "diffuser") {
                overlap = 0.1;
                translate([0, 0, -diffusion_height/2 + bottom_thickness/2])
                if (type == "hex_matrix") {
                    rotate([0, 0, 30])
                    cylinder(d=led_pitch / cos(30) + overlap, h=bottom_thickness, center=true, $fn=6);
                } else {
                    cube([led_pitch + overlap, led_pitch + overlap, bottom_thickness], center=true);
                }
            }
        }

        // Subtract the cavity from the body
        if (part == "all" || part == "body") {
            // Inner cavity (hollow part)
            // For "all", it stops at bottom_thickness. For "body", it goes all the way through the main part
            cavity_h = diffusion_height + 0.2;
            z_offset = bottom_thickness/2 + 0.1;

            // Slightly smaller cavity subtractor to avoid cutting through unified walls
            cavity_overlap = 0.01;

            translate([0, 0, z_offset]) {
                if (cell_shape == "circular") {
                    cylinder(d1=exit_dim - cavity_overlap, d2=entry_dim - cavity_overlap, h=cavity_h, center=true, $fn=64);
                } else if (cell_shape == "hexagonal") {
                    rotate([0, 0, 30])
                    cylinder(d1=(exit_dim - cavity_overlap)/cos(30), d2=(entry_dim - cavity_overlap)/cos(30), h=cavity_h, center=true, $fn=6);
                } else {
                    hull() {
                        translate([0, 0, -cavity_h/2])
                        cube([exit_dim - cavity_overlap, exit_dim - cavity_overlap, 0.01], center=true);
                        translate([0, 0, cavity_h/2])
                        cube([entry_dim - cavity_overlap, entry_dim - cavity_overlap, 0.01], center=true);
                    }
                }
            }

            // For "body", we also subtract the entire top layer to make room for the lid
            if (part == "body") {
                translate([0, 0, -diffusion_height/2 + bottom_thickness/2])
                if (type == "hex_matrix") {
                    rotate([0, 0, 30])
                    cylinder(d=led_pitch / cos(30) + 0.15, h=bottom_thickness + 0.1, center=true, $fn=6);
                } else {
                    cube([led_pitch + 0.15, led_pitch + 0.15, bottom_thickness + 0.1], center=true);
                }
            }
        }
    }
}

module hex_matrix_layout() {
    matrix_layout();
}

module matrix_layout() {
    actual_row_end = (row_end == -1) ? rows - 1 : row_end;
    actual_col_end = (col_end == -1) ? cols - 1 : col_end;

    row_dist = (type == "hex_matrix") ? led_pitch * cos(30) : led_pitch;

    x_min = (col_start - 0.5) * led_pitch - frame_width;
    x_max = (actual_col_end + 0.5) * led_pitch + (type == "hex_matrix" && actual_row_end > 0 ? led_pitch/2 : 0) + frame_width;
    y_min = (row_start - 0.5) * led_pitch - frame_width;
    y_max = (type == "hex_matrix") ? actual_row_end * row_dist + led_pitch/2 + frame_width : (actual_row_end + 0.5) * led_pitch + frame_width;

    // Interior bounds for the lid
    lx_min = (col_start - 0.5) * led_pitch + lid_tolerance;
    lx_max = (actual_col_end + 0.5) * led_pitch + (type == "hex_matrix" && actual_row_end > 0 ? led_pitch/2 : 0) - lid_tolerance;
    ly_min = (row_start - 0.5) * led_pitch + lid_tolerance;
    ly_max = (type == "hex_matrix") ? actual_row_end * row_dist + led_pitch/2 - lid_tolerance : (actual_row_end + 0.5) * led_pitch - lid_tolerance;

    difference() {
        union() {
            // Optional frame
            if (frame_enabled && (part == "all" || part == "body")) {
                if (frame_radius > 0) {
                    // Rounded frame
                    difference() {
                        hull() {
                            translate([x_min + frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_min + frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_min + frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                            translate([x_max - frame_radius, y_max - frame_radius, 0]) cylinder(r=frame_radius, h=diffusion_height, $fn=32);
                        }
                        // Subtract interior
                        translate([x_min + frame_width, y_min + frame_width, -1])
                        cube([x_max - x_min - 2*frame_width, y_max - y_min - 2*frame_width, diffusion_height + 2]);
                    }
                } else {
                    // Left frame
                    if (col_start == 0) {
                        translate([x_min, y_min, 0])
                        cube([frame_width, y_max - y_min, diffusion_height]);
                    }
                    // Right frame
                    if (actual_col_end == cols - 1) {
                        translate([x_max - frame_width, y_min, 0])
                        cube([frame_width, y_max - y_min, diffusion_height]);
                    }
                    // Bottom frame
                    if (row_start == 0) {
                        translate([x_min, y_min, 0])
                        cube([x_max - x_min, frame_width, diffusion_height]);
                    }
                    // Top frame
                    if (actual_row_end == rows - 1) {
                        translate([x_min, y_max - frame_width, 0])
                        cube([x_max - x_min, frame_width, diffusion_height]);
                    }
                }
            }

            // Mounting tabs
            if (mounting_holes_enabled && frame_enabled) {
                tab_size = magnets_enabled ? max(mounting_hole_dia * 2, magnet_dia + 2) : mounting_hole_dia * 2;
                // Corners
                if (col_start == 0 && row_start == 0) {
                    translate([x_min, y_min, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && row_start == 0) {
                    translate([x_max, y_min, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (col_start == 0 && actual_row_end == rows - 1) {
                    translate([x_min, y_max, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
                if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                    translate([x_max, y_max, 0])
                    cylinder(d=tab_size, h=diffusion_height, $fn=32);
                }
            }

            if (part == "all" || part == "body") {
                difference() {
                    union() {
                        for (r = [row_start : actual_row_end]) {
                            x_offset = (type == "hex_matrix" && r % 2 != 0) ? led_pitch / 2 : 0;
                            for (c = [col_start : actual_col_end]) {
                                translate([c * led_pitch + x_offset, r * row_dist, diffusion_height/2])
                                cell();
                            }
                        }
                    }
                    if (cap_clearance_enabled) {
                        for (r = [row_start : actual_row_end]) {
                            x_offset = (type == "hex_matrix" && r % 2 != 0) ? led_pitch / 2 : 0;
                            for (c = [col_start : actual_col_end]) {
                                translate([c * led_pitch + x_offset, r * row_dist, 0])
                                for (a = [0, 90, 180, 270]) {
                                    rotate([0, 0, a])
                                    translate([led_pitch/2, 0, cap_clearance_height/2])
                                    // Ensure it doesn't meet the next one or sever the body completely
                                    cube([cap_clearance_width, led_pitch - 3.0, cap_clearance_height + 0.1], center=true);
                                }
                            }
                        }
                    }
                }
            } else if (part == "diffuser") {
                // One piece solid lid for version 3
                translate([(lx_min+lx_max)/2, (ly_min+ly_max)/2, bottom_thickness/2])
                if (type == "matrix") {
                    if (frame_radius > 0) {
                        hull() {
                            translate([lx_min+frame_radius, ly_min+frame_radius, 0]) cylinder(r=max(0.1, frame_radius - frame_width - lid_tolerance), h=bottom_thickness, center=true, $fn=32);
                            translate([lx_max-frame_radius, ly_min+frame_radius, 0]) cylinder(r=max(0.1, frame_radius - frame_width - lid_tolerance), h=bottom_thickness, center=true, $fn=32);
                            translate([lx_min+frame_radius, ly_max-frame_radius, 0]) cylinder(r=max(0.1, frame_radius - frame_width - lid_tolerance), h=bottom_thickness, center=true, $fn=32);
                            translate([lx_max-frame_radius, ly_max-frame_radius, 0]) cylinder(r=max(0.1, frame_radius - frame_width - lid_tolerance), h=bottom_thickness, center=true, $fn=32);
                        }
                    } else {
                        cube([lx_max-lx_min, ly_max-ly_min, bottom_thickness], center=true);
                    }
                } else if (type == "hex_matrix") {
                     intersection() {
                        translate([0, 0, 0])
                        cube([lx_max-lx_min, ly_max-ly_min, bottom_thickness], center=true);

                        hull() {
                            for (r = [row_start, actual_row_end]) {
                                x_offset = (r % 2 == 0) ? 0 : led_pitch / 2;
                                for (c = [col_start, actual_col_end]) {
                                    translate([c * led_pitch + x_offset, r * row_dist, 0])
                                    rotate([0, 0, 30])
                                    cylinder(d=(led_pitch - 2*lid_tolerance) / cos(30), h=bottom_thickness, center=true, $fn=6);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Mounting holes
        if (mounting_holes_enabled && frame_enabled) {
            // Corners
            if (col_start == 0 && row_start == 0) {
                translate([x_min, y_min, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (actual_col_end == cols - 1 && row_start == 0) {
                translate([x_max, y_min, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (col_start == 0 && actual_row_end == rows - 1) {
                translate([x_min, y_max, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
            if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                translate([x_max, y_max, -1])
                cylinder(d=mounting_hole_dia, h=diffusion_height + 2, $fn=32);
            }
        }

        // Frame Labeling
        if (label_text != "" && frame_enabled) {
            // Place on bottom frame by default
            translate([(x_max+x_min)/2, y_min + frame_width/2, diffusion_height - label_depth])
            linear_extrude(height = label_depth + 0.1)
            text(label_text, size = label_size, halign = "center", valign = "center");
        }

        // Magnet recesses
        if (magnets_enabled && mounting_holes_enabled && frame_enabled) {
            // Corners
            if (col_start == 0 && row_start == 0) {
                translate([x_min, y_min, -0.1])
                cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
            }
            if (actual_col_end == cols - 1 && row_start == 0) {
                translate([x_max, y_min, -0.1])
                cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
            }
            if (col_start == 0 && actual_row_end == rows - 1) {
                translate([x_min, y_max, -0.1])
                cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
            }
            if (actual_col_end == cols - 1 && actual_row_end == rows - 1) {
                translate([x_max, y_max, -0.1])
                cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
            }
        }

        // Cable cutout
        if (cutout_enabled) {
            if (cutout_side == "bottom" && row_start == 0) {
                translate([(x_max+x_min)/2, y_min + frame_width/2, cutout_depth/2 - 0.1])
                cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "top" && actual_row_end == rows - 1) {
                translate([(x_max+x_min)/2, y_max - frame_width/2, cutout_depth/2 - 0.1])
                cube([cutout_width, frame_width + 2, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "left" && col_start == 0) {
                translate([x_min + frame_width/2, (y_max+y_min)/2, cutout_depth/2 - 0.1])
                cube([frame_width + 2, cutout_width, cutout_depth + 0.2], center=true);
            } else if (cutout_side == "right" && actual_col_end == cols - 1) {
                translate([x_max - frame_width/2, (y_max+y_min)/2, cutout_depth/2 - 0.1])
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
            if (part == "all" || part == "body") {
                cylinder(d=actual_outer, h=diffusion_height, $fn=128);
            } else if (part == "diffuser") {
                // Lid for the ring
                difference() {
                    cylinder(d=outer_diameter - 2*lid_tolerance, h=bottom_thickness, $fn=128);
                    translate([0, 0, -1])
                    cylinder(d=inner_diameter + 2*lid_tolerance, h=bottom_thickness + 2, $fn=128);
                }
            }

            // Mounting tabs for ring
            if (mounting_holes_enabled && (part == "all" || part == "body")) {
                tab_size = magnets_enabled ? max(mounting_hole_dia * 2, magnet_dia + 2) : mounting_hole_dia * 2;
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

        // Magnet recesses for ring
        if (magnets_enabled && mounting_holes_enabled) {
            for (a = [0, 90, 180, 270]) {
                rotate([0, 0, a])
                translate([actual_outer/2, 0, -0.1])
                cylinder(d=magnet_dia, h=magnet_depth + 0.1, $fn=32);
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
        if (part == "all" || part == "body") {
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

            // Capacitor clearance for ring
            if (cap_clearance_enabled) {
                for (i = [0 : num_leds - 1]) {
                    angle = i * 360 / num_leds;
                    rotate([0, 0, angle + 180/num_leds])
                    translate([radius, 0, cap_clearance_height/2])
                    cube([ring_width + 2, cap_clearance_width, cap_clearance_height + 0.1], center=true);
                }
            }
        }

        // For Version 3 "body", also subtract the recessed ring for the lid
        if (part == "body") {
            translate([0, 0, -0.1])
            difference() {
                cylinder(d=outer_diameter + 0.1, h=bottom_thickness + 0.1, $fn=128);
                translate([0, 0, -0.1])
                cylinder(d=inner_diameter - 0.1, h=bottom_thickness + 0.3, $fn=128);
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
