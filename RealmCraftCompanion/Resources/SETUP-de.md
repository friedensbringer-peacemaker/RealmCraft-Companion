ASSISTENT BEIM ERSTEN START

Beim ersten Start öffnet Companion automatisch eine schrittweise Anleitung. Sie trennt Aktionen am Mac, Smartphone und in der Brille. Mit Weiter und Zurück gehst du in deinem Tempo vor. Später schließt sie und merkt sich deinen Schritt; öffne sie über Einstellungen → Gerät einrichten erneut. Alle Einstellungen öffnet die vollständige Konfiguration. Der Abschluss zeigt, was tatsächlich erkannt wurde; er startet kein Backup und keine Wiederherstellung.

Diese Anleitung wurde am Beispiel der Meta Quest integriert. Menüs, Freigaben, Kontovoraussetzungen und Speicherorte können bei anderen Brillen oder Softwareversionen abweichen. Die Kompatibilität mit anderen Brillen ist nicht garantiert. Folge bei Abweichungen den aktuellen Anweisungen des Herstellers.

WAS DU WOFÜR BRAUCHST

Rezepte, Materialpläne, Bauanleitungen und die Hilfe lassen sich ohne angeschlossene Quest nachschlagen. Die lokalen Rezeptdaten sind Vergleichsdaten, keine vollständig bestätigten RealmCraft-Rezepte. Gegenstands-Icons sind optional; ohne installiertes Paket bleiben Namen und Mengen sichtbar.

ADB wird für die direkte Quest-Verbindung benötigt. Karten, Kistensuche und Erzanalysen benötigen die optionalen Kartenwerkzeuge. Tectonicus hat eine eigene experimentelle Einrichtung. Lokales Vorlesen im Bau-Coach verwendet die macOS-Sprachausgabe; die Konversation hat eine separate Einrichtung für Sprache und Modelle.

DAUER UND HINTERGRUNDAUFGABEN

Sicherung und Karten hängen von Datenmenge, Dateianzahl, Kabel, freiem Speicher und Cache ab. Warte auf den bestätigten Abschluss statt mit festen Minutenwerten zu planen. Folge-Sicherungen können geprüfte unveränderte Dateien wiederverwenden, prüfen aber weiterhin den vollständigen Stand.

Atlas bereitet zunächst eine unabhängig geprüfte Arbeitskopie vor. Während der anschließenden Hintergrundberechnung kannst du andere Bereiche verwenden. Fortschritt, Abbrechen und später „Karte öffnen“ bleiben in der App erreichbar. Optionale Systemhinweise werden erst nach deiner Aktivierung und macOS-Freigabe verwendet. Tectonicus ist ein eigener Ablauf und nutzt diese Atlas-Hinweise nicht.

„Alle gespeicherten Chunks“ bedeutet die bereits gespeicherte Abdeckung, nicht die gesamte theoretisch erzeugbare Welt. Eine vorhandene Karte zu öffnen startet keine Neuberechnung. Ausgelagerte Cloud-Dateien müssen gegebenenfalls zuerst geladen werden.

EINRICHTUNG SCHRITT FÜR SCHRITT

Du brauchst einen Mac mit macOS 14 oder neuer, deine eingerichtete Quest, ein USB-Datenkabel und dein Smartphone mit der Meta-Horizon-App. Internet brauchst du für Meta-Konto und ADB-Download. Die eigentlichen Sicherungen bleiben lokal.

1 · APP AUF DEM MAC ÖFFNEN

Entpacke das Community-ZIP. Ziehe „RealmCraft Companion.app“ nach Programme und starte diese Kopie. Beim ersten Start ist Englisch ausgewählt. Im Einrichtungsfenster oder unter Einstellungen → Language kannst du auf Deutsch wechseln; die App merkt sich die Sprache. Öffne Einstellungen → Gerät einrichten. Die folgenden Details ergänzen den Startassistenten; „Alle Einstellungen“ öffnet die ausführlichen Optionen.

Wird die App von macOS blockiert, lies die verlinkte Apple-Anleitung „Apps sicher öffnen“. Diese Community-Ausgabe ist noch nicht notarisiert. Deaktiviere nicht die Sicherheit des gesamten Macs.

