# Modulare Teamfenster (Entwicklungsstand)

## Bedienung

Unter **PadUI Einstellungen > Anordnung** stehen drei Team-Modi zur Auswahl:

- **Vertikal:** Spaltenzahl 1 bis 9. Die sortierten Mitglieder werden erst nach
  unten, dann in der naechsten Spalte angezeigt. Sieben Mitglieder in zwei
  Spalten ergeben vier links und drei rechts.
- **Horizontal:** Zeilenzahl 1 bis 9. Die sortierten Mitglieder werden erst nach
  rechts, dann in der naechsten Zeile angezeigt. Sieben Mitglieder in zwei
  Zeilen ergeben vier oben und drei unten.
- **Frei:** Jedes Mitgliedsfenster ist einzeln positionierbar. Laufende
  HP-Aenderungen tauschen die Mitglieder nicht zwischen den Fensterplaetzen.

Der vorhandene Team-Groessenregler bleibt erhalten (75 bis 150 Prozent).
Die Sortierung nach Name, HP oder fehlenden HP sowie das Einblenden des eigenen
Charakters bleiben im Reiter **Fenster**. Die alte untere Sortierleiste wird
nicht mehr angezeigt. Itemleisten- und Timer-Einstellungen bleiben erhalten.

Positionen sind anfangs gesperrt. Zum Verschieben **Positionen gesperrt**
anklicken und am schmalen linken Rand eines Mitgliedsfensters ziehen.
Der restliche Bereich bleibt fuer Zielwahl und Rechtsklickmenue reserviert.
In automatischen Modi bewegt dieser Griff das ganze Raster, in **Frei** nur
sein Fenster. **Positionen zuruecksetzen** setzt die Ankerposition und alle
neun freien Positionen zurueck, nicht Groesse oder Sortierung.

Nicht benoetigte Spalten/Zeilen werden nicht kuenstlich freigehalten. Ein zu
breites/hohes Raster aendert die gewuenschte Spalten-/Zeilenzahl nicht heimlich:
Es erscheint ein Hinweis, Groesse oder Rasterzahl anzupassen. Freie Fenster
werden fuer die aktuelle Bildschirmgroesse im sichtbaren Bereich gehalten.

Freie Positionen werden pro Charakter und Fensterplatz gespeichert. Solange
jemand im Team bleibt, bleibt die Zuordnung zu seinem Fenster stabil, auch
wenn sich sein nativer Team-Index aendert. Frei gewordene Plaetze koennen neue
Mitglieder aufnehmen. Nach einem frischen Login erfolgt die Erstzuordnung
nach Namen; dies ist keine dauerhafte Positionsdatenbank fuer jeden Mitspieler.
Ein Wechsel zu einem automatischen Modus ueberschreibt freie Positionen nicht.

## Technischer Aufbau

Die bestehende `user/team_compact.lua` enthaelt den Controller und die
XML-Vorlagen. Es gibt keine neue Laufzeitdatei und somit keine zusaetzliche
Windows-Dateiverknuepfung. Der native XML-Parser registriert die Vorlagen und
neun eigenstaendige `container` genau einmal pro UI-Lebensdauer.

`padui_team_member1` bis `padui_team_member9` sind Geschwister unter
`ui:interface`, nicht Kinder eines grossen Team-Rahmens. Ihr Inhalt verwendet
`no_bordure`; nur diese neun neuen Container erhalten lokale Rahmen-Alpha 0.
Globale Transparenz- und Mouseover-Einstellungen werden nicht veraendert.
Der freie linke Griff gehoert jeweils zur kleinen Fensterflaeche.

Ein unsichtbarer generischer Controller (`padui_team_driver`, 1 x 1,
`use_cursor=false`, keine Texturen, transparente Namen ohne Schatten) besitzt
**einen** Draw-Callback und acht native `text_id`-Quellen. Der schon vorhandene
DB-Tick-Aufruf bleibt als Einstieg erhalten; der gemeinsame Smooth-Tick-Guard
verhindert doppelte Datenscans im selben Tick. Es gibt keine Draw-Callbacks
auf den neun einzelnen Fenstern und keine fortlaufende GUI-Erzeugung.

Der alte `team_compact`-Container bleibt ausschliesslich als **inaktiver**
Kompatibilitaetsschalter fuer den nativen Fenstermanager erhalten. Ein
`on_active`-Handler schaltet die logische Team-Sichtbarkeit und deaktiviert den
alten Container sofort wieder. Die PadUI-Einstellungsfunktionen werden einmal
gezielt erweitert, statt die grosse bestehende XML-Datei zu duplizieren.
Alte Namensquellen werden fuer die vorhandene Ziel-des-Ziels-Anzeige gespiegelt.

Die `UI:SAVE:PADUI:TEAM_MODULAR:*`-Properties werden bereits beim Laden der
Lua-Datei angelegt, **vor** dem Einlesen der Charakter-Interfacekonfiguration.
Das ist notwendig: `CInterfaceConfig::streamToDataBase()` stellt nur bereits
existierende DB-Blattwerte wieder her. Dabei wird keine Spielerfunktion vor
`game.InGameDbInitialized` aufgerufen. Native Container-Geometriespeicherung
ist fuer die neuen Fenster abgeschaltet; freie Positionen und Raster-Anker
werden getrennt in `UI:SAVE` gespeichert, nicht als Dateien geschrieben.

