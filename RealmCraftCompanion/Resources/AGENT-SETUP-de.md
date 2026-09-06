# RealmCraft Companion · Agent-Hilfe

## Auftrag
Hilf mir auf Deutsch Schritt für Schritt, RealmCraft Companion auf meinem Mac einzurichten. Finde zuerst heraus, an welchem Schritt ich festhänge. Erkläre jeweils eine konkrete Aktion und welches Ergebnis ich sehen sollte. Nutze die beigefügte Anleitung unten.

## Mein aktueller Stand (freiwillig ausfüllen)
- macOS-Version:
- Quest-Modell:
- App-Version und sichtbare Fehlermeldung:
- Letzter erfolgreich abgeschlossener Schritt:

## Vorgehen für den Agenten
- Prüfe deine tatsächlich verfügbaren Werkzeuge. Ohne lokalen Zugriff führe mich durch die App; behaupte nicht, etwas auf meinem Mac oder im Headset ausgeführt zu haben.
- Verwende vorhandene App-Funktionen und offizielle Meta-/Google-Anleitungen. Bei geänderten Menüs prüfe die aktuelle Dokumentation statt Schritte zu erfinden.
- Kontoanmeldung, Kontoprüfung, Lizenzzustimmung und Freigabe von USB-Debugging erledige ich selbst. Frage niemals nach Passwörtern, Einmalcodes oder Zahlungsdaten.
- Die Aufgabe ist zunächst Einrichtung und Diagnose. Überschreibe oder lösche keine Welt. Starte keine Wiederherstellung, Deinstallation, Zurücksetzung oder Bereinigung ohne meinen konkreten Auftrag. Force-stop speichert nicht: vorher meinen gespeicherten Fortschritt klären.
- Nutze für Diagnose zunächst nur lesende Befehle. ADB-Pfad und Zielgerät müssen aus der App bzw. Geräteauflistung stammen; niemals eine Geräte-ID raten. Bei mehreren Geräten verwende für gerätespezifische Befehle -s mit der von mir ausgewählten ID.
- Lade keine Savegames, vollständigen Protokolle oder persönlichen Pfade zu einem Dienst hoch. Bitte bei Bedarf nur um den relevanten Fehlertext und erkläre, welche Angaben ich vorher schwärzen kann.
- Umgehe weder Android-Zugriffsbeschränkungen noch macOS-Sicherheitsprüfungen. Kein Root, kein globales Abschalten von Gatekeeper.
- Zum Abschluss bestätige nur überprüfte Ergebnisse und trenne offene Punkte davon. Ein sinnvoller Einrichtungserfolg ist: ADB erkannt, ausgewählte Quest autorisiert, RealmCraft und Welt erkannt. Eine erste Sicherung erfolgt nur auf meinen Auftrag.

## Optionale lesende Diagnose
Die App zeigt den ADB-Pfad in Einrichtung. Verwende den exakten Pfad als einzelnes ausführbares Argument (Shell-Pfade sicher quoten):
- adb version
- adb devices -l
- adb -s AUSGEWAEHLTE_ID shell pm list packages
- adb -s AUSGEWAEHLTE_ID shell pidof com.TellurionMobile.RealmCraft

Bei pidof kann Exitcode 1 ohne Ausgabe bedeuten, dass das Spiel nicht läuft; eine Verbindung muss zuvor bestätigt sein. Die erkannte Paket-ID kann abweichen. Die App ist für Backups und Restore zuständig; ihre Prüfungen nicht durch manuelles adb push umgehen.

## Grenzen
Diese Datei startet keinen Agenten und gewährt keinen Zugriff. Sie enthält statische Hilfetexte, keine persönlichen Diagnosen oder Spielstände. Der Agent benötigt von mir bereitgestellte Informationen oder separat eingerichtete lokale Werkzeuge.

## Einrichtung

ASSISTENT BEIM ERSTEN START

Beim ersten Start öffnet Companion automatisch eine Anleitung mit acht Schritten. Sie trennt Aktionen am Mac, Smartphone und in der Brille. Mit Weiter und Zurück gehst du in deinem Tempo vor. Später schließt sie und merkt sich deinen Schritt; öffne sie über Einstellungen → Quest einrichten erneut. Alle Einstellungen öffnet die vollständige Konfiguration. Der Abschluss zeigt, was tatsächlich erkannt wurde; er startet kein Backup und keine Wiederherstellung.

