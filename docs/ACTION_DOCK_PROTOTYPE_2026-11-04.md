# PadUI-Public — Unified Action Dock 0.5 (2026-11-04)

**Branch:** `feature/unified-action-dock-20261104`  
**Basis:** `feature/action-dock-prototype-20261104` (0.4).  
**Keine Client-/C++-/Serveränderung.** Der stabile `main`-Branch bleibt unangetastet.

## 0.5.1 – Z-Order/Mausklick-Fix

**Befund aus echtem Ingame-Screenshot:** Die ALT-Skillbuttons sind vorhanden, wirken aber verdunkelt und lassen sich nicht anklicken. Ursache: Beide ursprünglichen Ryzom-Windows lagen in derselben Prioritätsstufe (NORMAL=3). Der über vier Reihen aufgezogene Mastercontainer verdeckte deshalb den unteren ALT-Bereich sowohl beim Zeichnen als auch beim Maustest.

**Änderung ausschließlich in PadUI-Public/user/inventory.xml:** `gestionsets2` hat jetzt das vorhandene Core4-Attribut `win_priority="4"` (HIGH), während `gestionsets` bei NORMAL=3 bleibt. Dadurch sollten die echten `ctrl_alt_memory`-Controls über der einzigen Master-Hintergrundfläche gerendert werden und Mausklicks empfangen. Alle 40 IDs, Seiten-DB-Werte und Hand-Slots sind unverändert.

**Einschränkung:** Die ALT-Priorität ist in dieser rein XML-basierten Testvariante auch bei getrennten Leisten HIGH. Das muss im Spiel mit anderen Fenstern geprüft werden. Es ist keine globale Fensteränderung. Wir verändern weder C++ noch `setOnDraw` noch die restliche PadUI-UI. Ein erfolgreicher statischer Test bestätigt **nicht** automatisch die tatsächliche Hit-Test-Reihenfolge im Spiel.

**Nach dem Update:** Ryzom komplett schließen, auf dem vorhandenen Unified-Branch `git pull --ff-only`, Ryzom neu starten. Bei aktivem Dock prüfen, ob ALT-Skills unten jetzt hell und anklickbar sind; ALT-Drag-and-drop und Tooltip testen. Bei Problem per Menü trennen oder auf den vorherigen `feature/action-dock-prototype-20261104`-Branch zurückgehen.

## Ziel und technische Grenze

Der Core4-Client erwartet zwei **fest verdrahtete UI-ID-Pfade** in `sphrase_manager.cpp` und `action_handler_phrase.cpp`:

- `ui:interface:gestionsets:shortcuts:s0..s19` (Hauptleiste)
- `ui:interface:gestionsets2:header_closed:shortcuts:s0..s19` (Zusatzleiste)

Die originalen Gruppen mit diesen IDs **müssen** bestehen bleiben, damit alle Fähigkeiten, Cooldowns, Tastenkürzel, Tooltips, Drag-and-drop und C++-Aktionen funktionieren.

Der reine XML/Lua-Prototyp baut deshalb **einen sichtbaren Mastercontainer** über vier Reihen. Die zweite native Gruppe bleibt als unsichtbarer/undraggbarer **Control-Overlay** aktiv. Das ist im Spiel ein einziges sichtbares Dock, auch wenn die zugrunde liegenden C++-Widgetgruppen weiterhin getrennt sind. Wir behaupten ausdrücklich **nicht**, die Client-Objekthierarchie physisch in einen einzigen Container umgebaut zu haben.

## Unified Dock 0.5

- **40 originale native Aktions-Slots**, vier Reihen mit je zehn Plätzen, ohne kopierte/Fake-Controls.
- **Ein einziger sichtbarer Hintergrund** über alle vier Reihen in `gestionsets`. Die zweite native Gruppe hat weder eigenen Hintergrund/Rahmen noch eine eigene Drag-Fläche.
- Originale Waffenplätze links/rechts und native Seitenschalter bleiben funktional.
- Fensterbewegung: das Hauptfenster ist der Drag-Master; die Zusatzgruppe wird anhand der **echten ersten Slotkoordinaten** ausgerichtet. Kein Ermitteln der relativen Position über unterschiedliche Fensterränder.
- Neue dunkle Glasfläche mit durchgehendem Metallrahmen, 4 Eckdetails, dezentem Trenner, einem Titel. Drei vorhandene Paletten: Gold (Default), Türkis, Kupfer; 28/36-px Raster und drei Deckkraftstufen.
- Weiterhin optional oben/unten, getrennt/vereinigt.

## Seitensteuerung

