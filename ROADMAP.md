# Roadmap: 3D-Druck Diffusor-Generator für NeoPixel Panels

Diese Roadmap beschreibt die 30 Schritte zur Umsetzung eines parametrierbaren Generators für 3D-gedruckte Diffusor-Aufsätze.

## Werkzeugwahl
- **CAD-Kern:** OpenSCAD (für parametrisches Design)
- **Automatisierung:** Python (für Batch-Generierung und CLI-Interface)

## Umsetzungsschritte

- [x] 1. **Analyse der Hardware-Dimensionen:** Verifizierung der exakten Maße für das 16x16 Panel (160x160mm) und das 8x32 Panel (80x320mm).
- [x] 2. **Recherche Ring-Parameter:** Bestimmung der Standardabmessungen für den 20-LED Ring als Standardvorgabe.
- [x] 3. **OpenSCAD Umgebung einrichten:** Erstellung der Basis-Datei mit globalen Variablen.
- [x] 4. **Definition des LED-Pitch:** Implementierung einer Variablen für den Mittenabstand der LEDs (z.B. 10mm).
- [x] 5. **Parameter für Wandstärke:** Festlegung der minimalen Druckbreite für die Trennwände (z.B. 0.8mm oder 1.2mm).
- [x] 6. **Definition der Diffusionshöhe:** Variable für den Abstand zwischen LED und Diffusor-Oberfläche zur Lichtmischung.
- [x] 7. **Modellierung einer Einzelzelle:** Erstellung eines Moduls für eine quadratische Kammer.
- [ ] 8. **Parametrisierung der Zellform:** Unterstützung für quadratische und kreisförmige Diffusor-Ausschnitte.
- [ ] 9. **Implementierung des Matrix-Generators:** Erstellung einer Doppelschleife zur Anordnung der Zellen in X- und Y-Richtung.
- [ ] 10. **Toleranz-Management:** Einführung eines Offsets für die Passgenauigkeit auf den Panels.
- [ ] 11. **Entwicklung der 16x16 Konfiguration:** Vordefinierter Parametersatz für das 16x16 Panel.
- [ ] 12. **Entwicklung der 8x32 Konfiguration:** Vordefinierter Parametersatz für das 8x32 Panel.
- [ ] 13. **Mathematik für den Ring-Diffusor:** Berechnung der Positionen basierend auf dem Radius und dem Winkel (360/20 Grad).
- [ ] 14. **Implementierung des Ring-Moduls:** Polare Anordnung der Diffusor-Kammern für den 20-LED Ring.
- [ ] 15. **Hohlraum-Design:** Optimierung der Kammern zur Reduzierung von Lichtlecks zwischen benachbarten LEDs.
- [ ] 16. **Boden-Integration:** Optionale dünne Diffusionsschicht am oberen Ende der Kammern (0.4mm - 0.8mm).
- [ ] 17. **Kabelaussparungen:** Automatisierte Erstellung von Ausschnitten für die Stromeinspeisung und Datenleitungen.
- [ ] 18. **Montage-Elemente:** Design von seitlichen Laschen oder Schnappverschlüssen zur Befestigung am Panel.
- [ ] 19. **Stabilitätsrahmen:** Integration eines verstärkten Außenrahmens für große Matrizen (Verzugsprävention).
- [ ] 20. **Modularitäts-Option:** Aufteilung großer Matrizen in druckbare Segmente (z.B. 4x 8x8 für 16x16).
- [x] 21. **Python-Wrapper erstellen:** Entwicklung eines Skripts zur Steuerung von OpenSCAD via Kommandozeile.
- [x] 22. **Automatisierter STL-Export:** Skriptgesteuerter Export für alle Zielgrößen (16x16, 8x32, Ring).
- [ ] 23. **Vorschau-Generierung:** Automatisches Rendern von PNG-Vorschaubildern zur visuellen Kontrolle.
- [ ] 24. **Konfigurationsdatei (JSON):** Speicherung der Panel-Parameter in einer externen JSON-Datei für einfache Erweiterbarkeit.
- [ ] 25. **Fehlerbehandlung im Skript:** Validierung der Parameter vor dem Aufruf von OpenSCAD.
- [ ] 26. **Optimierung der Wandgeometrie:** Implementierung von Schrägen (Draft Angles) für besseren Lichtaustritt.
- [x] 27. **Batch-Processing:** Möglichkeit, alle Varianten mit einem einzigen Befehl zu generieren.
- [ ] 28. **Slicer-Test (Virtuell):** Prüfung der STL-Dateien auf Druckbarkeit und Manifold-Status.
- [ ] 29. **Dokumentation der Parameter:** Erstellung einer Tabelle mit allen einstellbaren Werten in einer README.
- [ ] 30. **Abschluss und Review:** Finale Kontrolle der Roadmap-Ergebnisse gegen die Projektziele in GEMINI.md.
