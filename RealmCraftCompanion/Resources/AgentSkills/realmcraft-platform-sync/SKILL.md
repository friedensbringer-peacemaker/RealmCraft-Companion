---
name: realmcraft-platform-sync
description: Gleiche UI, UX, Funktionen und Inhalte von RealmCraft Companion für macOS, Android/Quest und GitHub Pages ab und aktualisiere beauftragte Abweichungen mit macOS als führender Referenz.
---
# RealmCraft-Plattformabgleich

Die macOS-Companion-Variante ist derzeit die führende Referenz für Produktverhalten, Funktionsumfang, Inhalte und Gestaltung. Android/Quest und die gehostete GitHub-Web-Version orientieren sich daran. Eine spätere ausdrückliche Nutzerentscheidung kann diese Priorität ändern. Übertrage Bedienabsichten und Ergebnisse in passende Plattformkonventionen; identische Pixel oder ungeprüft übernommene Desktop-Funktionen sind kein Ziel.

## Auftrag und Ausgangsstand

- Bei einem Prüfauftrag liefere den Abgleich. Bei einem Aktualisierungsauftrag behebe die beauftragten Abweichungen einschließlich betroffener Navigation, Hilfe und Tests. Die bloße Verwendung dieses Skills autorisiert keine Veröffentlichung, Geräteinstallation oder wiederkehrende Überwachung. Bereits erteilte Autorisierung bleibt gültig.
- Lies die geltenden AGENTS.md im ausgewählten Workspace und den betroffenen Projekten. Suche gezielt nach `RealmCraftCompanion`, `RealmCraftCompanionAndroid`, `RealmCraftWebDemo`, Buildskripten und Deployment-Workflows. Dies sind Orientierungspunkte, keine fest vorgeschriebenen Pfade. Erfasse unabhängige laufende Änderungen, bevor du Dateien bearbeitest.
- Erfasse je Plattform Quellstand/Commit, App-Version, Build-Artefakt und gegebenenfalls installierten/veröffentlichten Stand. Ermittle die echte Hosting-URL aus Projektkonfiguration oder Repository-Metadaten. Prüfe sie beim beauftragten Live-Abgleich; leite den veröffentlichten Zustand nicht aus lokalen Dateien ab. Fehlender Geräte-, APK- oder Live-Zugriff bleibt ausdrücklich ungeprüft.
- Prüfe README-Aussagen gegen Implementierung und Tests. Android ist zum Ausgangsstand ein eigenständiger Prototyp, die Web-Ausgabe eine statische Demo ausgewählter Funktionen. Diese Einordnung muss bei jedem Abgleich erneut überprüft werden.

## Abgleich

Baue eine kompakte Matrix: Bereich/Funktion | macOS-Referenz mit Beleg | Android | Web | Abweichung/Priorität | nächste Maßnahme. Nutze eindeutige Zustände: gleichwertig, plattformgerecht angepasst, fehlt, veraltet, bewusst ausgeschlossen oder ungeprüft. Belege Beobachtungen mit Dateien, Tests oder dem tatsächlich untersuchten Artefakt. Bewusst ausgeschlossen erfordert eine dokumentierte Produktentscheidung; technische Hürden sind kein solcher Beleg.

Prüfe im beauftragten Umfang:

- Navigation, Bezeichnungen, Informationsstruktur, zentrale Arbeitsabläufe und Auffindbarkeit; Karte, Bibliothek, Spieler/Inventar, Truhen, Bauanleitungen, Rezepte, KI-Kontext und Skill-Verwaltung, soweit vorhanden.
- Gestaltung und UX: Hierarchie, Farben, Symbole, Lesbarkeit, adaptive Größen, Touch/Quest-Zeiger, Maus/Tastatur, Fokus, Barrierefreiheit sowie Lade-, Leer-, Fehler- und Bestätigungszustände. Beachte Zurück-Navigation und Fenster-/Panelgrößen.
- Funktionales Verhalten: Datenformate und Kataloge, Import/Export, Versionierung, Persistenz, Offline-Verhalten, Berechtigungen und Grenzen. Unterscheide Beispiel-/Sandbox-Aktionen, gespeicherte Kopien und echte Spielzugriffe.
- Deutsche und englische Texte, Hilfe, Einrichtung und verständliche Hinweise auf fehlende Möglichkeiten. Fehlende Übersetzungen bleiben sichtbare Abweichungen.

Priorisiere Datenverlust, irreführende Funktionsversprechen und blockierte Kernabläufe vor kosmetischen Unterschieden. Plane größere Portierungen in überprüfbare Schritte. Übernimm keine bekannten macOS-Fehler; dokumentiere den Referenzfehler und korrigiere ihn innerhalb des Auftrags.

## Aktualisieren und prüfen

- Nutze gemeinsame Kataloge, Formate und Logik, soweit die Architektur es erlaubt. Erhalte Herkunft, fachliche Einschränkungen und vorhandene Nutzeränderungen. Gleiche Ergebnisse mit denselben synthetischen Testfällen ab.
- Übersetze Desktop-Dateizugriff und ADB nicht blind in Android-Berechtigungen oder Browser-Code. Erhalte Grenzen für Import, Backups und Wiederherstellung. Eine fehlende Restore-Funktion wird nicht allein wegen macOS-Parität eingebaut.
- Lokales Qwen/LM Studio ist eine optionale Fähigkeit des jeweiligen Geräts. Browser-Localhost und Android-Localhost verweisen nicht automatisch auf den Mac. Prüfe Transport und Modellverfügbarkeit; erfinde keinen Cloud-Fallback. KI-Übersetzungen sind überprüfbare Entwürfe; bewahre Code, Platzhalter und Formate.
- Prüfe geänderte Plattformen mit ihren vorhandenen Builds und Tests: macOS gemäß Buildskript; Android gemäß Gradle-Konfiguration einschließlich relevanter Unit-/Lint-Prüfungen; Web gemäß Test- und statischem Buildablauf. Ein erfolgreicher Build belegt keine Quest-Bedienbarkeit, Live-Parität oder erfolgte Auslieferung.
- Die Erstellung und Veröffentlichung weiterer Screenshots ist derzeit pausiert. Nutze bestehende Belege, Quellprüfung und funktionale/UI-Prüfungen ohne neue Screenshot-Dateien; erst eine ausdrückliche Aufhebung erlaubt neue Screenshots.
- Pflege betroffene Hilfe zweisprachig sowie Update Log und Backlog auf Englisch mit aktuellen App-Versionen, neueste Einträge zuerst. Erhalte den sichtbaren Codex-Projekt-Credit und Codex Astra als KI-Contributor.
- Veröffentliche nur bei entsprechender Autorisierung aus dem vorgesehenen geprüften öffentlichen Checkout. Prüfe konkrete Dateien, Archive und Metadaten nach den Projektregeln. Echte Spielstände, persönliche Exporte, Gerätekennungen und private Pfade gehören nicht in Testfälle oder Paritätsberichte. Besondere Demo-Freigaben gelten nur für den ausdrücklich freigegebenen Inhalt.

## Ergebnis

Berichte Referenzstände, wichtigste Abweichungen, umgesetzte Änderungen, durchgeführte Prüfungen und offene Plattformgrenzen. Trenne lokal geändert, gebaut, auf Gerät geprüft und veröffentlicht. Verlinke bei größeren Abgleichen einen bereinigten Bericht mit Matrix und priorisierten Folgearbeiten im bestehenden Dokumentationsbereich. Behaupte vollständige Parität nur für den nachweislich geprüften Umfang.
