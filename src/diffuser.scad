// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
type = "matrix";          // "matrix" or "ring"
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
tolerance = 0.1;          // Offset for fit (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)
cell_shape = "square";    // "square" or "circular"

// Stability frame
frame_enabled = false;    // Add a reinforced outer frame
frame_width = 2.0;        // Thickness of the outer frame (mm)

// Matrix specific
rows = 16;
cols = 16;

// Ring specific
num_leds = 20;
outer_diameter = 62;
inner_diameter = 47;

// --- Modules ---

// Module for a single diffuser cell
module cell() {
    difference() {
        // Outer boundary of the cell
        cube([led_pitch, led_pitch, diffusion_height], center=true);

        // Inner cavity (hollow part)
        translate([0, 0, bottom_thickness/2])
        if (cell_shape == "circular") {
            cylinder(d=led_pitch - wall_thickness + tolerance, h=diffusion_height - bottom_thickness + 0.1, center=true, $fn=64);
        } else {
            cube([led_pitch - wall_thickness + tolerance, led_pitch - wall_thickness + tolerance, diffusion_height - bottom_thickness + 0.1], center=true);
        }
    }
}

module matrix_layout() {
    total_width = cols * led_pitch;
    total_height = rows * led_pitch;

    // Optional frame
    if (frame_enabled) {
        translate([-led_pitch/2, -led_pitch/2, 0])
        difference() {
            translate([-frame_width, -frame_width, 0])
            cube([total_width + 2*frame_width, total_height + 2*frame_width, diffusion_height]);

            translate([0, 0, -1])
            cube([total_width, total_height, diffusion_height + 2]);
        }
    }

    for (r = [0 : rows - 1]) {
        for (c = [0 : cols - 1]) {
            translate([c * led_pitch, r * led_pitch, diffusion_height/2])
            cell();
        }
    }
}

module ring_layout() {
    radius = (outer_diameter + inner_diameter) / 4;
    ring_width = (outer_diameter - inner_diameter) / 2;
    actual_outer = frame_enabled ? outer_diameter + 2*frame_width : outer_diameter;

    difference() {
        // Ring body
        cylinder(d=actual_outer, h=diffusion_height, $fn=128);
        translate([0, 0, -1])
        cylinder(d=inner_diameter, h=diffusion_height + 2, $fn=128);

        // Subtract cavities
        for (i = [0 : num_leds - 1]) {
            angle = i * 360 / num_leds;
            rotate([0, 0, angle])
            translate([radius, 0, bottom_thickness + (diffusion_height - bottom_thickness)/2])
            if (cell_shape == "circular") {
                cylinder(d=led_pitch - wall_thickness + tolerance, h=diffusion_height - bottom_thickness + 0.1, center=true, $fn=64);
            } else {
                // For square cells in a ring, we rotate them to align with the radius
                // Width is radial, height is tangential (arc-like)
                cube([ring_width - wall_thickness + tolerance, (3.14159 * (outer_diameter+inner_diameter)/2 / num_leds) - wall_thickness + tolerance, diffusion_height - bottom_thickness + 0.1], center=true);
            }
        }
    }
}

// --- Render Logic ---
if (type == "matrix") {
    matrix_layout();
} else if (type == "ring") {
    ring_layout();
} else {
    // Fallback to single cell
    translate([0, 0, diffusion_height/2]) cell();
}
