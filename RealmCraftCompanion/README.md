**Project family:** [macOS Companion · main project](https://github.com/friedensbringer-peacemaker/RealmCraft-Companion) · [Android / Quest · APK](https://github.com/friedensbringer-peacemaker/RealmCraft-Companion-Android) · [Website · try the demo](https://friedensbringer-peacemaker.github.io/RealmCraft-Companion/)

---

## Build guides · 1.4.1

Bauanleitungen / Build guides contains twelve offline, bilingual test builds grouped by topic. Graph-paper plans show coordinates, block directions and selectable layers/sections. Click cells for placement details; materials, operation, tests and sources follow below. Local test notes persist per build. Game functionality remains unverified until tested in RealmCraft VR.

Data: `Resources/BuildGuides.json`; views: `Sources/BuildGuidesView.swift`; validated model: `Sources/BuildGuideModels.swift`.

## UI update · 1.3.1

Persistent sidebar navigation replaces the horizontal tabs and home shortcut cards. The overview shows real saved worlds. Each tool has one primary action and an action menu. Settings in the sidebar includes Quest setup, skin and language. Cmd+1 through Cmd+6 switches sections. Library data, verification and restore protection remain unchanged.

The header stays fixed across all six sections. The Appearance menu switches between Block world and Classic and contains the language selector; the setting persists across launches. Links & Knowledge includes the existing sourced comparison and community links. Search and section controls stay visible while scrolling.

# RealmCraft Companion

Community translations: [central language catalog, import/export and contribution guide](Resources/Translations/README.md). The translation workspace includes DE/EN source text and accepts reviewed contributions for additional languages; app-wide locale activation is a separate implementation step.

Crafting / Rezepte (1.7.40 development candidate) adds offline search across all 1,206 name-catalog entries, with 821 Minecraft Java 1.16.5 comparison recipes for 588 outputs. Ingredients, quantities, yield, station, one-batch grids, recipe variants, ingredient navigation and whole-batch calculations are available in German and English. Unmapped recipes remain open; no RealmCraft/Quest compatibility is claimed. Field-scoped RealmCraft wiki evidence is shown separately. See [Crafting sources and validation](Resources/CRAFTING-SOURCES.md).

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
- `build.sh`: Universal Binary und ein frisches App-Bundle unter `$TMPDIR/realmcraft-companion-build-…/`. Ein bestehendes, verlinktes oder direkt unter `/Applications` liegendes Ziel wird verweigert; Installation bleibt ein separater, geprüfter Schritt.

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

Current architecture and planning documentation: `docs/FEATURE-MAP.md`, `docs/ARCHITECTURE.md`, `docs/DATA-MODEL.md`, `docs/IDEAS-2026-09-07.md` and `docs/AUDIT-2026-09-07.md`.

## World maps (Atlas preview)
Maps are a separate feature, generated locally from verified backups. Python 3.10+, NumPy 2.x and Pillow 10.4–12.x are required. The Install map tools button in Maps and Setup downloads a private Python 3.12 runtime from Astral/python-build-standalone (SHA-256 verified) and binary NumPy/Pillow packages from PyPI. No preinstalled Python, Homebrew, Xcode or administrator password is needed. Existing working environments remain usable; failed installations preserve the previous runtime. Maps use schematic block colors and only show saved chunks. Read the bilingual in-app map guide. The frozen renderer source is in Resources/MapEngine; personal worlds and generated maps are excluded from distribution.

## Chest explorer and places
Read-only chest content search supports English/German names, numeric IDs, quantities, coordinates and JSON export. The map highlights saved chests, beds, glass, crafting tables and furnaces. Building suggestions are explicitly heuristic. Cycle through places and save custom names. The bilingual in-app guides explain scope and limits.

Additional checks: `python3 -m unittest discover -s Tests -p 'test_*.py'`. The source and distribution exclude game binaries and personal data.

Kartenrotation: Kompass anklicken (45°), mit Umschalt rückwärts. Rechtsklick auf den Kompass oder R auf der Karte richtet nach Norden aus. Option/Alt + Scrollen dreht frei; Q/E drehen in Schritten.

## Player information

Player / Spieler reads the last saved player_data directly from the selected Quest world or a verified library backup. Native Swift parsing needs no Python. Displays level, 36-slot inventory, equipped armor, bilingual item search, source/read time and JSON export. Two device copies must match. No game files are changed or game processes stopped. Unknown formats fail visibly; durability, enchantments, health and hunger remain undecoded.

Parser checks: compile Sources/PlayerModels.swift and Sources/DurabilityCatalog.swift with Tests/PlayerTests.swift, then run the resulting executable. Synthetic fixtures cover equipped items, empty inventories, duplicate/out-of-range slots, zero quantities and every truncation of a valid fixture. Optional local player_data paths enable private regressions without packaging saves.

## 1.5.0: enchantments and consolidated release

Enchantment names and stored levels are parsed natively for inventory and equipped armor, shown in both languages, searchable and exported as JSON. Unknown IDs remain visible. All player analysis works without Codex or OpenAI and supports other worlds using the validated format. See Resources/PLAYER-FORMAT.md for compatibility and evidence. Includes all latest map orientation/mirroring, cached viewer, chest map and offline build-guide improvements, alongside the faster player reader and persistent player view.

## 1.6.0: local conversation

Conversation / Gespräch supports typed and spoken questions with local Mac speech input/output. On macOS 26, SpeechAnalyzer/SpeechTranscriber manages language assets (first use may download from Apple). Older Macs use SFSpeechRecognizer only when supportsOnDeviceRecognition is true and requiresOnDeviceRecognition is enabled; unsupported configurations retain text input. No cloud recognition fallback. Apple Foundation Models optionally interprets natural questions using a constrained action/target schema, with runtime availability shown in the view. Answers and quantities come from local records; no GPT/Claude subscription or API key. Model failure falls back visibly to basic lookup. Stop/Escape cancels audio and pending answer; changing world/language clears conversation context.

Use the Mac's selected microphone and audio output. The Quest microphone is not automatically connected. Start Microphone (Cmd+Shift+M in this view), pause to submit, or choose Answer now. Conversation mode resumes listening after the reply. No microphone permission is requested before starting. Conversation transcripts stay in memory.

Name map markers in Maps, then ask for that name. Saved labels are scoped to the selected world. The verified player_data file also exposes saved respawn coordinates for the supported format. Respawn dimension, live navigation and whether the point is still usable are unavailable. See Resources/CONVERSATION-FORMAT.md.

My chests reads the selected backup's chest index and lets the user explicitly mark ownership, retained per world/coordinate. NPC containers are excluded by leaving them unchecked; ownership is never inferred from buildings. Inventory questions total only readable marked chests, list each location, and always state game-save date, backup date and uncertainty. Missing/unreadable marked chests and scan errors produce a partial result, never a false complete total. Player inventory is not included. The index must match the selected save ID.

Ten sourced Minecraft crafting references include bed and chest, with materials, grid instructions, source links and an explicit unverified-in-RealmCraft-VR label. Existing offline build guides are accessible by title. Followups use the current topic. Unknown recipes fail explicitly. The local model does not expand the recipe catalog or invent facts.

Validation: compile Sources/ChestModels.swift, Sources/BuildGuideModels.swift, Sources/ConversationKnowledge.swift and Tests/ConversationTests.swift, then pass Resources (and optionally a private player_data regression file). Synthetic tests cover world changes, followups, NPC exclusion, partial inventory, dates, recipe lookup, signed spawn coordinates and truncation rejection. Never package personal saves or ownership data.

### Qwen3.5-4B über LM Studio

Im Gespräch kann zwischen Qwen3.5-4B, Apple Intelligence und einfacher Suche gewählt werden. Qwen verwendet ausschließlich `http://127.0.0.1:1234/v1`, ohne Cloud-Schlüssel. LM Studio separat installieren, `lmstudio-community/Qwen3.5-4B-MLX-4bit` herunterladen (ca. 3,1 GB), laden und im Developer-Bereich den Server auf Port 1234 starten. Netzwerkfreigabe ausgeschaltet lassen. 4096 Tokens Kontext reichen für den Einstieg; insgesamt 5–8 GB freien Plattenplatz und vorzugsweise 16 GB RAM einplanen.

Unter Gespräch → Einrichten stehen die Schritte und Downloadlinks; Verbindung prüfen erkennt den Qwen3.5-4B-Modellnamen. Der Server muss während der Verwendung laufen. Die Prüfung bestätigt Erreichbarkeit und Modellauflistung, die erste Frage prüft die tatsächliche Inferenz. Die API-Modellkennung garantiert keine Quantisierungsstufe: Beim Download explizit die verlinkte 4-Bit-MLX-Version wählen.

Das Modell liefert eine strukturierte Absicht, keine erfundenen Savegame-Zahlen. Der Companion berechnet Bestände aus den markierten eigenen Kisten und gibt Rezepte aus seinem belegten Katalog aus. Fehler oder fehlendes Modell werden sichtbar gemeldet, anschließend greift die einfache Suche. Internet wird für Installation und Modelldownload benötigt, nicht für die lokale Inferenz.

## 1.6.1: item durability

Player equipment and inventory now show saved remaining durability, verified reference maxima, a condition bar and a low-state marker at 20% or less. Unknown or incompatible maxima never produce a percentage. JSON export includes the values. Runs natively offline for compatible player files.

## AI export / KI-Export

Dedicated sidebar section plus a link from Conversation. Select a backup, optionally scan all chests, generate the context and save Markdown or JSON. Both formats use one captured snapshot, with full inventory/chest records, names in DE/EN (JSON), level, durability, enchantments, respawn, user-named places, saved chunk bounds and separate inventory/armor/owned-storage totals. The preview alone is shortened; export records are not truncated. Files are generated locally and uploaded manually by the user.

A fresh scan reads the selected backup, with full SHA-256 manifest verification before and after reading. Chest scan failures and unsupported player data remain explicit partial sections. Current ownership/place annotations are captured at generation time and labeled as user annotations, not historical save facts. Unmarked chests have unknown ownership and do not count as owned resources. Missing/unreadable marked chests make totals partial. Health, hunger, player position, world seed, terrain resource deposits and live mobs remain unsupported. Output cannot overwrite files inside the managed library. No context-size compatibility guarantee is made for external models.

Validation: compile Sources/{Library,PlayerStorage,PlayerModels,DurabilityCatalog,ChestModels,EnchantmentNames,BuildGuideModels,ConversationKnowledge,AIContextExport}.swift with Tests/AIContextExportTests.swift and run. Tests cover independent totals, NPC exclusion, unknown vs empty, unreadable and missing chests, signed bounds, escaped labels, deterministic JSON and 1,500 untruncated chest records. Optional private regression: test executable LIBRARY RESOURCES OUTPUT_DIRECTORY; set REALMCRAFT_TEST_PYTHON to scan chests. Personal exports are not distributed.


### Materialcheck und Sprachprüfung (1.7.0, Beta)

Unter Gespräch → Mehr → Eigene Kisten den gewählten Spielstand einlesen, eigene Container markieren und optional benennen. Beispiele: „Kann ich ein Bett craften?“, „Was fehlt mir dafür?“, „Wo liegen die Materialien?“. Verglichen wird genau eine Ausführung eines gebündelten Minecraft-Referenzrezepts. Das ist keine Bestätigung des RealmCraft-Rezepts. Nur direkte Zutaten in ausdrücklich markierten, lesbaren Kisten werden berücksichtigt; Zwischenprodukte, Werkstationen und Spielerinventar fehlen im Vergleich. Bei unvollständigen Scans wird von nicht gefundenen Mengen gesprochen. Wolle verschiedener Farben wird für ein Bett nicht addiert. Holzvarianten im direkten Abgleich sind konservativ auf die klassischen sechs Brettarten beschränkt.

Gesprächseinstellungen: „Erkannten Text vor dem Senden prüfen“ legt das Transkript ins editierbare Eingabefeld. Erst Senden fragt den Companion. „Nach einer Sprechpause automatisch senden“ lässt sich für längere Fragen deaktivieren; Abschluss dann über Jetzt antworten. Automatik: 2,5 Sekunden Pause; Aufnahmegrenze 45 Sekunden, manuell 120 Sekunden ohne automatisches Absenden. Deutsch/Englisch und der richtige Mac-Eingang bleiben entscheidend.

Für weitere Qualitätsverbesserungen werden im Spiel verifizierte Rezeptmengen und Beispiele falsch erkannter gesprochener Sätze mit gewünschtem Text benötigt. Apples moderner SpeechTranscriber verwendet aktuell keinen speziell trainierten RealmCraft-Wortschatz. Eine spätere Alternative wäre DictationTranscriber mit Apples Custom-Vocabulary-Schnittstelle oder ein vergleichend getesteter lokaler Whisper-Decoder; ein größeres Antwortmodell allein repariert fehlendes oder falsch erkanntes Audio nicht zuverlässig.

## Chest ownership on the map · 1.6.5

Use Select ownership area / Besitzbereich ziehen above the map, drag between two corners, review the chest count, then mark as owned or remove ownership marks. Selection is an inclusive X/Z rectangle across Y 0–255 in the current dimension, unaffected by visible POI categories, rotation or mirroring. Escape or Close exits selection mode. Green rings show owned chests. Only recorded chests in this map are selected; new chests need a new selection, and partial map coverage/read errors can leave missing containers.

The native bridge applies validated add/remove deltas to the existing conversation.ownedChests.<world> store, preserving all marks outside the selection. Conversation and freshly generated AI exports share these marks. Standalone browser maps cannot write Companion ownership. Native acknowledgement updates the visible ownership state; a failed/missing acknowledgement is shown explicitly.

Checks: node --test Tests/{ownership,orientation,rotation,points}.test.cjs; compile Sources/ChestOwnership.swift with Tests/ChestOwnershipTests.swift. Covers dimension isolation, both Y limits, negative/inclusive bounds, mirrored/rotated drag, no pan during selection, cancellation, explicit confirmation, native acknowledgements, invalid batch rejection and large selections.


## Optional item graphics packs

Settings → Item icons offers Text only or Icons + text and a graphics-pack selector. Kenney Voxel Pack covers 49 current catalog entries (CC0, 1.3 MB download). Pixel Perfection Legacy 26.2-88.0-1 covers 686 (CC BY-SA 4.0 / CC BY 4.0 notices, 36.5 MB download). Creator, source and license links are visible before download. Download & use installs a pinned, verified pack; Use this pack switches an existing installation. Both packs can remain installed independently. Removing the active pack returns to text; removing another pack preserves the active display. Missing mappings remain text. Pack files are not bundled with the app or community source. See Resources/ITEM-ICONS.md for attribution and mapping limits.

### iCloud Drive and AirDrop (1.7.4)

After generating an AI context, “Send to iPhone” offers two Markdown handoffs:
- Choose a folder inside iCloud Drive. The Companion remembers its bookmark on this Mac. “Save to iCloud” writes a new dated file; existing exports remain intact. macOS performs synchronization. On iPhone, open Files → iCloud Drive and attach the document in your AI app.
- “Send via AirDrop” opens the native recipient chooser. Select your iPhone and accept the file. Temporary attachments are retained through the sharing operation and removed after its completion or failure.

Neither action automatically starts a chat. JSON and ordinary Markdown Save As remain available. No cloud upload is performed until you save into the chosen iCloud folder; AirDrop requires recipient selection. The Companion uses ordinary folder bookmarks because it is a non-sandboxed macOS application.

Validation: compile Sources/AIExportSharing.swift and Tests/AIExportSharingTests.swift with AppKit; run the result. Tests cover a large Unicode snapshot, separate exports, unsafe world names, protection of the save library including symlink aliases, and folder bookmark resolution.

## Chest visibility and spoiler-light exploration
Settings → Exploration & spoilers enables an optional global display policy. Player Chests are explicitly owned; Other / Random Chests means not marked owned, not proven world-generated. The chest view also supports per-world manual hiding, explicit known/discovered marks, and visible/all/hidden filters. Marks carry across backups of that world using dimension and coordinates. Replaced chests at the same coordinates inherit those marks.

The optional dungeon hint requires readable Overworld chests at Y ≤ 50 with rail + redstone + torch or golden apple. It is a conservative heuristic inspired by the example, not a validated generator or discovery detector. Owned and manually shown chests are exempt from this heuristic; explicit hiding takes precedence.

Spoiler-light mode admits only owned/known chests, including in item searches, location anchors and counts. The native map applies the same chest marks and uses surface elevation only: underground layers, block inspection, automatic place hints and ownership-area selection are disabled. User map markers remain. Generated landscape is still shown: no supported decoder currently provides reliable visited/seen history, so this is not fog of war. Unknown ores are not exposed by block types or underground views; known ore locations can be retained as manual markers. Raw JSON, map data and AI exports are outside this display policy.

Validation: ChestVisibilityTests.swift covers heuristics, manual overrides, persistence and world isolation. `node --test Tests/{privacy,points,ownership,orientation,rotation}.test.cjs` covers map admission, live policy changes, layer and keyboard restrictions, and existing navigation/ownership behavior.

## Transport networks
Build guides now includes a bilingual Transport networks category with four original test plans: a footpath junction, stairs, a rail test track and a ladder connection. Material counts and plan dimensions are validated. In-game behaviour remains explicitly untested.

Maps offers independently selectable path-block, stairs, rails and ladder overlays plus Show all / Hide all. Colors follow the selected surface or Y slice, dimension, rotation and mirroring. Tunnels require the relevant height slice; this is block highlighting, not route finding or a connectivity guarantee. Decorative stairs also match. Arbitrary paved roads, bridges and waterways cannot be reliably inferred. Spoiler-light mode suppresses all transport overlays. Cached maps refresh their viewer assets on reopen without rebuilding the world data.

Checks: `node --test Tests/*.test.cjs` (27 passing); compile BuildGuideModels.swift + BuildGuideTests.swift, then pass Resources/BuildGuides.json to the executable (19 validated guides). Production guide views rendered in DE/EN; synthetic map checked in the browser with all layers, rail-only deselection and rotation. Universal macOS build: `RealmCraft Companion Transportnetze.app` in the workspace root.

## Unified instruction book
All 19 guides now provide a shopping checklist ordered by first use, a copy action, and a step navigator with paired top/side drawings. Checklist marks persist per guide on this Mac. Each stage explicitly stores its two labeled layers/sections and the cells introduced at that stage; earlier cells are faded. The written instructions remain authoritative for test procedures and attachments outside a section. Preliminary hopper/composter tests have their own drawings; simulated growth and fluid movement remain expected behavior, not inventory requirements. Original full plans and layer controls are available in a disclosure section.

BuildCatalog.validate checks stage coverage, orientations, highlight bounds and first-use references in addition to all original grid checks. BuildGuideTests includes cumulative path construction, lamp wiring, the separate hopper test and water removal. These checks validate the instructions as data; they do not verify RealmCraft gameplay mechanics.

The chest screen uses one compact search/category row, a filter popover with active-filter count and summary, and a single Manage menu for ownership/discovery/visibility. Scan diagnostics are in the information popover; scan errors and active spoiler mode remain visible.

## Chest material shortcuts
Seven compact text buttons select diamonds, gold, iron, wood, cobblestone, coal and redstone without replacing the free-text query. Multiple selections support any resource (default) or every resource within the same chest, never pooled across adjacent chests. The text query is an additional chest constraint. Resource groups use explicit catalog IDs, include the documented raw/ore/block variants, and exclude equipment. Plain cobblestone excludes stairs, slabs and walls. Hover descriptions document each group. Existing ownership, visibility, dimension and spoiler filters remain in force; matching resource rows are highlighted. Selection can be cleared independently of the other filters.

Validation: compile ChestModels.swift with Tests/ChestMaterialTests.swift and run against Resources/ItemNames.json. Covers per-chest any/all semantics, variants, wood, equipment exclusion, unreadable records and valid catalog IDs.


## Savegame Editor · BETA / PREVIEW

Der Bereich **Editor · Beta / Preview** erstellt für jede Aktion einen neuen Bibliotheks-Spielstand. Er unterstützt das Einsetzen/Duplizieren vorhandener Gegenstände in freie Truhenslots, Umlagern zwischen Truhen, Mengenänderungen, Sortieren nach Gegenstands-ID und Erhöhen des Spielerlevels. Einsetzen nutzt einen vorhandenen gespeicherten Gegenstand als Vorlage; freie Erzeugung beliebiger Katalog-IDs ist nicht enthalten. Sortieren verdichtet Slots ab 1 und führt Stapel nicht zusammen.

**Warnung:** Der Editor kann das Savegame unwiderruflich beschädigen und die Spielerfahrung negativ beeinträchtigen. Die Oberfläche zeigt dies dauerhaft und vor dem Erstellen einer Kopie. Nutzung auf eigene Gefahr. Struktur- und Prüfsummenprüfungen garantieren keine Spielkompatibilität.

Spielstand wählen, für Truhenaktionen „Kisten einlesen“, Aktion und Slots auswählen, Vorschau prüfen und Risiko bestätigen. Neue Kopien tragen „Editor BETA“ im Namen. Die Übertragung auf die Quest erfolgt anschließend über die bestehende Wiederherstellung unter Savegames. Originale werden nicht geändert. Unbekannte oder mehrdeutige Container werden abgewiesen; Zielslots müssen leer sein. Item-Zusatzdaten werden bytegetreu übernommen. Die Leveländerung schreibt nur das erkannte Level-Feld; weitere Erfahrungswerte werden nicht angepasst.

Prüfungen: `Tests/test_editor.py`, `Tests/test_chests.py`, `Tests/SaveEditorTests.swift`. Synthetische Daten prüfen Slotänderungen, Datenbewahrung, Ablehnung belegter Slots, Originalerhalt und gültige Manifeste. Ein In-Game-Roundtrip ist noch nicht bestätigt.


### Separate Testwelt auf der Quest

„Separate Testwelt vorbereiten …“ prüft die Quest bei beendetem Spiel und erstellt eine Bibliotheks-Kopie mit eigener Welt-ID und Namen „BETA TEST …“. Bei erkanntem `world_data` v9 werden Welt-ID und UTF-8-Name ersetzt; Der Speicherzeitstempel (.NET UTC ticks bei Suffix+8) wird aktualisiert; Seed und übrige Bytes bleiben unverändert. Das Format wurde anhand mehrerer Entwicklungsproben verglichen; die tatsächliche Listenposition ist noch nicht durch einen Exporttest bestätigt. Der Dialog zeigt Quelle, Quest, neue ID und vorhandene Weltordner. **Die maximale Anzahl von Quest-Welten/Slots ist nicht verifiziert.** Mehrere Welten werden laut Nutzer vom Spiel unterstützt. Die Zahl vorhandener Ordner beweist keine maximale Kapazität. Der Dialog bestätigt ausdrücklich das Hinzufügen einer weiteren Welt und die Risiken.

Erst „Testwelt jetzt übertragen“ schreibt auf die Quest. Quelle und bestehende Welten werden per SHA-256 geprüft. Der neue Exportpfad verwendet ausschließlich die Aktivierung ohne Überschreiben (`mv -T -n`); unbekannte Unterstützung, geänderte Weltliste, laufendes Spiel oder belegtes Ziel brechen ab. Fehlgeschlagene Übertragungen können eine Staging-Kopie außerhalb des Weltverzeichnisses hinterlassen. Es werden keine Quest-Welten automatisch gelöscht. Das Anzeigen und Laden der neuen Welt im Spiel ist weiterhin unbestätigt.

`Tests/SaveEditorTests.swift` prüft zusätzlich ID-/Namens-Roundtrip, unveränderten Seed, neue Prüfsummen sowie mit `Tests/fake_editor_adb.py` die Übertragung, belegte Ziele, Kollisionen während der Aktivierung und Ablehnung bei laufendem Spiel. Dieser Test verwendet ausschließlich ein temporäres lokales Dateisystem, keine echte Quest.

## Sign layer in Maps

Map layers → Signs independently toggles saved sign markers. The Signs sidebar searches inscriptions or coordinates, navigates previous/next, and displays the original multiline text with X/Y/Z. Clicking stacked signs cycles the records at that location. All heights are included, also underground; spoiler-light mode suppresses the layer and its details. Empty inscriptions and unavailable text are distinguished. Existing maps must be generated again to include sign data; refreshed viewers explain this instead of claiming no signs exist.

The read-only v9 decoder validates sign blocks, coordinates, record lengths, UTF-8 and the observed footer. Oak sign records (162, including wall blocks 172) are confirmed against eight real signs. Other wood families retain block-derived locations with text unavailable until their record formats are verified. Sources are never modified. The cache version includes sign extraction; map audit.json records unreadable sign records.

Checks: Python test_signs.py covers multiline Unicode, empty/missing records, every record truncation, invalid lengths/UTF-8, duplicates, dimension isolation, cache reuse and source hashes. Node signs.test.cjs covers search, navigation, plain-text rendering, stacked markers, transformed selection, legacy maps and live privacy changes. No personal save data is packaged.


### Expanded AI context (schema 2)

Exports capture the selected backup plus current annotations in its annotation scope. World name and seed require the validated observed world_data v9 layout. The export includes free markers (unknown Y), chest names and groups, visibility flags, repair forecasts, and recipe material assessments using the same owned-storage logic as Conversation. Reference catalogs include full step-by-step grids, evidence and source links. Build checklists and test notes are global user annotations, not world observations. No cached terrain scan or live mob census is implied. Local paths, AI provider configuration and unrelated preferences are not exported.

Compile AIContextExportTests with AIContextSupplement, MobModels and RepairForecast as well as the existing export test sources. Run from the project workspace so the tests can load RealmCraftCompanion/Resources. Tests cover scope isolation, format/identity validation, complete catalogs, label escaping and repair arithmetic.

## Statistics (Beta), 1.7.8

Your world → Statistics reads the selected local backup's world_data after checking its manifest checksum. The v9 reader locates the combined build/dig Int64 using the variable world-name and screenshot-hash lengths, validates the world identity, and rejects unsupported/truncated data. Both TryBuild and FinishDig increment the same game counter. Its coverage for special tools and other versions remains Beta; the UI does not call it blocks mined or estimate missing lifetime metrics. Import/create a new backup to include later gameplay. Changing the backup clears the result.

Validation: StatisticsTests.swift covers variable names/hash lengths, zero and large counters, malformed input, unknown versions and identity mismatch. StatisticsStorageTests.swift covers checksum tampering, missing manifest entries and symlinks. PlayerStorageTests.swift protects the shared verified-read path. No Quest writes or runtime binary-analysis dependencies.


### Grafischer Editor

„Gegenstände“ zeigt einen Rucksack mit 36 Slots und Kisten mit 27 Slots. Gegenstand anklicken, Duplizieren/Verschieben/Menge wählen und bei Transfers den freien Zielslot anklicken. Die Zielansicht ersetzt das Quellraster, damit die Oberfläche kompakt bleibt. Installierte Gegenstandsgrafiken werden verwendet; ohne Grafikpaket erscheinen Namenskürzel und Mengen mit vollständigem Namen im Tooltip. Kisten lassen sich nach Gegenständen oder Koordinaten filtern. Rucksack und Kisten können gegenseitig als Quelle und Ziel dienen. Rüstung wird nicht als bearbeitbarer Behälter angeboten.

„Spielerlevel“ ist ein eigener Reiter. Die Risiko-Bestätigung erscheint mit der konkreten Änderung erst bei „Änderung prüfen …“. Eine kurze Warnung und BETA/PREVIEW bleiben sichtbar. „Quest-Test“ ist im Kopfbereich als separates Menü verfügbar. Jede Änderung wird weiterhin in einer neuen lokalen Sicherung gespeichert.

Zusätzliche Tests: `Tests/test_editor_inventory.py` prüft die Slots 1–36, Erweiterung der player_data-Länge, Erhalt von Rüstung und Nachfolgedaten, Zusatzdaten, belegte Ziele und Transfers zwischen Rucksack und Kiste. Eine temporäre Kopie echter Inventardaten wurde dupliziert und anschließend auch vom Swift-PlayerReader erfolgreich gelesen. Kein Savegame auf der Quest wurde dafür verändert.

## Spielstände nach Welt und Löschen

Die Bibliothek gruppiert lokale Sicherungen nach Welt-ID und zeigt den lesbaren Weltnamen aus unterstützten world_data-Dateien. Innerhalb jeder Welt steht der neueste Stand zuerst. Unterschiedliche IDs bleiben auch bei gleichem Namen getrennt.

Löschen ist über das Papierkorb-Symbol, das Aktionsmenü und das Kontextmenü möglich. Jede Aktion erfordert eine Bestätigung mit Spielstand, Welt, Datum und Größe. Nur die bestätigte lokale Sicherung wird in den macOS-Papierkorb verschoben; Quest-Welten und andere Sicherungen bleiben erhalten. Änderungen an Metadaten oder Bibliothek seit der Bestätigung sowie verknüpfte Einträge werden abgewiesen. Es gibt keinen permanenten Lösch-Fallback.

Regression: `Tests/SavegameOrganizationTests.swift` mit `Sources/Library.swift` und `Sources/SavegameOrganization.swift` kompilieren. Der Test nutzt ausschließlich temporäre Dateien und einen simulierten Papierkorb.

### Portal pairs

The Portal pairs area reads the selected snapshot’s Overworld and Nether POI files and groups adjacent portal blocks. Coordinates identify a bottom portal block; bounds describe the saved active area. Named, directional connections and observation notes are stored separately in local library metadata. Connections are reported observations, not destination links decoded from the save. Changed POI data invalidates the stored associations. In Maps, enable the portal layer, select a point and choose “Plan portal here”. Preview and save the counterpart in Portal pairs using an explicitly assumed 8:1 scale in either direction. Exact coordinates and rounded block suggestions are displayed separately; target height, buildability and actual exit remain unknown. Plans are saved per snapshot in separate local library metadata. Browser-only plans remain local to that browser. Verified linking and cross-dimension routes remain planned.
