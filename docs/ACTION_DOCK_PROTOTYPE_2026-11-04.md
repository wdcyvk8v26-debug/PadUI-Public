# PadUI-Public – Action Dock 0.2 (04.11.2026)

**Ziel-Repository: `wdcyvk8v26-debug/PadUI-Public` (NICHT `wdcyvk8v26-debug/PadUI`).**

Nur Testbranch `feature/action-dock-prototype-20261104`, Main bleibt unverändert.

## Umfang
- 20 native Haupt-Slots (`UI:PHRASE:MEMORY`) und 20 native Zusatz-Slots (`UI:PHRASE:MEMORY_ALT`) in einem wahlweise verbundenen Dock. Die originalen unabhängigen Seitenwechsel, Waffenplätze und Controls bleiben erhalten.
- Optische Dark-Glass-/Goldrahmen und 40 ergänzende Slotrahmen. Zwei Rasterabstände und drei Glasdeckkräfte im Kontextmenü.
- Rechte Maustaste auf der Haupt- oder Zusatzleiste: **PadUI · Leisten verbinden** / **PadUI · Leisten trennen**.
- Die Zusatztaste nutzt weiterhin Ryzoms native horizontale/vertikale Verfahren.
- `UI:SAVE:PADUI:ACTION_DOCK:ENABLED` standardmäßig 0. Beim Trennen wird die zuvor gespeicherte Ausrichtung, Position und Fensteraktivierung wiederhergestellt.
- Keine Kompassleiste; keine Änderungen am Ryzom-Core4-Client, Server oder globalem Mouseover.

## Anpassung gegenüber dem veralteten PadUI-Repository
Diese Version wurde durch einen **gezielten Transfer der Actionbar-Komponenten** auf die aktuelle `PadUI-Public/main` erstellt. Die kompletten alten `inventory.xml`- und `padui_core.lua`-Dateien wurden nicht blind ersetzt. Unabhängige Public-Funktionen bleiben erhalten.

## Im Branch geändert
- `user/inventory.xml`
- `user/padui_core.lua`

Neu hinzugefügt:
- `user/padui_action_dock.lua`
- `scripts/check_action_dock.py`
- `docs/ACTION_DOCK_PROTOTYPE_2026-11-04.md` (dieses Dokument)

Nur die **neue Lua-Datei** benötigt einen zusätzlichen Datei-Symlink im Ryzom-`user`-Verzeichnis, falls vorhandene Dateien bereits einzeln als Symlinks aus dem Public-Repository eingebunden sind.

## Sicherheits- und Teststatus
- Bestehende 40 Aktion-Slots und beide Original-Waffen-Slots erhalten; Slots werden **nicht** neu angelegt oder kopiert.
- Quellen statisch überprüfbar mit `python scripts/check_action_dock.py`, falls Python lokal vorhanden.
- **Noch nicht mit dem echten Ryzom-Client ausprobiert**: XML-Ladefähigkeit, tatsächliche Anordnung, Castbar-Kopplung, Bewegungen und UI-Fokus müssen im Spiel geprüft werden.
- Die detaillierte HTML-Vorschau besitzt stärkere Effekte und simulierte Aktionen; der Native-Prototyp ist eine vereinfachte XML-/Lua-Umsetzung. Native Skill-Icons sind nicht wirklich skaliert.
- Vor dem Test Ryzom beenden und gegebenenfalls lokale Änderungen sichern. `git switch` nicht durch `--force` ersetzen.
- Beim Zurückwechseln zu `main` den neuen Symlink `padui_action_dock.lua` **nach Prüfung des Linkziels** entfernen. Andere Symlinks bleiben bestehen.

## Vorgehen mit bestehenden Datei-Symlinks
Die Repo-Ermittlung kann rückwärts über `C:\Spiele\steamapps\common\Ryzom\user\inventory.xml` oder `padui_core.lua` erfolgen. **Unbedingt das Git-Remote auf `wdcyvk8v26-debug/PadUI-Public` prüfen**, bevor ein Branch gewechselt wird. Zeigt der Symlink noch auf das alte `PadUI`, zuerst den alten Linkbestand prüfen; nicht stillschweigend Dateien überschreiben.

Nach einem erfolgreichen isolierten Ingame-Test: Screenshots, XML-Fehler, Skill-Seitenwechsel, Wechsel der Leistenorientierung und Relog prüfen, bevor in `PadUI-Public/main` gemergt wird.
