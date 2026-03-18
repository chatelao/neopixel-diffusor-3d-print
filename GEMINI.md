# Projektziel
Ein Generator für 3D-Druckdateien von Diffusoraufsätzen an parametrierbaren Größen an NeoPixel-Panels.

## Zielgrößen
- 16x16 Panel (160x160mm, 10mm Pitch)
- 8x32 Panel (80x320mm, 10mm Pitch)
- Runder Ring mit 20 NeoPixeln (ca. 62mm OD)

## Aktueller Status (Implementierte Schritte 1-7)
- [x] 1. Analyse der Hardware-Dimensionen
- [x] 2. Recherche Ring-Parameter
- [x] 3. OpenSCAD Umgebung einrichten (`src/diffuser.scad`)
- [x] 4. Definition des LED-Pitch (Variable `led_pitch`)
- [x] 5. Parameter für Wandstärke (Variable `wall_thickness`)
- [x] 6. Definition der Diffusionshöhe (Variable `diffusion_height`)
- [x] 7. Modellierung einer Einzelzelle (Modul `single_cell()`)

## Projektstruktur
- `/src`: OpenSCAD Quellcode (`diffuser.scad`)
- `/stl`: Generierte 3D-Druckdateien
- `/scripts`: Python-Automatisierung für Batch-Export
- `.github/workflows`: GitHub Action zur automatischen Generierung bei Änderungen

## Automatisierung
Die Generierung der STL-Dateien erfolgt automatisch über GitHub Actions bei jedem Push auf den `main` Branch. Die Dateien werden als Artifacts hochgeladen.
