# Modulare Teamfenster (Entwicklungsstand)

## Bedienung

Unter **PadUI Einstellungen > Anordnung**:

- **Vertikal:** 1 bis 9 Spalten, erst nach unten, dann in die naechste Spalte.
- **Horizontal:** 1 bis 9 Zeilen, erst nach rechts, dann in die naechste Zeile.
- **Frei:** jedes Mitgliedsfenster separat platzieren. HP-Aenderungen tauschen
  die Mitglieder nicht zwischen ihren Fensterplaetzen.

Sieben Mitglieder mit zwei Spalten ergeben vier links und drei rechts;
mit zwei Zeilen vier oben und drei unten. Der Groessenregler (75 bis 150
Prozent), die Sortierung und die optionale Selbstanzeige bleiben erhalten.
Die alte untere Sortierleiste bleibt entfernt.

### Name anklicken UND daran ziehen

**Ein kurzer Linksklick auf den Namen waehlt weiterhin das Mitglied aus.**
Auch die HP-/Sap-/Ausdauerbalken und der restliche Fensterbereich bleiben
anklickbar. Rechtsklick oeffnet weiterhin das Mitglieds-Kontextmenue.

Zum Verschieben den vorhandenen Schalter auf **LOCK: Aus (ziehen)** stellen.
Die Namenszeile wird dezent hinterlegt. Dort die linke Maustaste gedrueckt
halten und bewegen. Erst ab vier UI-Pixeln Bewegung gilt die Geste als Ziehen;
ein kleiner Wackler bleibt ein Klick. Nach einem Ziehvorgang wird beim
Loslassen kein Mitglied ausgewaehlt, auch nicht beim Zurueckziehen zum Start.
Eine lange gedrueckte Taste ohne Bewegung bleibt ebenfalls ein Klick.

**LOCK: An (gesperrt)** verhindert das Verschieben, nicht die Zielwahl.
Die Ressourcenbalken sind auch bei LOCK aus keine Ziehflaeche.

In Vertikal/Horizontal bewegt sich die gesamte Anordnung, in Frei nur das
angefasste Fenster. Die beiden Positionssaetze werden getrennt gespeichert.
**Positionen zuruecksetzen** betrifft den Rasteranker und freie Fensterplaetze,
nicht Groesse, Sortierung oder Sichtbarkeit.

Positionen gelten pro Charakter und Fensterplatz. Solange ein Mitglied im
Team bleibt, bleibt seine Fensterzuordnung stabil. Nach einem frischen Login
ist die Erstzuordnung nach Namen; es gibt keine dauerhafte Positionsdatenbank
fuer jeden Mitspieler. Ein zu grosses Raster aendert die gewuenschte
Zeilen-/Spaltenzahl nicht heimlich, sondern zeigt einen Hinweis.

## Aufbau und Eingabeverarbeitung

`user/team_compact.lua` enthaelt weiterhin Controller und XML-Vorlagen.
Es gibt **keine neue Laufzeitdatei und keinen neuen Windows-Symlink**.
Neun root-level Container stehen nebeneinander unter `ui:interface`.
Es existiert kein gemeinsames klickblockierendes Rechteck um das Raster.
Der alte `team_compact`-Container ist nur noch ein inaktiver Kompatibilitaets-
schalter fuer den nativen Fenstermanager.

Der unsichtbare 1x1-Controller mit `use_cursor=false` hat den einzigen neuen
Frame-Callback. Die neun Mitgliederfenster werden einmal erzeugt und danach
wiederverwendet. Der vorhandene DB-Tick-Einstieg teilt denselben Tick-Guard.

Das transparente native `target_button` deckt jetzt die ganze Mitgliedskarte
ab, einschliesslich der Namenszeile. Es behaelt das native Mouse-Capture und
die Klick-/Kontextmenuebehandlung. Die Fenster haben keinen konkurrierenden
nativen Mover mehr (`movable=false`); der Controller setzt beim Ziehen die
Positionen selbst. Auf native Root-Koordinaten wird weiterhin mit
`nativeY = screenHeight + topOffset` umgerechnet.

Der Controller liest `getMouseDown()` fuer die urspruengliche Druckposition
und `getMousePos()` fuer die aktuelle Position. Eine Geste beginnt nur bei
einem neuen Mausklick auf dem tatsaechlich obersten Mitgliedsfenster
(`getCurrentWindowUnder()`); das Herueberziehen aus der Spielwelt oder von
einem ueberdeckenden Einstellungsfenster startet keine Bewegung.

