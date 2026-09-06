USB-TRANSFER MIT EINER MTP-APP · QUEST → MAC

1. Speichere deinen Fortschritt in RealmCraft und beende das Spiel normal. Halte die Quest wach und verbinde sie über ein USB-Datenkabel mit dem Mac.

2. Setze die Brille auf und erlaube die USB-Dateizugriffs-/Dateiübertragungs-Abfrage. Das ist eine andere Freigabe als USB-Debugging. Fehlt die Meldung, nutze Metas aktuelle Geräteanleitung; Menüs und Kontobeschränkungen können abweichen.

3. Installiere am Mac eine MTP-fähige App aus der offiziellen Quelle, beispielsweise OpenMTP oder MacDroid. Wähle für einen Weg ohne ADB bei MacDroid ausdrücklich MTP, nicht dessen ADB- oder Debugging-Verbindungsmodus. Prüfe aktuelle Bedingungen und Kosten beim Anbieter selbst.

4. Öffne in der App den internen Speicher der Brille. Navigiere zu Android → data → com.TellurionMobile.RealmCraft → files → local. Wird ein anderes Spielpaket erkannt, nutze den unten angezeigten Quest-Pfad. Ist der Ordner wegen Zugriffssperren unzugänglich oder leer, ist dieser Weg nicht nutzbar: Abbrechen und die empfohlene ADB-Einrichtung verwenden.

5. Prüfe ALLE numerischen Weltordner. Es kann mehrere Welten geben. Wähle bewusst, welche du kopieren willst; der erste Ordner muss nicht deine aktuelle Welt sein. Kopiere jeden gewählten vollständigen Weltordner in einen neuen lokalen Ordner mit Datum, Uhrzeit und Welt-ID im Namen. Nutze unten Empfangsordner öffnen als Ziel. Dieser Ordner ist zunächst leer; das Öffnen kopiert noch nichts von der Quest. Das Quest-Original weder verschieben noch löschen.

6. Warte auf die Abschlussmeldung der Transfer-App. Prüfe, ob world_data, player_data und die Chunk-Dateien vorhanden sind; vergleiche Dateianzahl und Größen, soweit das Werkzeug dies erlaubt. Komprimiere jeden kopierten Weltordner in Finder zu einem ZIP-Backup. Anzahl und Größe allein beweisen keine bytegenaue Übereinstimmung.

7. Nutze unten Kopierte Welt / ZIP importieren. Wähle jeweils einen numerischen Weltordner oder sein ZIP. Companion legt einen Library-Eintrag aus der lokalen Kopie an. Bewahre Originalkopie und Quest-Spielstand auf, bis du unabhängig geprüft hast, dass das Backup nutzbar ist.