2 · ADB IN DER APP EINRICHTEN

ADB ist das Verbindungswerkzeug zwischen Mac und Quest. Im Assistenten unter „Mac vorbereiten“ oder unter Alle Einstellungen → ADB verwalten sollte eine Versionsnummer erscheinen. Dann ist ADB bereits vorhanden und du kannst mit Schritt 3 fortfahren.

Fehlt ADB: Öffne die Google-Lizenzbedingungen über den Link. Lies sie und entscheide selbst, ob du zustimmst. Aktiviere erst dann das Kontrollkästchen und klicke im Assistenten „ADB installieren“ oder in den Detailoptionen „ADB von Google installieren / aktualisieren“. Warte auf die Erfolgsmeldung und klicke „Erneut prüfen“.

Alternativ unter Alle Einstellungen → ADB verwalten: „Vorhandenes ADB auswählen …“ und die Datei adb aus deinem platform-tools-Ordner wählen. Für die Quest-Verbindung brauchst du weder Android Studio noch Python oder Xcode. Karten und Kistensuche verwenden zusätzliche Werkzeuge; deren Installation per Button ist weiter unten beschrieben. Auf dem Mac ist kein Windows-ADB-Treiber erforderlich.

3 · META-KONTO VORBEREITEN

Öffne die verlinkte Meta-Geräteeinrichtung. Folge dort den aktuellen Voraussetzungen für Entwicklerkonto, Team und Kontoprüfung. Verwende dein Quest-Konto und erledige die erforderlichen Bestätigungen selbst; Herstellerbedingungen können sich ändern.

4 · ENTWICKLERMODUS EINSCHALTEN

Am Smartphone: Meta Horizon → Headset-Symbol → dein gekoppeltes Headset → Headset-Einstellungen → Entwicklermodus einschalten. Fehlt der Eintrag, prüfe Schritt 3 und die Verbindung zum Headset. Menübezeichnungen können sich ändern.

5 · USB-DEBUGGING ERLAUBEN

Verbinde die Quest direkt mit dem Mac und setze sie auf. Klicke am Mac „Erneut prüfen“. Bestätige im Headset „USB-Debugging zulassen“. „Von diesem Computer immer zulassen“ nur für deinen vertrauenswürdigen Mac wählen. Falls deine Quest-Version Einstellungen → Entwickler → MTP-Benachrichtigung anbietet, beachte dazu die aktuelle Meta-Anleitung.

Debugging ist die Freigabe für ADB-Befehle von diesem Mac. Eine reine Dateiübertragungs-Abfrage ist nicht dieselbe Freigabe. Ein Ladegerät-Kabel ohne Datenleitungen genügt nicht. Kontopasswörter und Bestätigungscodes gehören ausschließlich in die Meta-Anmeldung, nicht in einen KI-Chat.

6 · VERBINDUNG PRÜFEN

In „Einrichtung“ muss ADB mit Version erscheinen. Unter „Quest & RealmCraft“ muss die App das Spiel und mindestens eine Welt erkennen. Unter Welten & Sicherungen → (…) → Gerät & Welt findest du Gerät, Welt-ID und „Verbindung prüfen“.

Keine Quest: Headset aufwecken, Kabel neu verbinden, anderes Datenkabel oder anderen USB-Port testen. Zunächst ohne Hub anschließen. „USB-Debugging bestätigen“: Headset aufsetzen und die Freigabe prüfen. „RealmCraft nicht installiert“: das richtige Headset wählen und das Spiel dort installieren. „Keine Welt“: im Spiel eine Welt erstellen und speichern.

Bleibt die Debugging-Abfrage aus, kontrolliere den Entwicklermodus und die aktuelle Meta-Anleitung. Beende laufende Übertragungen, bevor du Geräte oder ADB neu startest. Für eine genauere Diagnose gibt es „Hilfe mit einem Agenten“ in dieser Hilfe.

7 · ERSTE SICHERUNG ERSTELLEN

Speichere deinen Fortschritt im Spiel und beende RealmCraft vollständig. Wähle unter Welten & Sicherungen → (…) → Gerät & Welt die richtige Quest und Welt. Sichere jede gewünschte Welt separat. Klicke „Vom Gerät sichern“. Lasse die Verbindung bestehen und starte das Spiel erst nach „Gesichert und geprüft“ wieder. Ein neuer Eintrag mit Datum und Uhrzeit erscheint links.

