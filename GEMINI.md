# Projektziel
Ein Generator für 3D-Druckdateien von Diffusoraufsätzen an parametrierbaren Größen an NeoPixel-Panels.

## Zielgrößen
- 16x16 Panel (160x160mm, 10mm Pitch)
- 8x32 Panel (80x320mm, 10mm Pitch)
- Runder Ring mit 20 NeoPixeln (ca. 62mm OD)

## Aktueller Status (Alle Schritte 1-30 implementiert)
- [x] 1. Analyse der Hardware-Dimensionen
- [x] 2. Recherche Ring-Parameter
- [x] 3. OpenSCAD Umgebung einrichten (`src/diffuser.scad`)
- [x] 4. Definition des LED-Pitch (Variable `led_pitch`)
- [x] 5. Parameter für Wandstärke (Variable `wall_thickness`)
- [x] 6. Definition der Diffusionshöhe (Variable `diffusion_height`)
- [x] 7. Modellierung einer Einzelzelle (Modul `single_cell()`)
- [x] 8. Parametrisierung der Zellform
- [x] 9. Implementierung des Matrix-Generators
- [x] 10. Toleranz-Management
- [x] 11. Entwicklung der 16x16 Konfiguration
- [x] 12. Entwicklung der 8x32 Konfiguration
- [x] 13. Mathematik für den Ring-Diffusor
- [x] 14. Implementierung des Ring-Moduls
- [x] 15. Hohlraum-Design (Tapered Cavities)
- [x] 16. Boden-Integration
- [x] 17. Kabelaussparungen
- [x] 18. Montage-Elemente (Mounting Holes)
- [x] 19. Stabilitätsrahmen
- [x] 20. Modularitäts-Option
- [x] 21. Python-Wrapper erstellen
- [x] 22. Automatisierter STL-Export
- [x] 23. Vorschau-Generierung
- [x] 24. Konfigurationsdatei (JSON)
- [x] 25. Fehlerbehandlung im Skript
- [x] 26. Optimierung der Wandgeometrie (Draft Angles)
- [x] 27. Batch-Processing
- [x] 28. Slicer-Test (Virtuell)
- [x] 29. Dokumentation der Parameter
- [x] 30. Abschluss und Review
- [x] 31. GitHub Pages Integration (STL 3D Viewers)
- [x] 32. Magnet-Halterungen
- [x] 33. Multi-Material-Automatisierung
- [x] 34. Erweiterte Konfigurationen & Bugfixes

## Projektstruktur
- `/src`: OpenSCAD Quellcode (`diffuser.scad`)
- `/stl`: Generierte 3D-Druckdateien
- `/scripts`: Python-Automatisierung für Batch-Export
- `.github/workflows`: GitHub Action zur automatischen Generierung bei Änderungen

## Automatisierung
Die Generierung der STL-Dateien erfolgt automatisch über GitHub Actions bei jedem Push auf den `main` Branch. Die Dateien werden als Artifacts hochgeladen.
