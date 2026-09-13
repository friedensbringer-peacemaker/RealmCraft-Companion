TRANSFER OHNE ADB · UNGETESTETE ALTERNATIVEN

Öffne Einstellungen → Gerät einrichten → Alternative: ohne ADB übertragen. Dort gibt es einen Empfangsordner-Button, eine Auswahl für eingebundene Quest-Ordner, Pfadkopie, lokalen Import und ZIP-Export. Ein reines MTP-Gerät hat keinen normalen Finder-Pfad. ADB bleibt der empfohlene, getestete Weg mit SHA-256-Prüfung. Für Richtigkeit, Vollständigkeit, Kompatibilität und Erfolg externer Apps wird keine Gewähr übernommen; Nutzung auf eigenes Risiko. Andere Brillen können abweichen.


USB-TRANSFER MIT EINER MTP-APP · QUEST → MAC

1. Speichere deinen Fortschritt in RealmCraft und beende das Spiel normal. Halte die Quest wach und verbinde sie über ein USB-Datenkabel mit dem Mac.

2. Setze die Brille auf und erlaube die USB-Dateizugriffs-/Dateiübertragungs-Abfrage. Das ist eine andere Freigabe als USB-Debugging. Fehlt die Meldung, nutze Metas aktuelle Geräteanleitung; Menüs und Kontobeschränkungen können abweichen.

3. Installiere am Mac eine MTP-fähige App aus der offiziellen Quelle, beispielsweise OpenMTP oder MacDroid. Wähle für einen Weg ohne ADB bei MacDroid ausdrücklich MTP, nicht dessen ADB- oder Debugging-Verbindungsmodus. Prüfe aktuelle Bedingungen und Kosten beim Anbieter selbst.

4. Öffne in der App den internen Speicher der Brille. Navigiere zu Android → data → com.TellurionMobile.RealmCraft → files → local. Wird ein anderes Spielpaket erkannt, nutze den unten angezeigten Quest-Pfad. Ist der Ordner wegen Zugriffssperren unzugänglich oder leer, ist dieser Weg nicht nutzbar: Abbrechen und die empfohlene ADB-Einrichtung verwenden.

5. Prüfe ALLE numerischen Weltordner. Es kann mehrere Welten geben. Wähle bewusst, welche du kopieren willst; der erste Ordner muss nicht deine aktuelle Welt sein. Kopiere jeden gewählten vollständigen Weltordner in einen neuen lokalen Ordner mit Datum, Uhrzeit und Welt-ID im Namen. Nutze unten Empfangsordner öffnen als Ziel. Dieser Ordner ist zunächst leer; das Öffnen kopiert noch nichts von der Quest. Das Quest-Original weder verschieben noch löschen.

6. Warte auf die Abschlussmeldung der Transfer-App. Prüfe, ob world_data, player_data und die Chunk-Dateien vorhanden sind; vergleiche Dateianzahl und Größen, soweit das Werkzeug dies erlaubt. Komprimiere jeden kopierten Weltordner in Finder zu einem ZIP-Backup. Anzahl und Größe allein beweisen keine bytegenaue Übereinstimmung.

7. Nutze unten Kopierte Welt / ZIP importieren. Wähle jeweils einen numerischen Weltordner oder sein ZIP. Companion legt einen Library-Eintrag aus der lokalen Kopie an. Bewahre Originalkopie und Quest-Spielstand auf, bis du unabhängig geprüft hast, dass das Backup nutzbar ist.


DIREKT AUF DER QUEST BEGINNEN · BEDINGTER DRITTANBIETER-WEG

1. Speichere in RealmCraft und beende das Spiel. Ein normaler Dateimanager ist kein garantiertes Backup-Werkzeug. Die vorinstallierte Dateien-App der Quest zeigt Spieldaten möglicherweise überhaupt nicht an.

2. Möchtest du einen Dateimanager auf der Brille prüfen, ist der QuestFiles-Store-Link unten ein Beispiel. Prüfe aktuelle Funktionen, Preis, Berechtigungen und Brillen-Unterstützung vor einer Installation oder einem Kauf. Wir haben ihn nicht mit RealmCraft getestet. Store-Verfügbarkeit oder Dateiübertragung belegen keinen Zugriff auf Android/data.

3. Versuche im Dateimanager, den unten angezeigten RealmCraft-local-Pfad zu öffnen. Sind Android/data oder die vollständigen Weltordner nicht zugänglich, brich ab. Eine Freigabe für „alle Dateien“ garantiert diesen Zugriff nicht. Kein Root und keine Umgehung von Berechtigungen.