Welten & Sicherungen → (…) → Gerät & Welt → RealmCraft auf Quest beenden beendet das Spiel ohne Speichern. Verwende diese Aktion erst nach dem Speichern im Spiel.

8 · SICHERUNG FINDEN ODER ALS ZIP SPEICHERN

Unter Welten & Sicherungen → (…) öffnet „Bibliotheksordner öffnen“ die gesamte Library und „Im Finder anzeigen“ den ausgewählten Weltordner. „ZIP exportieren“ sichert einen Spielstand, „Library-Backup-ZIP exportieren“ die gesamte Library. Verwahre eine zusätzliche Kopie, bevor du eine Wiederherstellung ausprobierst.

Standardordner: ~/Library/Application Support/RealmCraftLibrary/Savegames. Unter Gerät einrichten → Alle Einstellungen kannst du ihn ändern. Lass „Vorhandene Spielstände … mitkopieren“ eingeschaltet, wenn die bisherigen Einträge mitkommen sollen. Die Originale bleiben erhalten.

9 · SPÄTER WIEDERHERSTELLEN

Speichere und beende das Spiel. Wähle links die gewünschte Sicherung und prüfe Datum, Welt-ID und Zielgerät. „Auf Quest wiederherstellen“ öffnet zunächst eine Bestätigung. Erst „Sichern & wiederherstellen“ startet den Vorgang. Die aktuelle Zielwelt wird vorher automatisch gesichert. Bei einem Fehler das Spiel geschlossen lassen und die Meldung lesen. Details findest du unter „Mac → Quest laden“.

QUELLEN

Meta-Geräteeinrichtung, Android-Geräteanleitung und Apple-Sicherheitshinweise. Die Links unten öffnen die Originalanleitungen; bei abweichenden Menüs ist die aktuelle Meta-Anleitung maßgeblich.


KARTEN UND KISTENSUCHE EINRICHTEN (OPTIONAL)

Öffne Einstellungen → Gerät einrichten und im Schritt „Speicher wählen“ oder unter „Alle Einstellungen“ den Block „Karten- & Kistenwerkzeuge“. Klicke dort auf „Kartenwerkzeuge installieren“. Derselbe Button erscheint im Bereich „Karten“, wenn Werkzeuge fehlen.

Die App installiert die benötigten Kartenwerkzeuge mit Python, NumPy und Pillow in einem eigenen Ordner für deinen Benutzer und prüft anschließend ihre Funktion. Dafür brauchst du Internet, aber kein Administratorpasswort, Homebrew, Xcode oder vorinstalliertes Python. Der Python-Download kommt von Astral/GitHub, die Pakete von PyPI. Vorhandene Python-Installationen werden nicht verändert.

Bei einem Fehler kannst du die Installation erneut starten; eine bisherige Installation bleibt erhalten. Für normale Backups und die Spieleransicht sind diese Kartenwerkzeuge nicht nötig.


TRANSFER OHNE ADB · UNGETESTETE ALTERNATIVEN

Öffne Einstellungen → Gerät einrichten → Alternative: ohne ADB übertragen. Dort gibt es einen Empfangsordner-Button, eine Auswahl für eingebundene Quest-Ordner, Pfadkopie, lokalen Import und ZIP-Export. Ein reines MTP-Gerät hat keinen normalen Finder-Pfad. ADB bleibt der empfohlene, getestete Weg mit SHA-256-Prüfung. Für Richtigkeit, Vollständigkeit, Kompatibilität und Erfolg externer Apps wird keine Gewähr übernommen; Nutzung auf eigenes Risiko. Andere Brillen können abweichen.

OHNE HEADSET STARTEN

Wähle im Assistenten Später. Auf Start öffnet Offline nutzen die Rezepte; die Schnellsuche oben findet Rezepte, Bauanleitungen, Videos und Hilfe. Sicherung importieren öffnet Welten & Sicherungen; dort startet Sicherung importieren … die Dateiauswahl. Quest einrichten führt zurück zur Einrichtung. Es wird dabei kein Backup automatisch gestartet.
