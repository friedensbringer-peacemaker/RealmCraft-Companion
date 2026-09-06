MAC → QUEST · MANUELLES WIEDERHERSTELLEN OHNE COMPANION-SCHUTZ

Die ADB-Wiederherstellung wird ausdrücklich empfohlen. Manuelles Kopieren bietet nicht die Spiel-läuft-Sperre, das automatische Vorab-Backup, die Rücksicherung bei Fehlern oder den Ende-zu-Ende-Vergleich des Companion. Es wird keine Gewähr für Richtigkeit oder Erfolg übernommen.

1. Speichere in RealmCraft und beende es vor jeder Änderung. Erstelle zuerst eine unabhängige vollständige Sicherung der aktuellen Zielwelt auf der Quest und behalte ein ZIP auf dem Mac. Kannst du kein rückspielbares Backup erstellen, fahre nicht fort.

2. Wähle unter Savegames das gewünschte Backup und nutze unten Dieses Backup als ZIP exportieren. Entpacke es am Mac. Suche den numerischen Weltordner mit world_data, player_data und Chunk-Dateien. Bearbeite keine Dateien innerhalb der Companion-Library und kopiere nicht deren UUID-Hüllordner oder Metadatenordner auf die Quest.

3. Öffne in der MTP-App oder dem Brillen-Dateimanager den unten gezeigten local-Pfad und prüfe die Ziel-Welt-ID. Wähle ausdrücklich, welche Welt ersetzt werden soll. Ein funktionierender Download von der Quest beweist nicht, dass Zurückschreiben möglich ist. Ohne Zugriff und Schreibmöglichkeit auf das vollständige Ziel nicht fortfahren.

4. Nutze das dokumentierte Verfahren der Transfer-App zum vollständigen Ordnerersatz für NUR diese Welt, bei beendetem Spiel und mit aufbewahrtem unabhängigem Backup. Mische keine alten und neuen Chunk-Dateien, überschreibe keine anderen Welten und verwirf keine Rettungskopie. Ist ein sicherer vollständiger Ersatz nicht möglich, brich ab und nutze ADB.

5. Warte auf den Abschluss und vergleiche das Ergebnis mit der Quelle, soweit das Werkzeug das unterstützt. Teste anschließend im Spiel: Laden, eine kleine Änderung machen, speichern, beenden und erneut laden. Dateien können wegen ihrer Berechtigungen lesbar sein, aber RealmCraft kann sie nicht weiterschreiben. Schlägt Speichern fehl oder fehlen Daten, nutze die veränderte Welt nicht weiter und stelle das aufbewahrte Backup über den empfohlenen ADB-Weg wieder her. Companion kann bei diesem manuellen Weg keine Rechte prüfen oder reparieren.