**Synchron (Standard, ein Schalter):**
- `UI:SAVE:PADUI:ACTION_DOCK:PAGE_SYNC=1`
- Beide originalen UI-Datenbankwerte `UI:PHRASE:SELECT_MEMORY` und `UI:PHRASE:SELECT_MEMORY_2` bekommen denselben Seitenindex (1 bis 10), ohne irgendwelche Skills umzubelegen.
- Beim Aktivieren wird die Zusatzleiste auf die aktuell gewählte Seite der Hauptleiste eingestellt.
- Beide DB-Werte sind beobachtet. Deshalb soll auch ein Seitenwechsel über vorhandene Tastenkürzel synchronisieren.
- Die zweite originale `select_memory_h`-Steuerung ist unsichtbar, die erste bleibt erhalten.

**Unabhängig (zwei Schalter):**
- `PAGE_SYNC=0`
- Beide nativen Seitenschalter sichtbar; ihre DB-Werte werden nicht gekoppelt.

Im Kontextmenü stehen `PadUI · Seiten: Synchron (1 Schalter)` und `PadUI · Seiten: Unabhaengig (2 Schalter)`. Es wird nichts serverseitig verändert. XML-`<link>`-Beobachter führen die neue Lua-Synchronisierung aus; die beiden bisherigen originalen `phrase_select_memory`-Link-Handler bleiben bestehen.

## Windows-Test mit vorhandenen Symlinks

Vorher **Ryzom vollständig schließen** und PowerShell öffnen:

```powershell
git -C "C:\Users\ralph\PadUI-Public" fetch origin
git -C "C:\Users\ralph\PadUI-Public" switch --track origin/feature/unified-action-dock-20261104
git -C "C:\Users\ralph\PadUI-Public" pull --ff-only
```

Wenn der Branch bereits lokal existiert: statt `switch --track ...` einfach `git -C "C:\Users\ralph\PadUI-Public" switch feature/unified-action-dock-20261104` ausführen.

**Keine neuen Symlinks:** `inventory.xml`, `padui_core.lua` und `padui_action_dock.lua` sind bereits verlinkt. Die neue Testlogik liegt ausschließlich in `scripts/` und wird nicht ins Ryzom-Verzeichnis eingebunden.

Danach Ryzom starten. Beide nativen Balken über Kontextmenü **`PadUI · Verbinden (Zusatz unten)`** vereinen. Bei Bedarf **`PadUI · Leisten trennen`** für sofortige Rückkehr zu eigenständigen Leisten.

### Erste Ingame-Prüfung

1. Erstes Screenshot im normalen Kompaktmodus: Sind 4 Reihen mit je 10 echten Slots ohne ALT-Hintergrund sichtbar?
2. Bewege den gesamten Block über die obere Rahmen-/Drag-Fläche. Folgen die 20 Zusatz-Slots den 20 Haupt-Slots?
3. Wähle **Synchron (1 Schalter)**. Ändere die Aktionseite mit den Pfeilen *und* mit einer vorhandenen Tastenbelegung. Beide Seitenwerte sollten gleich wechseln.
4. Wähle **Unabhängig (2 Schalter)**. Es müssen zwei Seitenwähler sichtbar werden und unabhängig schalten.
5. Prüfe original Waffen, Quicktooltips, Cooldowns und Drag-and-drop an einem Haupt- und einem ALT-Slot.
6. Prüfe `Weit (36 px)`, Theme und Transparenz.
7. `Leisten trennen` und ALT wieder vertikal drehen; Originalposition und Steuerung überprüfen.
8. Relog und Fensterposition: Bei Auffälligkeiten zurück zur separaten Variante.

## Automatische Tests und Einschränkungen

- `python3 scripts/check_action_dock.py`: XML-Syntax, 40 Original-Controls, original C++-Pfade, Menüoptionen, Page-Observer und Widget-Geometrie.
- `lua5.1 scripts/test_action_dock.lua`: Mocked Widgetpositionen, 4×10-Reihen, Master-Dragging, zwei Page-Betriebsarten, bidirektionale Seiten-DB-Synchronisierung und Rückbau.
- GitHub Actions führt beide aus.
- **Noch kein Test gegen den tatsächlichen Ryzom-Renderer und die echte UI-Ereignisreihenfolge.** Der erste Ingame-Test kann weitere Anpassungen notwendig machen, insbesondere für Z-Order, Clipping und Fensterrandpositionen.
- Die vorherige 0.4 liegt weiter auf `feature/action-dock-prototype-20261104`. `main` wurde nicht verändert.

## Rollback

Wenn das Dock Darstellungsprobleme verursacht:
1. Im Spiel `PadUI · Leisten trennen` auswählen.
2. Ryzom beenden.
3. In PowerShell: `git -C "C:\Users\ralph\PadUI-Public" switch feature/action-dock-prototype-20261104` (zur getesteten 0.4) oder `git ... switch main`.
4. Ryzom starten.

Der bereits angelegte `padui_action_dock.lua`-Symlink braucht für diese Branchwechsel weder gelöscht noch neu erstellt zu werden.

**Kein C++-/Client-Mod, kein Kompass, keine globale Mouseover-Änderung.**
