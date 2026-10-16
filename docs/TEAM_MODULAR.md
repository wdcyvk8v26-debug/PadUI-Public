# Modulare Teamfenster

## Bedienung

Unter **PadUI Einstellungen > Anordnung**:

- **Vertikal:** 1 bis 9 Spalten, erst nach unten, dann in die naechste Spalte.
- **Horizontal:** 1 bis 9 Zeilen, erst nach rechts, dann in die naechste Zeile.
- **Frei:** jedes Mitgliedsfenster separat platzieren. HP-Aenderungen tauschen
  die Mitglieder nicht zwischen ihren Fensterplaetzen.

Sieben Mitglieder mit zwei Spalten ergeben vier links und drei rechts;
mit zwei Zeilen vier oben und drei unten. Nicht benoetigte Spalten oder
Zeilen bleiben nicht kuenstlich frei. Maximal neun Fenster werden angezeigt,
einschliesslich des eigenen Charakters, sofern dessen Anzeige eingeschaltet ist.

Der Groessenregler (75 bis 150 Prozent), die Sortierung nach Name, HP oder
fehlenden HP und die optionale Selbstanzeige bleiben erhalten. Sortierung
und Selbstanzeige stehen weiterhin im Reiter **Fenster**. Die alte untere
Sortierleiste ist entfernt.

### Verschieben und LOCK

Zum Anordnen **LOCK: Aus (ziehen)** einstellen. Oben rechts erscheint ein
kleines farbiges Quadrat mit **vier nach aussen gerichteten Pfeilspitzen**.
Dort die linke Maustaste gedrueckt halten und ziehen.

In **Vertikal oder Horizontal** bewegt jeder Mitgliedsgriff die komplette
Anordnung. In **Frei** wird nur das angefasste Mitgliedsfenster verschoben.
Der Griff ist 8 x 8 UI-Pixel bei 75/100 Prozent Teamskalierung, 10 x 10 bei
125 Prozent und 12 x 12 bei 150 Prozent. PadUI verwendet keine eigene
Halteverzoegerung oder Bewegungsschwelle.

**LOCK: An (gesperrt)** blendet die Griffe aus und verhindert das Verschieben.
Die bisherige Griffflaeche ist dann ebenfalls zur Zielauswahl anklickbar.

**Name und Ressourcenbalken waehlen das Mitglied aus; sie sind keine
Ziehflaechen.** Rechtsklick ausserhalb des entsperrten Griffs oeffnet das
bisherige Mitglieds-Kontextmenue. Ziehen am Griff fuehrt keine Zielwahl aus.
Diese Bedienung ersetzt die fruehere experimentelle Namensleisten-Bewegung
und den schmalen linken Ziehrand.

### Positionen speichern und zuruecksetzen

Freie Positionen und der gemeinsame Rasteranker werden getrennt pro Charakter
gespeichert. Ein Wechsel zu Vertikal/Horizontal ueberschreibt die freie
Anordnung nicht. **Positionen zuruecksetzen** betrifft den Rasteranker und
freie Fensterplaetze, nicht Groesse, Sortierung oder Sichtbarkeit.

Positionen gelten pro Fensterplatz, nicht dauerhaft pro Mitspieler. Solange
ein Mitglied im Team bleibt, bleibt seine Fensterzuordnung stabil, auch bei
einem Wechsel des nativen Teamindex. Nach einem frischen Login erfolgt die
Erstzuordnung nach Namen; freie Plaetze koennen neue Mitglieder aufnehmen.

Ein zu grosses Raster veraendert die gewuenschte Zeilen-/Spaltenzahl nicht
heimlich. Stattdessen erscheint ein Hinweis, Groesse oder Raster anzupassen.

## Technischer Aufbau

`user/team_compact.lua` enthaelt Controller und XML-Vorlagen. Es gibt
**keine neue Laufzeitdatei und keinen neuen Windows-Symlink**. Bis zu neun
root-level Container stehen als Geschwister unter `ui:interface`, ohne
gemeinsamen Fensterkasten um das gesamte Raster. Der alte `team_compact`-
Container bleibt als inaktiver Kompatibilitaetsschalter fuer die native
Fensterverwaltung erhalten.

Ein unsichtbarer 1x1-Controller mit `use_cursor=false` besitzt den einzigen
neuen Frame-Callback. Fenster werden einmal erstellt und wiederverwendet;
der vorhandene DB-Tick-Einstieg verwendet denselben Tick-Guard.

Die Eckgriffe verwenden den nativen `CCtrlMover` mit `on_begin_move` und
`on_move`. Vier nicht ueberlappende Zielklickflaechen lassen genau den Griff
fuer den Mover frei. Die Pfeile bestehen aus kleinen Bitmap-Rechtecken mit
der vorhandenen Blank-Textur; neue Grafiken oder Schriftdateien sind unnoetig.
Globale Container-Move-, Transparenz- und Mouseover-Einstellungen bleiben
unveraendert.

