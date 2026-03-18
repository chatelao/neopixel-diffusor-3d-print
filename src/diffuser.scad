// Parametric NeoPixel Diffuser Generator

// --- Global Parameters ---
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)
cell_shape = "square";    // "square" or "round" (Step 8)
tolerance = 0.1;          // Extra space for the cavity to ensure LEDs fit (Step 10)

// Parameters passed from Python/CLI (Steps 11 & 12)
type = "matrix";          // "matrix" or "ring"
panel_type = "custom";    // "16x16", "8x32", or "custom"
rows = 1;
cols = 1;
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
        cube([led_pitch, led_pitch, diffusion_height]);

        // Inner cavity (hollow part)
        // Centered within the led_pitch x led_pitch area
        translate([(led_pitch - cavity_dim)/2, (led_pitch - cavity_dim)/2, -1])
        if (shape == "round") {
            translate([cavity_dim/2, cavity_dim/2, 0])
            cylinder(d = cavity_dim, h = diffusion_height - bottom_thickness + 1, $fn=64);
        } else {
            cube([cavity_dim, cavity_dim, diffusion_height - bottom_thickness + 1]);
        }
    }
}

// Matrix generator (Step 9 & 10)
module matrix_diffuser(r, c) {
    // The grid spacing MUST be exactly led_pitch to match the PCB.
    for (y = [0 : r - 1]) {
        for (x = [0 : c - 1]) {
            translate([x * led_pitch, y * led_pitch, 0])
            single_cell(cell_shape);
        }
    }
}

// Ring generator (Step 14 placeholder improved)
module ring_diffuser() {
    difference() {
        // Outer ring
        cylinder(d = outer_diameter + tolerance, h = diffusion_height, $fn=100);
        // Inner cutout
        translate([0, 0, -1])
        cylinder(d = inner_diameter - tolerance, h = diffusion_height + 2, $fn=100);
    }
}

// --- Render Logic ---
if (type == "matrix") {
    matrix_diffuser(effective_rows, effective_cols);
} else if (type == "ring") {
    ring_diffuser();
} else {
    single_cell(cell_shape);
}