4. NUR wenn die App vollständige Weltordner lesen kann: Identifiziere alle Welten und kopiere jeden gewählten Ordner separat, möglichst als ZIP mit Datum, Uhrzeit und Welt-ID. Das Original bleibt auf der Quest. Teilexporte, Screenshots und eine einzelne world_data-Datei sind keine vollständigen Backups.

5. Falls die App einen Download dieser Dateien über einen lokalen Browser-Transfer-Server unterstützt, folge deren Anleitung: Mac und Quest in dein eigenes vertrauenswürdiges Netzwerk bringen, Server starten und die exakt angezeigte Adresse im Mac-Browser öffnen. Lade das Welt-ZIP in den Empfangsordner. Fehlt eine Download-/Exportfunktion, ist dieser Weg nicht verfügbar. Beende den Server danach und mache ihn nicht öffentlich erreichbar. Companion startet keinen Server und überträgt hier keine Dateien für dich.

6. Warte auf den Abschluss, bewahre das Original auf und importiere dann das lokale ZIP im Companion. Die lokalen Importprüfungen verifizieren nicht den ursprünglichen Funktransfer gegen die Quest. Fehlt ein Schritt oder ist etwas unklar, verwende ADB.


MAC → QUEST · MANUELLES WIEDERHERSTELLEN OHNE COMPANION-SCHUTZ

Die ADB-Wiederherstellung wird ausdrücklich empfohlen. Manuelles Kopieren bietet nicht die Spiel-läuft-Sperre, das automatische Vorab-Backup, die Rücksicherung bei Fehlern oder den Ende-zu-Ende-Vergleich des Companion. Es wird keine Gewähr für Richtigkeit oder Erfolg übernommen.

1. Speichere in RealmCraft und beende es vor jeder Änderung. Erstelle zuerst eine unabhängige vollständige Sicherung der aktuellen Zielwelt auf der Quest und behalte ein ZIP auf dem Mac. Kannst du kein rückspielbares Backup erstellen, fahre nicht fort.

2. Wähle unter Welten & Sicherungen das gewünschte Backup und nutze unten Dieses Backup als ZIP exportieren. Entpacke es am Mac. Suche den numerischen Weltordner mit world_data, player_data und Chunk-Dateien. Bearbeite keine Dateien innerhalb der Companion-Library und kopiere nicht deren UUID-Hüllordner oder Metadatenordner auf die Quest.

3. Öffne in der MTP-App oder dem Brillen-Dateimanager den unten gezeigten local-Pfad und prüfe die Ziel-Welt-ID. Wähle ausdrücklich, welche Welt ersetzt werden soll. Ein funktionierender Download von der Quest beweist nicht, dass Zurückschreiben möglich ist. Ohne Zugriff und Schreibmöglichkeit auf das vollständige Ziel nicht fortfahren.

4. Nutze das dokumentierte Verfahren der Transfer-App zum vollständigen Ordnerersatz für NUR diese Welt, bei beendetem Spiel und mit aufbewahrtem unabhängigem Backup. Mische keine alten und neuen Chunk-Dateien, überschreibe keine anderen Welten und verwirf keine Rettungskopie. Ist ein sicherer vollständiger Ersatz nicht möglich, brich ab und nutze ADB.

5. Warte auf den Abschluss und vergleiche das Ergebnis mit der Quelle, soweit das Werkzeug das unterstützt. Teste anschließend im Spiel: Laden, eine kleine Änderung machen, speichern, beenden und erneut laden. Dateien können wegen ihrer Berechtigungen lesbar sein, aber RealmCraft kann sie nicht weiterschreiben. Schlägt Speichern fehl oder fehlen Daten, nutze die veränderte Welt nicht weiter und stelle das aufbewahrte Backup über den empfohlenen ADB-Weg wieder her. Companion kann bei diesem manuellen Weg keine Rechte prüfen oder reparieren.

SOURCES / QUELLEN · 2026-09-06
OpenMTP: https://openmtp.ganeshrvel.com/
MacDroid (select MTP / MTP wählen): https://www.macdroid.app/
QuestFiles store listing (not a RealmCraft compatibility confirmation / keine RealmCraft-Kompatibilitätsbestätigung): https://www.meta.com/experiences/questfiles-vr-file-manager/1162974433570137/
Meta USB/device guidance: https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