Der Klick behaelt einen Snapshot aus UID, Name-ID und Teamindex. Bei
Mitgliedswechsel, LOCK-/Layout-/Groessenaenderung oder Viewportwechsel wird
eine laufende Geste abgebrochen. HP-Sortierung wird waehrend des Haltens
zurueckgestellt. Erst der native Mouse-up-Klickhandler darf das Mitglied
anvisieren: Ein Frame-Callback fuehrt niemals eine Zielwahl aus.

## Performance, Speicherung und bisherige Korrekturen

Ein gemeinsamer Durchlauf liest die vorhandenen lokalen Teamdaten; es gibt
keine neuen Serveranfragen. Geometrie wird nur bei Skalierungs-/Schriftwechsel,
Sortierung und Layout nur bei relevanten Aenderungen berechnet. Identische
Texte, Farben und Balkenbreiten werden nicht wiederholt geschrieben.

Beim Ziehen wird die kleine Anordnung nachgefuehrt, nicht fuer jedes Fenster
noch einmal die ganze Gruppe abgefragt. Gespeichert wird nach dem Loslassen,
nicht in jedem Frame. Ein ruhig gehaltenes Raster am Bildschirmrand loest
keine fortlaufenden Layoutberechnungen aus.

Die `UI:SAVE:PADUI:TEAM_MODULAR:*`-Properties werden vor dem Wiederherstellen
der Charakterkonfiguration deklariert. Globale Alpha-/Mouseover-Einstellungen
bleiben unangetastet. Ungebundene private Namensresolver verwenden nur den
unterstuetzten UInt32-Setter, niemals den problematischen `textid`-Getter.

Siehe [TEAM_JOIN_CRASH.md](TEAM_JOIN_CRASH.md) und
[TEAM_VISIBILITY.md](TEAM_VISIBILITY.md) fuer die frueheren Korrekturen.
Die Fenster werden nach dynamischer Erstellung weiterhin explizit geoeffnet.

## Tests und Grenzen

```sh
python3 tests/run_team_tests.py
# Optional: vorhandenen Interpreter explizit angeben
python3 tests/run_team_tests.py lua5.1
```

Der Runner erzeugt XML mit der echten Laufzeitfunktion und erstellt daraus
strikte native-interface Stand-ins. Die Tests unterscheiden aktive/geoeffnete
Fenster, BL-TL-Koordinaten, abgewiesene UInt32-Lesezugriffe sowie die
Druck-/Bewegungs-/Loslasspositionen einer Mausgeste.

Beim Namensleisten-Umbau lokal ausgefuehrt: **55 Regressionstests unter
Lua 5.3 (texlua)** plus XML- und Syntaxpruefung. Abgedeckt sind insbesondere
Klick und Ziehen auf Namen, Klick auf Balken, LOCK an/aus, kleine Wackler,
Ziehen und Zurueckziehen, sehr schnelle Klicks, verschiedene Release-Reihenfolgen,
Gruppen-/Moduswechsel, Weltklicks und ueberdeckende Fenster. Die bisherigen
Funktionen (0 bis 9 Mitglieder, Raster, Skalierung, asynchrone Namen,
Zielpruefung, Sichtbarkeit, simulierter Neustart/Charakterwechsel) sind ebenfalls
abgedeckt. 200 unveraenderte Updates schreiben keine UI-/Speicherwerte neu.

**Das sind keine Tests des echten NeL-Renderers, der OS-Mauseingabe oder einer
realen .icfg-Datei.** Kein echter Lua-5.1-Client und kein FPS-Benchmark wurden
hier ausgefuehrt. Laut Rueckmeldung funktionieren die Anzeige und der Wechsel
zwischen Vertikal und Horizontal im Client; das neue Ziehen muss dort erst
bestaetigt werden. Anschliessend auch Linux, Desktopwechsel, UI-Ausblenden,
Bildschirmwechsel, volle Gruppe und Klicks durch Rasterluecken testen.

## Testbranch unter Windows aktualisieren

Ryzom vollstaendig beenden; kein reines Lua-Reload. Alte generierte Fenster
werden anhand einer XML-Versionsmarkierung erkannt und verlangen einen Neustart.
Bei Git-Fehlern stoppen; lokale Aenderungen nicht verwerfen.

```powershell
git -C "$HOME\PadUI-Public" switch feature/modular-team-windows
git -C "$HOME\PadUI-Public" pull --ff-only
git -C "$HOME\PadUI-Public" log -1 --oneline
```

Die vorhandenen Symlinks bleiben unveraendert. Zurueck zum bisherigen Stand,
ebenfalls bei geschlossenem Client:

```powershell
git -C "$HOME\PadUI-Public" switch main
```

Danach ggf. Team unter Einstellungen > Fenster wieder einschalten und
Vertikal/Horizontal auswaehlen. Keine Backups in oder unter `Ryzom\user` ablegen.
