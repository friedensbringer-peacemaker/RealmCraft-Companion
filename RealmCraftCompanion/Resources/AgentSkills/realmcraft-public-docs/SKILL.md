---
name: realmcraft-public-docs
description: Aktualisiere die GitHub-Wiki und versionierte Demo-Screenshot-Galerie des RealmCraft Companion aus der aktuellen App-Hilfe. Für beauftragte Dokumentations- und Screenshot-Pflege, nicht für unabhängige Funktionsentwicklung.
---
# RealmCraft: Öffentliche Dokumentation pflegen

Arbeite im gewählten Checkout nach dessen Veröffentlichungsregeln. Maßgeblich sind `RealmCraftCompanion/Resources/HelpArticles.json` und referenzierte Ressourcendokumente. Wiki-Rahmentexte und Screenshot-Nachweise stehen in `Resources/PublicDocumentation.json`. Wiki-Seiten werden daraus abgeleitet; pflege die Quellen statt einer zweiten unabhängigen Anleitung.

## Wiki aktualisieren

- Prüfe Quellversion in `build.sh`, tatsächliche App-Version und öffentliches Release getrennt. Stelle reine Quellcodefunktionen nicht als bereits herunterladbar dar. Erhalte Beta-Kennzeichnungen, Datenlücken, Bestätigungsschritte und Plattformunterschiede.
- Pflege die betroffene DE/EN-Hilfe. Synchronisiere und prüfe den zentralen Übersetzungskatalog unter Erhalt vorhandener Übersetzungen und stillgelegter Einträge. Führe Katalogprüfung und passende Tests aus.
- Starte `python3 RealmCraftCompanion/Tools/build_public_wiki.py --output <neuer-Ordner>` im Projektordner. Das Werkzeug erstellt englische Seiten mit stabilen Hilfe-IDs, Querverweisen und Quellmanifest. Prüfe Ausgabe und Bildlinks. Bestehende Ausgabeordner werden zum Erhalt älterer Kandidaten abgelehnt.
- Die Wiki hat ein separates Git-Repository (`<projekt>.wiki.git`). Fehlt es, lege zuerst Home über die angemeldete GitHub-Wiki-Oberfläche an und klone danach. Erhalte unabhängig verfasste Seiten. Übernimm nur geprüfte erzeugte Dateien, prüfe den konkreten Index und nutze öffentlichen Kontonamen und GitHub-Noreply-Adresse. Veröffentliche nur im aktuellen Nutzerauftrag.
- Zeitüberschreitungen und 5xx-Antworten beweisen weder Erfolg noch Fehlschlag. Prüfe das konkrete Objekt bzw. den Git-Verweis vor einer Wiederholung. Begrenze Wiederholungen; erzeuge keine mehrfachen Release-Entwürfe und veröffentliche keine vorläufigen Platzhalter als fertige Dokumentation.

## Screenshots aktualisieren

- Baue und prüfe eine neue App, wenn die installierte Version älter ist. Notiere Version/Build und Quellprüfsumme. Erhalte frühere Versionsgalerien.
- Verwende `Tools/prepare_ui_audit.py prepare` mit ausdrücklich freigegebenem Demo-ZIP und festgelegter SHA-256-Prüfsumme. Der Launcher prüft isolierte Foundation-Pfade für Home, Support und Cache und deaktiviert ADB. Keine Aufnahmen aus dem persönlichen Profil und keine Übernahme seiner Einstellungen, Karten, Skills, Exporte oder Bibliothek.
- Starte die isolierte App, prüfe `launch-check.json`, importiere nur die freigegebene Demo über den normalen Importablauf und kontrolliere die Bibliothek vor Aufnahmen. Nutze echte UI-Zustände und vorhandene Karten-/3D-Werkzeuge; kennzeichne synthetische Pläne und Beispielzustände ausdrücklich. Eine Referenzanleitung ist kein gebautes Demo-Gebäude, ein altes Bild keine aktuelle Aufnahme.
- Erfasse nur das App-Fenster, für die öffentliche Galerie auf Englisch. Zeige verständliche Ergebnisse statt leerer Bedienelemente. Halte fest, ob Bilder echte Demo-Ansichten, mitgeliefertes Referenzwissen oder synthetische Beispiele zeigen. Veröffentliche keine Diagnosen oder unvollständigen/persönlichen UI-Zustände.
- Prüfe jedes Bild visuell. Entferne PNG-Text/EXIF/Zeit und andere identifizierende Metadaten, ohne UI-Inhalte zu erfinden oder zu übermalen. Speichere neue Bilder unter `docs/screenshots/v<version>/`; hinterlege Prüfsummen und Beschreibungen in der Dokumentationsressource und der Freigabeliste exakter Bilder. Ersetzte Bilder benötigen erneute Prüfung.

## Integration und Abschluss

Pflege diesen zweisprachigen Skill unter `Resources/AgentSkills/realmcraft-public-docs`, damit er in den Assistenten-Anweisungen erscheint und exportierbar ist. Installiere bei Auftrag den englischen SKILL-Einstieg im Skill-Verzeichnis des Agenten. Nimm Wiki-Generator und Audit-Launcher in Quellpaket und öffentlichen Export auf.

Prüfe Links, deterministische Erzeugung, Quellprüfsummen, Katalogstand, Datenschutzregeln, Bildfreigaben und eingebettete Archive vor dem Commit. Kontrolliere die entfernte Wiki und das Hauptrepository nach Veröffentlichung getrennt. Ein Source-Push beweist keine Aktualisierung von Wiki, Bildern oder App-Download. Berichte die tatsächlich veröffentlichten und gebauten Versionen sowie offene Lücken. Führe **100% vibe-coded with OpenAI Codex** und **Codex Astra** sichtbar weiter.
