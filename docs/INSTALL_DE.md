# PadUI installieren

1. Alle Ryzom-Clients schließen.
2. Den vorhandenen `user`-Ordner und die charakterbezogenen Interface-Einstellungen sichern. Dadurch bleiben Rückkehr und Wiederherstellung möglich.
3. Das Paket entpacken. Alle Dateien **aus dem enthaltenen `user`-Ordner** in den `user`-Ordner deiner Ryzom-Installation kopieren und gleichnamige Dateien ersetzen. Kein zusätzliches `user/user`-Verzeichnis anlegen.
4. Den Client neu starten. Für mehrere getrennte Installationen die Dateien jeweils kopieren.

Unter Windows kann der Pfad zum Beispiel `C:\Spiele\steamapps\common\Ryzom\user` sein. Bei Linux und macOS hängt der beschreibbare Client-Datenordner von der Installation ab; im Zweifel den vom Client verwendeten Ordner prüfen.

PadUI-Einstellungen sind über die Fensterübersicht erreichbar. Sprache, Akzente, Transparenz und Layouts werden zentral eingestellt. Teamgröße und kompakte Timer lassen sich dort skalieren. Die Timer bieten Countdown und Stoppuhr; ein Moduswechsel setzt den jeweiligen Timer zurück.

Die Dateien `padui_mob_catalog.lua` und `padui_mobs.lua` gehören ebenfalls direkt in `user`. Eine zusätzliche BM-JSON muss nicht installiert werden. Gelernte Bossnamen und viele Einstellungen werden pro Charakter über Ryzoms UI-Speicherung gesichert; den Client regulär beenden.

Updates: erneut alle mitgelieferten Dateien ersetzen. Ein Zurückkopieren älterer Dateien setzt gespeicherte Farben und Einstellungen nicht automatisch zurück. Zur vollständigen Wiederherstellung die eigene Sicherung verwenden.

Bei Problemen: PadUI-Version, Betriebssystem, genaue Client-Version und Schritte zur Reproduktion angeben. Private Daten aus Logs entfernen.
