# PadUI-Public: Action Dock 0.3 (2026-11-04)

**Repository:** `wdcyvk8v26-debug/PadUI-Public`. **Branch:** `feature/action-dock-prototype-20261104`. Main is untouched.

## Änderungen nach dem ersten Ingame-Screenshot

Der erste Ingame-Test zeigte **überlagerte Leisten** und **kaum erkennbare Unterschiede** zwischen den Presets. Diese Version behebt die Ursachen im experimentellen Code:

- **Verankerung statt Bildschirmkoordinaten:** `gestionsets2:setParentPos(gestionsets)` und `setPosRef("TL BL"/"BL TL")` verankern den kompletten Zusatzleisten-Container an der Hauptleiste. Für Barpositionen mit wenig Platz nach oben wird die Zusatzleiste **unterhalb** angebracht. Das verhindert die frühere Vermischung von absoluten `x_real/y_real`- und lokalen `x/y`-Werten.
- **Explizite Layout-Updates:** `updateCoords()` nach Ändern von Containergrößen, Slotabständen und der Verankerung, damit die nativen Ryzom-Controls die neue Position übernehmen.
- **Deutlich anderer Platzbedarf:** Kompakt = **28 px**, Weit = **36 px** Rasterabstand. Originale Skill-Icons bleiben unverändert groß (natives `CDBCtrlSheet`).
- **Drei eigenständige Farbthemen:** **Gold**, **Türkis/Aether**, **Kupfer/Ember**. Jedes färbt das Glas, die Oberkante, Slotrahmen, Waffenrahmen und Beschriftung. Zusätzlich gibt es drei spürbare Deckkraftstufen: 96, 77 und 42 %.
- **160 zusätzliche 1-px-Randsegmente** um die 40 nativen Slots, farbabhängig; zwei Statusanzeigen zeigen beispielsweise `GOLD / 28` und die Zusatzleiste hat einen erkennbaren eigenen Randbereich.
- Die originalen Fähigkeiten, Aktionen, Page-Selectors, 2 Waffenplätze, Drag-and-drop und Cooldowns werden weiterhin von Ryzom selbst gesteuert, **nicht** in Lua nachgebaut.
- Um das getrennte Layout bei einem Relog wiederherstellen zu können, bleibt die vorherige Position in `UI:SAVE:PADUI:ACTION_DOCK:` gespeichert.

## Bedienung

Rechtsklick auf eine der Aktionsleisten:
- `PadUI · Leisten verbinden` / `PadUI · Leisten trennen`
- `PadUI · Kompakt (28 px Raster)` / `PadUI · Weit (36 px Raster)`
- `PadUI · Design: Gold` / `Design: Tuerkis` / `Design: Kupfer`
- `PadUI · Deckkraft: 96 %` / `77 %` / `42 %`

Dock ist standardmäßig ausgeschaltet. Die separaten Leisten bleiben möglich.

## Dateiübersicht

Im Spielverzeichnis **keine neue Datei erforderlich**, falls `padui_action_dock.lua` bereits als Symlink angelegt wurde. Für diese Revision wurden nur **bestehende Dateien** auf dem Feature-Branch überarbeitet:

- `user/inventory.xml` — zwei Container, Menüs, Gold-/Türkis-Kanten und Statusanzeige
- `user/padui_action_dock.lua` — Verankerung, Live-Styling und getrennte Layout-Rückkehr
- `scripts/check_action_dock.py` — Regressionstests (nur für Entwickler)
- `.github/workflows/action-dock-check.yml` — experimentelle statische CI-Prüfung
- Diese Dokumentation

Der PadUI-Public-Code aus `main` außerhalb der Aktionsleisten wurde nicht durch alte PadUI-Dateien ersetzt. **Weder Git-Branch noch Symlinks müssen neu angelegt werden.**

## Nächster Ingame-Test

1. **Ryzom komplett beenden.** Dann `git -C "C:\Users\ralph\PadUI-Public" pull --ff-only` ausführen (Branch ist bereits ausgewählt).
2. Kontrollieren: `git -C "C:\Users\ralph\PadUI-Public" branch --show-current` muss `feature/action-dock-prototype-20261104` anzeigen.
3. Ryzom starten, ggf. bestehendes Dock trennen und wieder verbinden, falls ein altes Layout gespeichert wurde.
4. **Screenshot** mit beiden Leisten. Die 40 Slots müssen in **vier getrennten Reihen** erscheinen; bei knapper Höhe nach oben gehört die Zusatzleiste *unter* die Hauptleiste.
5. 28/36 px Raster nacheinander umschalten; es muss sich die Breite um 80 px verändern. Gold/Türkis/Kupfer nacheinander umschalten; Status und Rahmenfarbe müssen sichtbar wechseln.
6. Waffenplatz, Skillbelegungen, beide Seitenwähler, Drag-and-drop, Bewegen der Hauptleiste, Trennen/Wiederverbinden und Relog prüfen.
7. Mit `python scripts/check_action_dock.py` XML und Struktur prüfen; mit installierter Lua-5.1-Umgebung auch Syntax.

## Sicherheit und Limitierungen

- **Nicht im echten Spiel verifiziert:** Diese Korrektur ist ein neuer Implementierungsversuch, kein bestätigter Ingame-Fix. Keine Aussage über Crash-Freiheit.
- Nur die beiden nativen Aktionsleisten werden angefasst. Kein Kompass, keine Änderungen an globalem Mouseover oder anderem PadUI-Team-/Cast-Fensterverhalten.
- Die Original-Skill-Icons sind an fest gepackte Ryzom-Texturen gebunden. Komplett neuartige große Slot-Icons und aufwendige geschwungene Bitmap-Rahmen aus dem Browser-Mockup brauchen spätere Atlas-/Client-Arbeiten. Die jetzige Variante bleibt daher eine XML-/Lua-Annäherung.
- **Rollback:** Erst im Spiel `PadUI · Leisten trennen` wählen. Dann Git-Branch zurückwechseln, Ryzom neu starten. Vor Änderungen am Live-Client Backup der individuellen Fensterpositionen anlegen.
