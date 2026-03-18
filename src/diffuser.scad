// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)
cell_shape = "square";    // "square" or "circular" (Step 8)
tolerance = 0.1;          // Extra space for the cavity to ensure LEDs fit (Step 10)

// Parameters passed from Python/CLI (Steps 11 & 12)
type = "matrix";          // "matrix" or "ring"
panel_type = "custom";    // "16x16", "8x32", or "custom"
rows = 16;
cols = 16;
num_leds = 20;            // For ring
outer_diameter = 62;      // For ring
inner_diameter = 47;      // For ring

// --- Predefined Configurations (Steps 11 & 12) ---
// These values are used if panel_type is set accordingly.
effective_rows = (panel_type == "16x16") ? 16 : (panel_type == "8x32" ? 8 : rows);
effective_cols = (panel_type == "16x16") ? 16 : (panel_type == "8x32" ? 32 : cols);

// --- Modules ---

// Module for a single diffuser cell (Step 7 & 8)
module single_cell(shape="square") {
    // Cavity dimension with tolerance for fit
    cavity_dim = led_pitch - wall_thickness + tolerance;

    difference() {
        // Outer boundary of the cell (Grid spacing is maintained)
        cube([led_pitch, led_pitch, diffusion_height], center=true);

        // Inner cavity (hollow part)
        // Centered within the led_pitch x led_pitch area
        translate([0, 0, bottom_thickness/2])
        if (shape == "circular" || shape == "round") {
            cylinder(d = cavity_dim, h = diffusion_height - bottom_thickness + 0.1, center=true, $fn=64);
        } else {
            cube([cavity_dim, cavity_dim, diffusion_height - bottom_thickness + 0.1], center=true);
        }
    }
}

// Matrix generator (Step 9 & 10)
module matrix_layout(r, c) {
    // The grid spacing MUST be exactly led_pitch to match the PCB.
    for (y = [0 : r - 1]) {
        for (x = [0 : c - 1]) {
            translate([x * led_pitch, y * led_pitch, diffusion_height/2])
            single_cell(cell_shape);
        }
    }
}

// Ring generator (Step 14)
module ring_layout() {
    radius = (outer_diameter + inner_diameter) / 4;
    ring_width = (outer_diameter - inner_diameter) / 2;
    cavity_dim = led_pitch - wall_thickness + tolerance;

    difference() {
        // Ring body
        cylinder(d=outer_diameter + tolerance, h=diffusion_height, $fn=128);
        translate([0, 0, -1])
        cylinder(d=inner_diameter - tolerance, h=diffusion_height + 2, $fn=128);

        // Subtract cavities
        for (i = [0 : num_leds - 1]) {
            angle = i * 360 / num_leds;
            rotate([0, 0, angle])
            translate([radius, 0, bottom_thickness + (diffusion_height - bottom_thickness)/2])
            if (cell_shape == "circular" || cell_shape == "round") {
                cylinder(d=cavity_dim, h=diffusion_height - bottom_thickness + 0.1, center=true, $fn=64);
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
    matrix_layout(effective_rows, effective_cols);
} else if (type == "ring") {
    ring_layout();
} else {
    // Fallback to single cell
    translate([0, 0, diffusion_height/2]) single_cell(cell_shape);
}