Diese Anleitung wurde am Beispiel der Meta Quest integriert. Menüs, Freigaben, Kontovoraussetzungen und Speicherorte können bei anderen Brillen oder Softwareversionen abweichen. Die Kompatibilität mit anderen Brillen ist nicht garantiert. Folge bei Abweichungen den aktuellen Anweisungen des Herstellers.

EINRICHTUNG SCHRITT FÜR SCHRITT

Du brauchst einen Mac mit macOS 14 oder neuer, deine eingerichtete Quest, ein USB-Datenkabel und dein Smartphone mit der Meta-Horizon-App. Internet brauchst du für Meta-Konto und ADB-Download. Die eigentlichen Sicherungen bleiben lokal.

1 · APP AUF DEM MAC ÖFFNEN

Entpacke das Community-ZIP. Ziehe „RealmCraft Companion.app“ nach Programme und starte diese Kopie. Beim ersten Start ist Englisch ausgewählt. Oben kannst du auf Deutsch wechseln; die App merkt sich die Sprache. Öffne Einstellungen → Quest einrichten. Die folgenden Details ergänzen die acht Schritte des Startassistenten; „Alle Einstellungen“ öffnet die ausführlichen Optionen.

Wird die App von macOS blockiert, lies die verlinkte Apple-Anleitung „Apps sicher öffnen“. Diese Community-Ausgabe ist noch nicht notarisiert. Deaktiviere nicht die Sicherheit des gesamten Macs.

2 · ADB IN DER APP EINRICHTEN

ADB ist das Verbindungswerkzeug zwischen Mac und Quest. Im Assistenten unter „Mac vorbereiten“ oder unter Alle Einstellungen → ADB verwalten sollte eine Versionsnummer erscheinen. Dann ist ADB bereits vorhanden und du kannst mit Schritt 3 fortfahren.

Fehlt ADB: Öffne die Google-Lizenzbedingungen über den Link. Lies sie und entscheide selbst, ob du zustimmst. Aktiviere erst dann das Kontrollkästchen und klicke im Assistenten „ADB installieren“ oder in den Detailoptionen „ADB von Google installieren / aktualisieren“. Warte auf die Erfolgsmeldung und klicke „Erneut prüfen“.

Alternativ unter Alle Einstellungen → ADB verwalten: „Vorhandenes ADB auswählen …“ und die Datei adb aus deinem platform-tools-Ordner wählen. Für die Quest-Verbindung brauchst du weder Android Studio noch Python oder Xcode. Karten und Kistensuche verwenden zusätzliche Werkzeuge; deren Installation per Button ist weiter unten beschrieben. Auf dem Mac ist kein Windows-ADB-Treiber erforderlich.

3 · META-KONTO VORBEREITEN

Öffne die verlinkte Meta-Geräteeinrichtung. Meta verlangt ein verifiziertes Entwicklerkonto, Teamzugehörigkeit und ein Mindestalter von 18 Jahren. Verwende dein Quest-Konto, erstelle ein Team oder tritt einem bei und schließe die Kontoprüfung selbst ab.

4 · ENTWICKLERMODUS EINSCHALTEN

Am Smartphone: Meta Horizon → Headset-Symbol → dein gekoppeltes Headset → Headset-Einstellungen → Entwicklermodus einschalten. Fehlt der Eintrag, prüfe Schritt 3 und die Verbindung zum Headset. Menübezeichnungen können sich ändern.

5 · USB-DEBUGGING ERLAUBEN

Verbinde die Quest direkt mit dem Mac und setze sie auf. Klicke am Mac „Erneut prüfen“. Bestätige im Headset „USB-Debugging zulassen“. „Von diesem Computer immer zulassen“ nur für deinen vertrauenswürdigen Mac wählen. Meta nennt außerdem Einstellungen → Entwickler → MTP-Benachrichtigung einschalten.

Debugging ist die Freigabe für ADB-Befehle von diesem Mac. Eine reine Dateiübertragungs-Abfrage ist nicht dieselbe Freigabe. Ein Ladegerät-Kabel ohne Datenleitungen genügt nicht. Kontopasswörter und Bestätigungscodes gehören ausschließlich in die Meta-Anmeldung, nicht in einen KI-Chat.

6 · VERBINDUNG PRÜFEN