In automatischen Modi werden native Positionsaenderungen mit dem gemeinsamen
Anker abgeglichen. Geaenderte Geschwisterfenster aktualisieren ihre realen
Koordinaten; der Layoutcache laesst abweichende native Positionen nicht
unbemerkt stehen. In Frei betrifft dieselbe Bewegung nur den einen Fensterplatz.
Details stehen in [TEAM_DRAG_GRIP.md](TEAM_DRAG_GRIP.md).

## Aktualisierung und Sicherheit

Ein gemeinsamer Durchlauf liest die vorhandenen lokalen Teamdaten, ohne neue
Serveranfragen. Unveraenderte Texte, Farben und Balkenbreiten werden nicht
wiederholt gesetzt. Sortierung und Layout werden nur bei relevanten
Aenderungen neu berechnet; die Geometrie folgt Groesse und Schrifteinstellung.
Ein ausgeblendetes Team wird nicht fortlaufend gescannt.

Beim Ziehen werden keine zusaetzlichen vollstaendigen Teamabfragen pro Fenster
gestartet. Positionen werden nach dem Loslassen gespeichert, nicht pro Frame.
UID, Name-ID und Anwesenheit werden vor Zielaktionen erneut validiert.
Kontextmenues behalten einen Snapshot statt eines veraenderlichen Mitglieds.

Die `UI:SAVE:PADUI:TEAM_MODULAR:*`-Properties werden vor dem Wiederherstellen
der Charakterkonfiguration deklariert. Dynamisch erzeugte Container werden
explizit geoeffnet. Gespeicherte obere Offsets werden in native BL-TL-
Koordinaten umgerechnet: `nativeY = screenHeight + topOffset`.

Private ungebundene Namensresolver verwenden den unterstuetzten UInt32-Setter,
nicht den problematischen `textid`-Getter. Die Entwicklungshinweise in
[TEAM_JOIN_CRASH.md](TEAM_JOIN_CRASH.md) und
[TEAM_VISIBILITY.md](TEAM_VISIBILITY.md) dokumentieren diese frueheren Fehler.

## Validierung

**Windows-Spieltests, Rueckmeldung vom 16.10.2026:** Der Maintainer meldete
funktionierende Fenster, Layoutwechsel, gemeinsame Bewegung bei
Vertikal/Horizontal und individuelle Bewegung in Frei. Nach der Bitte,
freie Positionen und LOCK durch einen vollstaendigen Client-Neustart sowie
den Wechsel zwischen Raster und Frei zu pruefen, bestaetigte er ebenfalls
erfolgreiches Verhalten. Der zuvor gemeldete Einladungsabsturz wurde nach
der Korrektur nicht erneut beobachtet. Das sind Nutzerbestaetigungen fuer
den getesteten Windows-Client, keine plattformuebergreifende Zertifizierung.

Fuer den Laufzeitstand `efbd326` sind **74 bestandene Regressionstests unter
Lua 5.3 (texlua)** sowie XML-/Syntaxpruefungen protokolliert. Diese pruefen
unter anderem 0 bis 9 Mitglieder, beide Rasterrichtungen, native
Bewegungsabgleiche, freie Zuordnung, LOCK, Zielwahl, Skalierung und
verzoegerte Namensaufloesung. 200 unveraenderte Updates erzeugten im Test
keine zusaetzlichen Sortierungen, Layouts, UI-/Speicherwrites oder
Text-ID-Zuweisungen. Beim anschliessenden Dokumentationsabschluss wurden
Laufzeitcode und Tests nicht geaendert; die Tests wurden dabei nicht erneut
ausgefuehrt.

```sh
python3 tests/run_team_tests.py
# Optional: vorhandenen Interpreter explizit angeben
python3 tests/run_team_tests.py lua5.1
```

Die automatisierten Tests arbeiten mit XML aus der echten Laufzeitfunktion
und partiellen nativen Stand-ins, nicht mit dem NeL-Renderer. Nicht separat
belegt sind Linux/macOS, globale UI-Skalierung, Fokus-/Desktopwechsel,
Snapping-Randfaelle, alle Vollgruppenfaelle im echten Client oder ein
FPS-Benchmark. Der Windows-Neustarttest ist kein automatisierter `.icfg`-
Integrationstest.

## Lokalen Git-Klon nach dem Merge umstellen

**Erst nachdem PR #1 auf GitHub gemergt wurde.** Ryzom vollstaendig beenden;
ein Lua-Reload ersetzt den Neustart nach geaenderten XML-Vorlagen nicht.
Befehle einzeln ausfuehren und bei Git-Fehlern stoppen. Lokale Aenderungen
nicht verwerfen.

```powershell
git -C "$HOME\PadUI-Public" switch main
git -C "$HOME\PadUI-Public" pull --ff-only
```

Die vorhandenen Symlinks bleiben unveraendert. Kuenftige Updates kommen dann
ueber `main`. Solange der PR noch offen ist, befindet sich der neue Stand
nur auf `feature/modular-team-windows`; ein Wechsel zu `main` davor laedt
wieder die alte Teamoberflaeche.

Keine Backups in oder unter `Ryzom\user` ablegen.
