// Parametric NeoPixel Diffuser Generator
// Steps 3-7: Setup, Pitch, Wall Thickness, Diffusion Height, Single Cell Module

// --- Global Parameters ---
led_pitch = 10;           // Center-to-center distance between LEDs (mm)
wall_thickness = 0.8;     // Width of the dividing walls (mm)
diffusion_height = 10;    // Distance from LED to diffuser top (mm)
bottom_thickness = 0.4;   // Optional thin diffusion layer at the top (mm)

// --- Modules ---

// Module for a single square diffuser cell (Step 7)
module single_cell() {
    difference() {
        // Outer boundary of the cell
        cube([led_pitch, led_pitch, diffusion_height]);

        // Inner cavity (hollow part)
        // Shifted to maintain wall thickness on all sides
        translate([wall_thickness/2, wall_thickness/2, -1])
        cube([led_pitch - wall_thickness, led_pitch - wall_thickness, diffusion_height - bottom_thickness + 1]);
    }
}

// --- Render Logic (added to support automated generation) ---
// By default, we render a single cell as per step 7.
// In future steps, this will be expanded to support matrix and ring layouts.
single_cell();