## Aktualisierung und Sicherheit

- Ein gemeinsamer Scan liest bis zu acht Teammitglieder und optional den
  Spieler aus den vorhandenen Client-DB-Werten. Keine neuen Serveranfragen.
- Mitgliederobjekte und native Fenster werden wiederverwendet. Sortiert wird
  nur bei relevanten Aenderungen; im freien Modus nicht aufgrund von HP.
- Skalierung und Fontauswahl laufen nur bei geaenderter Geometrieeinstellung.
  Rasterpositionen werden nur bei geaendertem Layout/Anker/Reihenfolge gesetzt.
- Identische Texte, Balkenbreiten und Farben loesen keine neuen Lua-UI-Setter
  aus. Transparenzfarben und Uebersetzungen werden pro Renderdurchlauf geteilt.
- Ein ausgeblendetes Team wird nicht fortlaufend gescannt. Verborgene
  Mitgliedsfenster erhalten keine laufenden Balkenupdates.
- Beim Ziehen werden Positionen gemeinsam nachgefuehrt; gespeichert wird nach
  dem Loslassen, einschliesslich der letzten Mausposition, nicht pro Frame.
- UID, Name-ID und Anwesenheit werden vor jeder Ziel-/Menueaktion erneut
  validiert. Ein Kontextmenue speichert einen Snapshot statt eines mutierbaren
  Mitgliederobjekts. Verzoegert aufgeloeste Namen werden nicht weiterverwendet.
- Fehlt eine notwendige native API oder scheitert der Aufbau, wird ein Fehler
  protokolliert und die native Teamliste als Rueckfall angezeigt.

`RyzomTeamUI.stats` zaehlt Datenscans, Sortierungen, Layoutdurchlaeufe,
aktualisierte Eigenschaften und XML-Aufbauten, ohne laufende Logausgaben.
Diese Zaehler sind keine FPS-Messung.

## Automatische Tests

```sh
python3 tests/run_team_tests.py
# oder den Lua-Interpreter explizit angeben:
python3 tests/run_team_tests.py lua5.1
```

Python benoetigt nur seine Standardbibliothek. Der Runner erzeugt XML mit der
**tatsaechlichen** Lua-Funktion, prueft dessen Struktur und erstellt daraus die
UI-Testdaten. Die Lua-Tests verwenden strikte UI-Stand-ins: Nicht exportierte
Eigenschaften und Schreibzugriffe auf SERVER-Properties werden abgewiesen.

Lokal geprueft: XML-Struktur und **27 Regressionstests unter Lua 5.3 (texlua)**.
Die Laufzeitdatei verwendet Lua-5.1-kompatible Syntax; ein echter Lua-5.1-Client
wurde hier nicht gestartet. Abgedeckt sind alle Mitgliederzahlen 0 bis 9,
beide Rasterrichtungen und Rasterzahlen 1 bis 9, freie Zuordnung, Verschieben,
Maus-Loslassen, Reset, Skalierung, Sichtbarkeit, Namensauflosung,
Gruppenwechsel, Kontextmenues, Modulneuladen, Charakterwechsel und die
Deklaration der gespeicherten Properties vor der Konfigurationswiederherstellung.

Im unveraenderten Testzustand verursachen 200 weitere Aktualisierungen keine
weiteren Sortierungen, Layoutberechnungen, UI-Setter oder Speicher-DB-Writes.
Das ist ein Logiktest, **kein Benchmark des echten NeL-Renderers**.

## Noch im Spiel zu pruefen (vor Merge)

Windows und mindestens ein Linux-Client: volle Gruppe, alle drei Modi,
Groessenregler und Schriftoptionen, Teamwechsel/KO/Abwesenheit, Ziele und
Rechtsklickmenues. Fensterverwaltung sowie PadUI-Sichtbarkeit testen. An den
freien Rasterstellen und zwischen Fenstern muessen Weltziele erreichbar sein.

Griff verschieben, wieder sperren, zwischen allen Modi wechseln; danach den
Client komplett neu starten und mit einem zweiten Charakter pruefen. Auch
Aufloesungswechsel, native Desktopwechsel und das globale Ein-/Ausblenden der
Oberflaeche testen. Maus-Capture, Texturrahmen, tatsaechliche `.icfg`-Dateien,
Clientabstuerze und die reale Framerate sind durch Mock-Tests nicht belegt.

## Testbranch unter Windows

Ryzom vorher beenden. Vorhandene lokale Aenderungen nicht verwerfen.

```powershell
git -C "$HOME\PadUI-Public" fetch origin
git -C "$HOME\PadUI-Public" switch --track origin/feature/modular-team-windows
```

Die vorhandenen Symlinks bleiben unveraendert. Zurueck zum bisherigen Stand:

```powershell
git -C "$HOME\PadUI-Public" switch main
```

Keine Backups in oder unter `Ryzom\user` ablegen.
