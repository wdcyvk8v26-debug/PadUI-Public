# PadUI-Public — Action Dock 0.4 (2026-11-04)

**Zielrepository:** `wdcyvk8v26-debug/PadUI-Public`, **nicht** das veraltete `PadUI`.
**Branch:** `feature/action-dock-prototype-20261104`. Der reguläre `main`-Branch bleibt unangetastet.

## Erste Screenshots und Entscheidungen

Die ersten beiden Ingame-Tests zeigten (1) übereinanderliegende statt zusammengeführte Leisten, (2) eine zweite Leiste oberhalb der ersten, (3) keine gekoppelte Bewegung und (4) eine gegenüber dem HTML-Mockup zu simple Optik.

**0.4 löst gezielt diese Probleme:**

- **Standard unten:** Die zweite Leiste wird unterhalb der Hauptleiste angebracht. `UI:SAVE:PADUI:ACTION_DOCK:SIDE=0` ist der Default. Es erfolgt **kein automatischer Wechsel nach oben** aufgrund der Bildschirmhöhe mehr.
- **Option oben:** über einen eigenen Menüpunkt; `SIDE=1` bleibt gespeichert.
- **Mitziehen in beide Richtungen:** `gestionsets` und `gestionsets2` erhalten je einen nativen `on_move`-Callback. Der jeweils andere Container wird um das **Differential seiner tatsächlichen Bildschirmposition** verschoben. Die vorherige alleinige `setParentPos(main)`-Verankerung hat beim Verschieben nicht funktioniert und wird daher nicht mehr als Kopplung verwendet.
- **Optisch ein Block:** kein Zwischenraum, gemeinsame Hintergrundfarbe, keine zweite ALT-/EXTRA-Titelzeile, keine doppelte glänzende Kante an der Naht, ein kompakter PadUI-Schriftzug nur auf der Hauptleiste.
- **Gold, Türkis, Kupfer** sowie 28/36 px Raster und drei Glastönungen bleiben als Varianten erhalten; die Rahmenfarben sind absichtlich ruhiger als in 0.3.
- **Reversibel:** Beim Trennen werden die zuvor gespeicherte Sichtbarkeit, ALT-Position und native horizontal/vertikal Ausrichtung restauriert.
- **Nur echte Ryzom-Aktionen:** exakt 20 ursprüngliche `ctrl_memory` und 20 `ctrl_alt_memory` Instanzen. Beide originalen Seitenauswahlen und Waffenhand-Slots bleiben unverändert funktionsfähig.
- **Kein globaler Mouseover, kein anderer Fenster-Code, kein C++-Patch, kein Kompass.**

## Rechtsklick-Menü beider Leisten

- `PadUI · Verbinden (Zusatz unten)` — Standard
- `PadUI · Verbinden (Zusatz oben)`
- `PadUI · Leisten trennen`
- `PadUI · Kompakt (28 px Raster)` / `Weit (36 px Raster)`
- `PadUI · Design: Gold` / `Tuerkis` / `Kupfer`
- `PadUI · Deckkraft: 96 %` / `77 %` / `42 %`

Die nativen Leisten können bei getrenntem Modus wie bisher frei positioniert werden.

## Dateien / Installation

Aktualisiert:
- `user/inventory.xml`: Menü für oben/unten, zusätzliche native `on_move`-Aktion der zweiten Leiste, korrigierte Bitmap-Bool-Attribute, gemeinsame Optik
- `user/padui_action_dock.lua`: 0.4 gekoppelte Bewegung, Abstand = 0, Ausrichtung, Speicherung
- `scripts/check_action_dock.py`: XML-/Kontrollstrukturprüfungen
- `.github/workflows/action-dock-check.yml`: CI-Tests
- diese Dokumentation

Neu im Repository:
- `scripts/test_action_dock.lua`: Lua 5.1 Mocks der Fenster, Test für Ziehen beider Leisten, Position oben/unten, Umstellen der Themes/Abstände und Rückbau

**Keine neuen Symlinks in Ryzom erforderlich:** `padui_action_dock.lua` ist bereits verlinkt, die anderen zwei `user`-Dateien sind schon Symlinks. Neue Test- und Dokumentdateien brauchen keine Spielverknüpfung.

### Aktualisierung unter Windows

**Ryzom vollständig beenden.** In PowerShell:

```powershell
git -C "C:\Users\ralph\PadUI-Public" pull --ff-only
git -C "C:\Users\ralph\PadUI-Public" branch --show-current
```

Branch muss `feature/action-dock-prototype-20261104` anzeigen.

Neustart Ryzom, mit **PadUI · Verbinden (Zusatz unten)** aktivieren. Die 4 Reihen sollen unmittelbar aneinander anschließen. Zum Vergleich erst nur die **Hauptleiste** bewegen, dann **die Zusatzleiste**, danach `Verbinden (Zusatz oben)` und `Leisten trennen`.

## Teststatus

- Automatischer Test: `python scripts/check_action_dock.py` prüft XML, die 40 nativen Slots, die originalen Waffen-Slots, die beiden native `on_move`-Callbacks und beide Menüpunkte.
- Lua 5.1 Verhaltenstest: `lua5.1 scripts/test_action_dock.lua` simuliert Positionen, Bewegung von Haupt- und Zusatzleiste, oben/unten, große Abstände, Designwechsel, Rückbau inklusive gespeicherter Koordinaten und Ausrichtung.
- GitHub Actions führt beides bei Commits auf dem Feature-Branch aus.

**Wichtig:** Die Testumgebung enthält *keinen tatsächlichen Ryzom-Fenster-Renderer*. Die Funktion muss im Spiel geprüft werden. Auch das Erscheinungsbild ist weiterhin eine an native XML-Kontrollen angepasste Umsetzung, **kein 1:1-Nachbau der 3D-HTML-Vorschau**. Echte 24px-Icon-Skalierung würde gesonderte Core4-Client-Arbeiten erfordern.

## Sicherheitsregeln

- Kein Merge nach `main`, bevor du die Verschiebung beider Fenster im Spiel bestätigt hast.
- Keine Änderungen an Ryzom-Kundendateien ohne deine separaten Symlinks; keine Änderungen an Team, Auras, Castbar global, Fenstertransparenz.
- Rollback: im Spiel `PadUI · Leisten trennen`; bei Problemen Game beenden, `git -C "C:\Users\ralph\PadUI-Public" switch main` und neu starten. Die neue Lua-Datei als Symlink kann dabei bestehen bleiben, wird von `main` nicht geladen; für vollständigen Rückbau kann der Symlink später getrennt entfernt werden.
