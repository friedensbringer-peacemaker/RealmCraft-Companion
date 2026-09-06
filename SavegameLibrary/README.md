# RealmCraft Companion

Native SwiftUI-App für lokale RealmCraft-Sicherungen auf macOS 14+ (Apple Silicon und Intel). Oberfläche, Dialoge, Statusmeldungen und integrierte Hilfe sind zwischen Deutsch und Englisch umschaltbar und enthält auch den Ursprung aus der bereitgestellten Discord-Nachricht vom 31.08.2026.

Funktionen: ADB erkennen, prüfen und von Google installieren; Quest, RealmCraft und vollständige Welten automatisch erkennen; Savegames mit Datum, Uhrzeit und Vorschau verwalten; Backup und Wiederherstellung mit SHA-256-Prüfung; automatische Sicherung vor Wiederherstellung; Spiel nach Bestätigung per ADB beenden; ZIP-Import und -Export; Library-Speicherort wechseln und bestehende Einträge geprüft kopieren.

Benutzeranleitung: `LIESMICH-README.txt` und integrierte Hilfe. Verteilung nur über die separate App-ZIP, ohne persönliche Spielstände. ADB wird nicht mitverteilt, sondern bei Bedarf von Google heruntergeladen. Die App ist lokal ad-hoc signiert. Für öffentliche Verteilung ohne Gatekeeper-Hinweise fehlen Developer-ID-Signierung und Notarisierung.

## Entwicklung

- `Sources/Library.swift`: Prozesse, Dateiübertragung, Prüfsummen, ZIP, Wiederherstellung.
- `Sources/Setup.swift`: Erkennung, ADB-Installer, Library-Umzug.
- `Sources/main.swift`: Hauptoberfläche und CLI-Testzugänge.
- `Sources/SetupView.swift`: Einrichtung und Diagnose.
- `Sources/HelpView.swift`: vollständige zweisprachige Offline-Hilfe.
- `icon.swift`, `make_icon.py`: eigenes App-Icon; keine fremden Marken-Assets.
- `build.sh`: Universal Binary und App-Bundle unter `/private/tmp/realmcraft-distribution-build/`.

Erstellen: `./build.sh`. Erfordert Xcode Command Line Tools, Swift und Python 3 ausschließlich für den Build. Endnutzer benötigen diese Werkzeuge nicht.

## Verifikation

`python3 Tests/integration.py` testet den produktiven Swift-Transfercode gegen ein temporäres simuliertes Quest-Dateisystem. Enthalten sind laufendes Spiel, Backup-Prüfung, beschädigter Upload, Rollback bei Aktivierungsfehler, vollständiger Austausch ohne veraltete Restdateien, automatische Sicherung, ZIP-Roundtrip, unsichere ZIP-Pfade, Symlinks und nachträglich veränderte Savegames.

`Tests/SetupTests.swift` prüft Library-Migration einschließlich Erhalt der Originale und Ablehnung verschachtelter Zielordner. Optional wird mit `--download` der echte Google-Download in einem temporären Testordner geprüft, ohne die bestehenden Werkzeuge oder Einstellungen zu verändern.

Native Erkennung wurde mit der verbundenen Quest 3 geprüft. Der Wiederherstellungstest verwendet ausschließlich simulierte Welten; es wurde kein echter Quest-Spielstand überschrieben. Beide Architekturen werden kompiliert; die interaktive Prüfung erfolgt auf diesem Apple-Silicon-Mac.


Entwicklung / Development
Dieses Programm wurde vollständig mit OpenAI Codex und GPT-6 Astra entwickelt.
This program was developed entirely with OpenAI Codex and GPT-6 Astra.
Vollständiger Community-Quellcode unter MIT-Lizenz: siehe COMMUNITY.md und das Quellcode-ZIP; auch direkt über Hilfe → Entwicklung & Quellcode exportierbar.
Complete MIT-licensed community source: see COMMUNITY.md and the source ZIP, also available in Help → Development & source.


Release history and proposed work: `Resources/CHANGELOG.md` and `Resources/BACKLOG.md`, also available in offline Help.

## World maps (Atlas preview)
Maps are a separate feature, generated locally from verified backups. Python 3.10+, NumPy 2.x and Pillow 10.4–12.x are required. The app detects Python and can install the packages in an isolated environment from PyPI. Maps use schematic block colors and only show saved chunks. Read the bilingual in-app map guide. The frozen renderer source is in Resources/MapEngine; personal worlds and generated maps are excluded from distribution.

## Chest explorer and places
Read-only chest content search supports English/German names, numeric IDs, quantities, coordinates and JSON export. The map highlights saved chests, beds, glass, crafting tables and furnaces. Building suggestions are explicitly heuristic. Cycle through places and save custom names. The bilingual in-app guides explain scope and limits.

Additional checks: `python3 -m unittest discover -s Tests -p 'test_*.py'`. The source and distribution exclude game binaries and personal data.