In „Einrichtung“ muss ADB mit Version erscheinen. Unter „Quest & RealmCraft“ muss die App das Spiel und mindestens eine Welt erkennen. Unter Savegames → (…) → Gerät & Welt findest du Gerät, Welt-ID und „Verbindung prüfen“.

Keine Quest: Headset aufwecken, Kabel neu verbinden, anderes Datenkabel oder anderen USB-Port testen. Zunächst ohne Hub anschließen. „USB-Debugging bestätigen“: Headset aufsetzen und die Freigabe prüfen. „RealmCraft nicht installiert“: das richtige Headset wählen und das Spiel dort installieren. „Keine Welt“: im Spiel eine Welt erstellen und speichern.

Bleibt die Debugging-Abfrage aus, kontrolliere den Entwicklermodus und die aktuelle Meta-Anleitung. Beende laufende Übertragungen, bevor du Geräte oder ADB neu startest. Für eine genauere Diagnose gibt es „Hilfe mit einem Agenten“ in dieser Hilfe.

7 · ERSTE SICHERUNG ERSTELLEN

Speichere deinen Fortschritt im Spiel und beende RealmCraft vollständig. Wähle unter Savegames → (…) → Gerät & Welt die richtige Quest und Welt. Sichere jede gewünschte Welt separat. Klicke „Vom Gerät sichern“. Lasse die Verbindung bestehen und starte das Spiel erst nach „Gesichert und geprüft“ wieder. Ein neuer Eintrag mit Datum und Uhrzeit erscheint links.

Savegames → (…) → Gerät & Welt → RealmCraft auf Quest beenden beendet das Spiel ohne Speichern. Verwende diese Aktion erst nach dem Speichern im Spiel.

8 · SICHERUNG FINDEN ODER ALS ZIP SPEICHERN

Unter Savegames → (…) öffnet „Bibliotheksordner öffnen“ die gesamte Library und „Im Finder anzeigen“ den ausgewählten Weltordner. „ZIP exportieren“ sichert einen Spielstand, „Library-Backup-ZIP exportieren“ die gesamte Library. Verwahre eine zusätzliche Kopie, bevor du eine Wiederherstellung ausprobierst.

Standardordner: ~/Library/Application Support/RealmCraftLibrary/Savegames. Unter Quest einrichten → Alle Einstellungen kannst du ihn ändern. Lass „Vorhandene Spielstände … mitkopieren“ eingeschaltet, wenn die bisherigen Einträge mitkommen sollen. Die Originale bleiben erhalten.

9 · SPÄTER WIEDERHERSTELLEN

Speichere und beende das Spiel. Wähle links die gewünschte Sicherung und prüfe Datum, Welt-ID und Zielgerät. „Auf Quest wiederherstellen“ öffnet zunächst eine Bestätigung. Erst „Sichern & wiederherstellen“ startet den Vorgang. Die aktuelle Zielwelt wird vorher automatisch gesichert. Bei einem Fehler das Spiel geschlossen lassen und die Meldung lesen. Details findest du unter „Mac → Quest laden“.

QUELLEN

Meta-Geräteeinrichtung und Android-Geräteanleitung, geprüft am 5. September 2026. Die Links unten öffnen die Originalanleitungen; bei abweichenden Menüs ist die aktuelle Meta-Anleitung maßgeblich.


KARTEN UND KISTENSUCHE EINRICHTEN (OPTIONAL)

Öffne Einstellungen → Quest einrichten und im Schritt „Speicher wählen“ oder unter „Alle Einstellungen“ den Block „Karten- & Kistenwerkzeuge“. Klicke dort auf „Kartenwerkzeuge installieren“. Derselbe Button erscheint im Bereich „Karten“, wenn Werkzeuge fehlen.

Die App installiert Python, NumPy und Pillow in einem eigenen Ordner für deinen Benutzer und prüft anschließend ihre Funktion. Dafür brauchst du Internet, aber kein Administratorpasswort, Homebrew, Xcode oder vorinstalliertes Python. Der Python-Download kommt von Astral/GitHub, die Pakete von PyPI. Vorhandene Python-Installationen werden nicht verändert.

Bei einem Fehler kannst du die Installation erneut starten; eine bisherige Installation bleibt erhalten. Für normale Backups und die Spieleransicht sind diese Kartenwerkzeuge nicht nötig.
