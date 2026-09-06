import SwiftUI
import AppKit
import UniformTypeIdentifiers

private struct HelpArticle: Identifiable {
    let id: String
    let icon: String
    let deTitle: String
    let enTitle: String
    let de: String
    let en: String
}
private func releaseDocument(_ name: String) -> String {
    guard let url = Bundle.main.url(forResource: name, withExtension: "md"),
          let content = try? String(contentsOf: url, encoding: .utf8) else { return "This document is unavailable in this build." }
    return content
}
private let helpArticles: [HelpArticle] = [
    .init(id: "companion", icon: "square.grid.2x2", deTitle: "Der Companion", enTitle: "The companion", de: """
RealmCraft Companion bündelt mehrere Funktionen in einer App.

START
Die Startseite führt zu allen Bereichen und zeigt den Verbindungsstatus deiner Quest.

SAVEGAMES
Die bisherige Library ist ein eigenes Feature: Welten sichern, importieren, als ZIP exportieren und wiederherstellen. Bestehende Spielstände und Einstellungen bleiben erhalten.

KARTEN
Erzeuge aus einer Sicherung eine lokale Karte und erkunde Oberfläche, Höhen und einzelne Ebenen. Details findest du unter „Weltkarten erstellen“.

KISTEN
Durchsuche gespeicherte Kisten nach Gegenständen und finde Mengen, Plätze und Koordinaten.

RESSOURCEN
Hier findest du Website, YouTube, Store-Seiten, Community und Wiki. Die Suchfunktion filtert die Links. „Quelle“ zeigt, woher der jeweilige Verweis stammt. Das allgemeine RealmCraft-Wiki ist nicht speziell für VR; Inhalte können abweichen.

HILFE
Schritt-für-Schritt-Einrichtung, Agent-Instruktionen, Quellcode, Update Log und Backlog. Das Zahnrad öffnet die Quest-/ADB-Einrichtung aus jedem Bereich.
""", en: """
RealmCraft Companion brings several features together in one app.

HOME
The home page leads to each feature and shows your Quest connection status.

SAVEGAMES
The original library is now a dedicated feature: back up, import, export ZIPs and restore worlds. Existing saves and preferences are preserved.

MAPS
Generate a local map from a backup and explore terrain, heights and individual levels. See “Create world maps” for instructions.

CHESTS
Search saved chest contents and find quantities, slots and coordinates.

RESOURCES
Find the website, YouTube, store listings, community and wiki. Search filters the links. “Source” shows where each reference came from. The general RealmCraft wiki is not VR-specific; content may differ.

HELP
Step-by-step setup, agent instructions, source code, Update Log and Backlog. The gear button opens Quest/ADB setup from every feature.
"""),
    .init(id: "maps", icon: "map", deTitle: "Weltkarten erstellen", enTitle: "Create world maps", de: """
1. Sichere deine Welt im Bereich „Savegames“ oder importiere eine vorhandene Sicherung. Für Karten brauchst du keine angeschlossene Quest.
2. Öffne „Karten“ und wähle den Spielstand anhand von Name, Datum und Uhrzeit.
3. Die App prüft Python, NumPy und Pillow. Falls Python fehlt, öffne Python.org, installiere Python 3.10 oder neuer und klicke „Erneut prüfen“. Mit „Kartenwerkzeuge einrichten“ installiert die App NumPy und Pillow von PyPI in einer eigenen Umgebung. Dafür ist Internet nötig; vorhandene Python-Pakete werden nicht verändert.
4. Starte mit „Ursprung ±128 Blöcke“. Für mehr Umgebung wähle ±512 oder „Alle gespeicherten Chunks“. Große Welten benötigen mehr Zeit und freien Speicher.
5. Klicke „Karte erzeugen“. Die Sicherung wird vor und nach der Berechnung auf Integrität geprüft. Die Karte wird separat unter Library/Application Support/RealmCraftLibrary/Maps gespeichert.
6. Ziehe die Karte zum Verschieben, scrolle zum Zoomen oder suche X-/Z-Koordinaten. Wechsle zwischen Landschaft, Höhenkarte, Oberfläche und einzelnen Y-Ebenen. Nether erscheint nur, wenn gespeicherte Daten vorhanden sind.
7. „Im Browser öffnen“ zeigt die Karte im Standardbrowser. Das Ordnersymbol zeigt index.html; teile bei Bedarf den gesamten Kartenordner, da Bilder und Kartendaten dazugehören. Für den JSON-Export markierter Orte verwende die Browseransicht.

ATLAS-VORSCHAU
Dieser Kartenbereich integriert einen eigenständigen Stand des parallelen Realmcraft-Atlas-Projekts. Er liest gespeicherte Chunks und verwendet schematische Farben. Es ist keine Live-Karte und keine exakte Nachbildung der Spielgrafik. Unbekannte Blöcke und beschädigte Chunks werden gekennzeichnet. Die zuletzt erzeugte Karte wird je Sicherung, Bereich und Sprache wieder geöffnet. Erneutes Erzeugen legt einen neuen Kartenordner an. Nicht benötigte Karten kannst du im Finder entfernen; Savegames liegen separat.
""", en: """
1. Back up your world in Savegames or import an existing backup. A connected Quest is not required for maps.
2. Open Maps and choose a savegame by name, date and time.
3. The app checks Python, NumPy and Pillow. If Python is missing, open Python.org, install Python 3.10 or newer and click Check again. Set up map tools installs NumPy and Pillow from PyPI in a separate environment. Setup requires internet; existing Python packages are not changed.
4. Start with Origin ±128 blocks. Choose ±512 or All saved chunks for a larger area. Large worlds need more time and free disk space.
5. Click Generate map. The backup is checked for integrity before and after rendering. Maps are stored separately under Library/Application Support/RealmCraftLibrary/Maps.
6. Drag to pan, scroll to zoom or search X/Z coordinates. Switch between terrain, height map, surface and individual Y levels. Nether appears only when saved data is available.
7. Open in browser uses your default browser. The folder button reveals index.html; share the complete map folder because its images and data are required. Use the browser view to export marked places as JSON.

ATLAS PREVIEW
This feature integrates an independent snapshot of the parallel Realmcraft Atlas project. It reads saved chunks and uses schematic colors. It is not a live map or an exact reproduction of game graphics. Unknown blocks and damaged chunks are identified. The last map is reopened for each savegame, area and language. Generating again creates a new map folder. Remove unneeded maps in Finder; savegames are stored separately.
"""),
    .init(id: "chests", icon: "shippingbox", deTitle: "Kisten & Gegenstandssuche", enTitle: "Chests & item search", de: """
1. Wähle im Bereich „Kisten“ einen gesicherten Spielstand.
2. Klicke „Kisten einlesen“. Falls Werkzeuge fehlen, öffne „In Karten einrichten“. Beide Funktionen verwenden dieselbe Python-Umgebung.
3. Gib beispielsweise „Gold“, „Goldbarren“, „Diamant“ oder eine Gegenstands-ID in die Suche ein. Deutsche und englische Bezeichnungen werden gleichzeitig durchsucht. „Gold“ findet auch goldene Ausrüstung; „Goldbarren“ ist genauer.
4. Wähle einen gefundenen Lagerort. Kisten mit höchstens sechs Blöcken Abstand werden zu zusammenhängenden Gruppen verbunden. Mit Pfeilen oder Auswahlfeld wechselst du innerhalb des Lagerorts durch die passenden Kisten. Rechts erscheinen alle belegten Plätze mit Menge und Gegenstands-ID. Passende Inhalte werden hervorgehoben. Über „Koordinaten kopieren“ kannst du die Position in der Karte suchen.
5. Du kannst nach Oberwelt/Nether filtern und den vollständigen Index als JSON exportieren.

Die Übersicht zeigt gespeicherte normale Kisten und Redstone-Truhen. Doppeltruhen erscheinen als getrennte Hälften. Spielerinventar, Endertruhen-Inhalt, Kistenloren und andere Behälter sind nicht enthalten. Generierte Beutetruhen können ebenfalls vorkommen. Es werden gespeicherte Mengen angezeigt, keine Live-Bestände.

Die App prüft Datensatzgrenzen, Kistenblock, Koordinaten, Plätze und Gegenstands-IDs. Nicht lesbare Datensätze sind ausdrücklich nicht „leer“. Bei abweichenden Spielformaten kann die Suche unvollständig sein. Unbekannte Gegenstände bleiben als ID sichtbar. Zusätzliche Itemdaten wie Haltbarkeit/Verzauberungen werden erkannt, aber nicht im Detail interpretiert.
""", en: """
1. Choose a saved world in Chests.
2. Click Read chests. If tools are missing, use Set up in Maps. Both features share the same Python environment.
3. Search for gold, gold ingot, diamond or an item ID. German and English names are searched together. Gold also matches golden equipment; gold ingot is more specific.
4. Select a matching storage location. Chests connected by distances of at most six blocks form a group. Use the arrows or picker to browse matching chests within that location. The detail pane shows every occupied slot with quantity and item ID. Matches are highlighted. Copy coordinates to locate the chest in the map.
5. Filter by Overworld/Nether and export the full index as JSON.

The index covers stored normal and trapped chests. Double chests appear as separate halves. Player inventory, Ender chest contents, chest minecarts and other containers are excluded. Generated loot chests may also appear. Quantities reflect this backup, not the live game.

The app validates record boundaries, the chest block, coordinates, slots and item IDs. Unreadable records are explicitly not treated as empty. Different game formats may limit coverage. Unknown items remain visible by ID. Additional item data such as durability/enchantments is detected but not interpreted in detail.
"""),
    .init(id: "places", icon: "mappin.and.ellipse", deTitle: "Orte finden & benennen", enTitle: "Find & name places", de: """
1. Erzeuge im Bereich „Karten“ eine neue Karte. Die Suche bezieht sich auf den dafür gewählten Bereich; für die ganze gespeicherte Welt wähle „Alle gespeicherten Chunks“.
2. Scrolle in der Karten-Seitenleiste zu „Interessante Orte“.
3. Wähle mögliche Gebäude, Kisten, Betten, Glasgruppen, Werkbänke oder Öfen. „Markierungen anzeigen“ schaltet die Punkte ein und aus.
4. Mit ← und → springst du zum vorherigen/nächsten Fund. Am Ende beginnt die Auswahl wieder von vorne. Alternativ klicke einen Punkt direkt an.
5. Gib dem ausgewählten Ort einen Namen, etwa „Lager zu Hause“, und klicke „Namen speichern“. Ein leer gespeicherter Name setzt die automatische Bezeichnung zurück.

Eigene Ortsnamen bleiben in der App für dieselbe Welt gespeichert, auch nach dem Schließen, Sprachwechsel oder erneuten Erzeugen einer Karte. Im externen Browser werden sie separat im jeweiligen Browserspeicher abgelegt.

Gebäude sind Vermutungen: Mindestens zwei Arten von Hinweisen innerhalb eines Rasterbereichs von 32 × 32 × 16 Blöcken ergeben einen Vorschlag. Ein Gebäudekomplex kann mehrere Vorschläge haben; Höhlen, Ruinen oder Lagerplätze können ebenfalls als Vorschlag erscheinen. Die App erkennt damit keine Hausgrenzen oder Besitzverhältnisse. Glas wird gruppiert, damit einzelne Scheiben die Karte nicht überladen. Kistenmarkierungen zeigen die Position; den Inhalt findest du im Bereich „Kisten“.
""", en: """
1. Generate a new map in Maps. Detection covers the selected area; choose All saved chunks to cover the stored world.
2. Scroll the map sidebar to Interesting places.
3. Choose possible buildings, chests, beds, glass groups, crafting tables or furnaces. Show markers toggles the overlay.
4. Use ← and → to jump to the previous/next place, wrapping around at the end. You can also click a marker directly.
5. Enter a name such as Home storage and click Save name. Saving an empty name restores the automatic label.

The app remembers custom names for the same world after closing, switching language or generating another map. An external browser stores names separately in its own browser storage.

Buildings are suggestions: at least two indicator categories within a 32 × 32 × 16 block grid area produce a suggestion. Large complexes may have several suggestions; caves, ruins or storage areas may also qualify. This does not detect house boundaries or ownership. Glass is grouped to avoid clutter from individual panes. Chest markers show the location; use Chests to inspect contents.
"""),
    .init(id: "biomes", icon: "leaf", deTitle: "Biome erkennen", enTitle: "Identify biomes", de: """
Erzeuge eine neue Karte und bewege den Mauszeiger über die Welt. Links oben in der Karte erscheint der gespeicherte Biomname samt ID. Auch beim Anklicken eines Blocks und nach der Koordinatensuche wird das Biom angezeigt.

Die Zuordnung wird aus den gespeicherten Biomdaten gelesen. Das unterstützte Version-9-Format enthält pro Chunk ein Raster von 4 × 4 Einträgen: Ein Eintrag gilt für 4 × 4 Blöcke. Die Anzeige verwendet die horizontale X-/Z-Position. Ein Wechsel der Y-Ebene ändert dieses gespeicherte Biom nicht; eine eigene vertikale Höhlen-Biomkarte ist nicht enthalten.

Die Namen wurden mit den Biomdefinitionen der installierten Spielversion abgeglichen. Außerhalb der gespeicherten Kartenbereiche steht „keine Daten“. Nicht bekannte IDs werden als unbekannt angezeigt. Die Karte zeigt den Stand der gewählten Sicherung und verfolgt deine aktuelle Position auf der Quest nicht live.
""", en: """
Generate a new map and move the pointer over the world. The saved biome name and ID appear at the top left of the map. Clicking a block or searching coordinates also displays the biome.

Names come from saved biome data. The supported version-9 format stores a 4 × 4 grid per chunk: each entry covers 4 × 4 blocks. The display uses horizontal X/Z coordinates. Changing Y level does not change this saved biome; a separate vertical cave-biome map is not included.

Names were matched to the installed game version. Areas outside saved map coverage show no data. Unrecognized IDs remain unknown. The map reflects the chosen backup and does not track your current Quest position live.
"""),
    .init(id: "start", icon: "sparkles", deTitle: "Willkommen", enTitle: "Welcome", de: """
Deine RealmCraft-Welten, sicher auf dem Mac.

Die Savegame Library speichert einzelne RealmCraft-Welten von deiner Meta Quest und überträgt ausgewählte Sicherungen zurück. Jede Sicherung erhält einen eigenen Eintrag mit Datum, Uhrzeit, Dateianzahl und Größe. Ein vorhandenes Vorschaubild wird angezeigt.

SCHNELLSTART
1. Öffne „Einrichtung“ über das Zahnrad.
2. Prüfe ADB oder installiere die offiziellen Android Platform Tools.
3. Verbinde deine Quest per USB und erlaube USB-Debugging im Headset.
4. Speichere im Spiel und beende RealmCraft.
5. Klicke „Quest → Mac sichern“.

Die App ist für macOS 14 oder neuer auf Apple-Silicon- und Intel-Macs gebaut. Sie unterstützt RealmCraft-Welten mit world_data und player_data. Sie ist kein allgemeines Backup-Programm für andere Quest-Spiele.

Die gesamte App und diese Hilfe lassen sich über den Sprachumschalter auf Deutsch oder Englisch umstellen. Eigene Spielstandnamen bleiben unverändert.
""", en: """
Your RealmCraft worlds, saved on your Mac.

Savegame Library backs up individual RealmCraft worlds from your Meta Quest and restores a selected backup to the headset. Each backup has its own date, time, file count and size. A screenshot is displayed when available.

QUICK START
1. Open “Setup” using the gear button.
2. Check ADB or install the official Android Platform Tools.
3. Connect your Quest by USB and allow USB debugging in the headset.
4. Save in the game, then close RealmCraft.
5. Click “Back up Quest → Mac”.

The app is built for macOS 14 or later, on Apple Silicon and Intel Macs. It supports RealmCraft worlds containing world_data and player_data. It is not a general backup tool for other Quest games.

Both the app interface and this help can be switched between German and English using the language selector. Your own savegame names stay unchanged.
"""),
    .init(id: "setup", icon: "cable.connector", deTitle: "Einrichtung", enTitle: "Step-by-step setup", de: releaseDocument("SETUP-de"), en: releaseDocument("SETUP-en")),
    .init(id: "agent", icon: "text.bubble", deTitle: "Hilfe mit einem Agenten", enTitle: "Help from an agent", de: """
Du kannst GPT, Claude oder einen anderen Agenten bei der Einrichtung um Hilfe bitten.

1. Klicke unten auf „Agent-Anleitung als MD speichern“. Die Sprache folgt dem Umschalter dieser Hilfe.

2. Öffne deinen bevorzugten KI-Chat und füge die gespeicherte .md-Datei als Anhang hinzu. Alternativ kannst du die Instruktionen kopieren und in den Chat einfügen.

3. Schreibe dazu: „Bitte hilf mir mit dieser Anleitung bei der Einrichtung. Ich bin bei Schritt … und sehe folgende Meldung: …“

4. Der Agent führt dich durch die Schritte. Ohne eigene lokale Werkzeuge kann er nur erklären; er erhält durch die Datei keinen Zugriff auf deinen Mac oder deine Quest. Freigaben im Headset und Kontoanmeldungen erledigst du selbst.

Die Datei enthält die komplette Einrichtungsanleitung, Diagnosehinweise und Regeln zum Schutz deiner Welten. Persönliche Pfade, Geräte-IDs, Protokolle und Spielstände werden nicht eingefügt. Die optionalen Angaben zu deinem Problem ergänzt du selbst. Prüfe sie vor dem Teilen.
""", en: """
You can ask GPT, Claude or another agent to help you set up the app.

1. Click “Save agent instructions as MD” below. The exported language follows this help's language selector.

2. Open your preferred AI chat and attach the saved .md file. Alternatively, copy the instructions and paste them into the chat.

3. Add: “Please help me set this up using the attached instructions. I am on step … and see this message: …”

4. The agent guides you through the steps. Without its own local tools it can only explain; this file does not grant access to your Mac or Quest. Complete headset permissions and account sign-in yourself.

The file includes the full setup guide, diagnosis hints and rules for protecting your worlds. It does not insert personal paths, device IDs, logs or savegames. Fill in optional details about your problem yourself and review them before sharing.
"""),
    .init(id: "backup", icon: "arrow.down.to.line", deTitle: "Quest → Mac sichern", enTitle: "Back up Quest → Mac", de: """
1. Speichere deinen Fortschritt in RealmCraft.
2. Beende das Spiel vollständig.
3. Prüfe oben das ausgewählte Gerät und die Welt-ID.
4. Klicke „Quest → Mac sichern“ und lasse die Quest verbunden.
5. Warte auf „Gesichert und geprüft“. Der neue Eintrag wird ausgewählt.

Die App vergleicht die Dateien per SHA-256 auf Quest und Mac. Außerdem prüft sie, ob sich die Quest-Dateien während der Sicherung geändert haben. Unvollständige Sicherungen werden nicht als fertiger Library-Eintrag angezeigt.

SPIEL VOM MAC BEENDEN
Der Stopp-Button oben führt „am force-stop“ aus. Er beendet RealmCraft sofort und löst KEIN Speichern aus. Speichere zuerst im Spiel, damit kein ungespeicherter Fortschritt verloren geht. Die App fragt vor dem Beenden nach.

Während einer Übertragung sind weitere Aktionen gesperrt. Das normale Beenden der Mac-App wird während einer laufenden Übertragung verhindert.
""", en: """
1. Save your progress in RealmCraft.
2. Fully close the game.
3. Check the selected headset and world ID at the top.
4. Click “Back up Quest → Mac” and keep the Quest connected.
5. Wait for “Backed up and verified”. The new entry is selected.

The app compares SHA-256 file checksums on the Quest and Mac. It also checks whether the Quest files changed during the backup. Incomplete backups do not appear as completed library entries.

CLOSE THE GAME FROM YOUR MAC
The stop button runs “am force-stop”. It closes RealmCraft immediately and does NOT save the game. Save in the game first to avoid losing unsaved progress. The app asks for confirmation before stopping it.

Other actions are disabled during a transfer. Normal quitting of the Mac app is blocked while a transfer is in progress.
"""),
    .init(id: "restore", icon: "arrow.up.to.line", deTitle: "Mac → Quest laden", enTitle: "Restore Mac → Quest", de: """
1. Speichere und beende RealmCraft.
2. Wähle in der linken Liste den gewünschten Spielstand aus.
3. Kontrolliere Datum, Uhrzeit, Welt-ID und Zielgerät.
4. Klicke „Auf Quest wiederherstellen“ und bestätige „Sichern & wiederherstellen“.
5. Starte das Spiel erst nach der Erfolgsmeldung.

Vor dem Ersetzen wird die aktuelle Zielwelt automatisch auf dem Mac gesichert. Diesen Eintrag erkennst du an „Auto“ und „Vor Wiederherstellung“. Anschließend wird der gewählte Stand in einen separaten Quest-Ordner übertragen und geprüft. Erst danach wird er aktiviert.

Die Welt-ID des gewählten Library-Eintrags bestimmt die Zielwelt. Die Welt-Auswahl oben gilt für neue Sicherungen. Andere Quest-Welten werden nicht ersetzt.

ZUSÄTZLICHE RÜCKFALLKOPIE
Die vorherige Welt bleibt außerdem auf der Quest außerhalb der aktiven Welten unter files/.library-previous-<UUID> erhalten. Das belegt zusätzlichen Speicher. Fehlgeschlagene Übertragungen können .library-stage-<UUID> hinterlassen. Die App löscht diese Ordner nicht automatisch.

Bei einem USB-Abbruch oder einer unbestätigten Aktivierung: Spiel geschlossen lassen, Verbindung wiederherstellen und die Fehlermeldung beachten. Die automatische Sicherung in der Library kann erneut wiederhergestellt werden. Das Ende der Übertragung wurde dann nicht sicher bestätigt.
""", en: """
1. Save and close RealmCraft.
2. Select the backup you want in the left-hand list.
3. Check its date, time, world ID and the target device.
4. Click “Restore to Quest”, then confirm “Back up & restore”.
5. Only start the game after the success message.

Before replacing an existing target world, the app automatically backs it up to your Mac. This entry is marked “Auto” and “Before restore”. The selected backup is then uploaded to a separate folder on the Quest and verified before activation.

The selected library entry's world ID determines which world is restored. The world selector at the top is used when creating new backups. Other Quest worlds are not replaced.

EXTRA RECOVERY COPY
The previous world also remains on the Quest outside the active worlds directory, under files/.library-previous-<UUID>. This uses extra storage. Failed transfers can leave .library-stage-<UUID> folders. The app does not remove these folders automatically.

If USB disconnects or activation cannot be confirmed: keep the game closed, reconnect and follow the error message. You can restore the automatic library backup again. Completion of the interrupted transfer has not been confirmed.
"""),
    .init(id: "library", icon: "archivebox", deTitle: "Library & Speicherort", enTitle: "Library & storage", de: """
Wähle einen Spielstand in der linken Liste. Über den Stift kannst du ihn umbenennen. Die Suche filtert nach Name und Welt-ID. Die Ordner-Buttons öffnen die Library oder den gewählten Weltordner im Finder.

DATUM UND UHRZEIT
Die große Datumsanzeige bezeichnet die Sicherung beziehungsweise den Import. „Letzte Dateiänderung“ zeigt den neuesten Änderungszeitpunkt innerhalb der Weltdateien. Bei ZIPs aus dieser App bleibt die ursprüngliche Sicherungszeit erhalten; bei fremden Backups wird die Importzeit verwendet.

SPEICHERORDNER ÄNDERN
Öffne „Einrichtung“ → „Speicherordner ändern“. Standardmäßig werden vorhandene Library-Einträge in den neuen Ordner kopiert und geprüft. Der alte Ordner bleibt als Sicherung erhalten. Deaktiviere das Kopieren, wenn du nur eine andere vorhandene Library öffnen möchtest.

STANDARDPFAD
~/Library/Application Support/RealmCraftLibrary/Savegames

Jeder Library-Eintrag enthält die Weltdateien, savegame.json und manifest.json. Verschiebe immer den ganzen Eintragsordner. Manuelles Ändern der Weltdateien führt bei der nächsten Prüfung zu einem Fehler. Als neue Variante kannst du einen geänderten Weltordner über Importieren aufnehmen.
""", en: """
Select a backup in the left-hand list. Use the pencil button to rename it. Search filters by name and world ID. Folder buttons reveal either the library or the selected world in Finder.

DATES AND TIMES
The main date is the backup or import time. “Last file change” shows the latest modification time among the world files. ZIPs exported by this app retain the original backup time; other imports use the import time.

CHANGE STORAGE LOCATION
Open “Setup” → “Change storage folder”. Existing library entries are copied and verified by default. The old folder remains as a safety copy. Turn off copying if you only want to open a different existing library.

DEFAULT LOCATION
~/Library/Application Support/RealmCraftLibrary/Savegames

Each entry contains the world files, savegame.json and manifest.json. Always move the complete entry folder. Manually changing its world files will cause verification to fail. You can import a modified world folder as a new variant instead.
"""),
    .init(id: "zip", icon: "doc.zipper", deTitle: "ZIP & Weitergeben", enTitle: "ZIP & sharing", de: """
SAVEGAME EXPORTIEREN
Wähle einen Eintrag und klicke „Als ZIP exportieren“. Die Dateien werden vor dem Export geprüft. Wähle einen Dateinamen und Speicherort. Das ZIP enthält die vollständige Welt sowie die Library-Metadaten und Prüfsummen.

SAVEGAME IMPORTIEREN
Klicke „Importieren“. Unterstützt werden ein Weltordner mit seiner ursprünglichen Welt-ID als Namen oder ein ZIP mit genau einer solchen Welt. world_data und player_data müssen vorhanden sein. ZIPs mit unsicheren Pfaden oder symbolischen Verknüpfungen werden abgelehnt.

In der Einrichtung kannst du einen Backup-Ordner auswählen. Darin werden ZIP-Backups und Weltordner automatisch gefunden. Der Zugriff erfolgt erst nach deiner Ordnerauswahl.

DIE APP WEITERGEBEN
Teile die App-ZIP, nicht deinen Library-Ordner. Die Verteilungs-ZIP enthält keine persönlichen Spielstände und kein ADB. Empfänger können ADB in der Einrichtung installieren und die App nach Programme verschieben.

Diese Community-Version ist lokal signiert, aber nicht von Apple notarisiert. macOS kann beim ersten Start einen Hinweis auf einen unbekannten Entwickler zeigen. Die unten verlinkte Apple-Anleitung erklärt die Sicherheitsprüfung. Öffne nur Kopien aus einer vertrauenswürdigen Quelle.
""", en: """
EXPORT A SAVEGAME
Select an entry and click “Export ZIP”. Its files are verified before export. Choose a name and destination. The ZIP contains the complete world, library metadata and checksums.

IMPORT A SAVEGAME
Click “Import”. Select a world folder named with its original world ID, or a ZIP containing exactly one such world. world_data and player_data must be present. Archives with unsafe paths or symbolic links are rejected.

In Setup, select a backup folder to automatically discover ZIP backups and world folders inside it. The folder is only accessed after you select it.

SHARE THE APP
Share the app ZIP, not your library folder. The distribution ZIP contains no personal savegames and does not bundle ADB. Recipients can install ADB from Setup and move the app to Applications.

This community build is locally signed but is not notarized by Apple. macOS may display an unidentified-developer warning on first launch. Apple's guide linked below explains the security checks. Only open copies from a trusted source.
"""),
    .init(id: "trouble", icon: "wrench.and.screwdriver", deTitle: "Probleme lösen", enTitle: "Troubleshooting", de: """
KEINE QUEST GEFUNDEN
Quest aufwecken, USB-Kabel neu verbinden und einen anderen USB-Anschluss oder ein Datenkabel versuchen. Entwicklermodus prüfen. Der Verbindungsbutton startet die Suche sofort.

USB NICHT AUTORISIERT
Setze das Headset auf und bestätige die USB-Debugging-Abfrage. Danach erneut prüfen. Die reine Freigabe für Dateiübertragung ist nicht dasselbe wie USB-Debugging.

REALMCRAFT ODER WELT FEHLT
Prüfe das ausgewählte Gerät. Installiere RealmCraft auf der Quest und starte es einmal. Lege eine Welt an, speichere und beende das Spiel. Welten benötigen world_data und player_data.

DAS SPIEL LÄUFT NOCH
Speichere im Spiel und beende es vollständig. Alternativ kannst du nach dem Speichern den Stopp-Button in der App verwenden.

DATEIEN STIMMEN NICHT ÜBEREIN
Lasse das Spiel während der Übertragung geschlossen. Übertrage erneut. Eine manuell veränderte Library-Kopie muss als neuer Weltordner importiert werden, damit neue Prüfsummen entstehen.

SPEICHER VOLL / ZUGRIFF VERWEIGERT
Prüfe freien Speicher auf Mac und Quest sowie Schreibrechte für den Library-Ordner. In macOS unter Datenschutz & Sicherheit → Dateien und Ordner den Zugriff prüfen. Wähle bei Bedarf einen anderen Speicherordner.

DOWNLOAD FEHLGESCHLAGEN
Internetverbindung prüfen und erneut versuchen. Alternativ Platform Tools von Google herunterladen und die adb-Datei über „Vorhandenes ADB auswählen“ angeben.

Für Unterstützung kannst du in der Einrichtung „Diagnose kopieren“ verwenden. Prüfe den Text vor dem Weitergeben; Fehlermeldungen können lokale Dateipfade enthalten.
""", en: """
NO QUEST FOUND
Wake the headset, reconnect USB and try another port or a data cable. Check developer mode. The connection refresh button starts a scan immediately.

USB UNAUTHORIZED
Put on the headset and accept the USB debugging prompt, then check again. Permission for file transfer alone is not the same as USB debugging.

GAME OR WORLD MISSING
Check the selected device. Install and launch RealmCraft on the Quest. Create a world, save and close the game. Worlds must contain world_data and player_data.

GAME STILL RUNNING
Save in the game and close it fully. After saving, you can also use the app's stop button.

FILES DO NOT MATCH
Keep the game closed throughout the transfer and try again. A manually modified library copy must be imported as a new world folder to create new checksums.

DISK FULL / PERMISSION DENIED
Check free storage on both Mac and Quest and write access to your library folder. Review macOS Privacy & Security → Files and Folders permissions. Select another library location if needed.

DOWNLOAD FAILED
Check your internet connection and retry. You can also download Platform Tools from Google and use “Select existing ADB” to choose the adb file.

Use “Copy diagnostics” in Setup when requesting support. Review the text before sharing it; error messages may contain local file paths.
"""),
    .init(id: "origin", icon: "quote.bubble", deTitle: "Ursprung des Tools", enTitle: "Why this tool exists", de: """
Die Idee entstand aus einer Frage in der RealmCraft-Community: Wie lässt sich eine große Welt lokal sichern, wenn der Upload zum Spielserver nicht mehr möglich ist?

In einer Discord-Antwort im Kanal #general vom 31. August 2026 um 10:21 erklärte AdminPickaxe (Rolle „RCVR“), dass ihm zu diesem Zeitpunkt keine konkreten Pläne bekannt seien, das genannte Uploadlimit von 250 MB zu erhöhen. Er wollte beim Team nachfragen.

Als Möglichkeit für ein lokales Backup beschrieb er, das Headset per USB an einen Computer anzuschließen, die Verbindung im Headset zu erlauben und den Weltordner auf den Computer zu kopieren. Der dort genannte Speicherort war:

Android/data/com.TellurionMobile.RealmCraft/files/local

Unter Windows wurde dieser Pfad über „Dieser PC → Quest 3S → Interner gemeinsamer Speicher“ erreicht. Diese Mac-App greift über ADB auf denselben Bereich zu und ergänzt eine Library mit Zeitstempeln, geprüften Kopien, ZIP-Export und Wiederherstellung.

Das Ziel: eigene Welten unabhängig vom Server-Upload auf dem Mac sichern und einen gewünschten Stand später wieder auf die Quest übertragen.

QUELLE UND EINORDNUNG
Grundlage ist der vom Initiator bereitgestellte Screenshot dieser Discord-Nachricht. Die 250 MB beschreiben den damals genannten Server-Uploadgrenzwert, keine in dieser App eingebaute Größenbeschränkung und keine Aussage über heute geltende Serverregeln. Die Nachricht empfiehlt lokale Kopien; sie ist keine offizielle Freigabe oder Unterstützung dieser App. Diese wurde unabhängig als Community-Werkzeug entwickelt.
""", en: """
The idea began with a question in the RealmCraft community: how can a large world be backed up locally when it can no longer be uploaded to the game server?

In a Discord reply in #general dated August 31, 2026 at 10:21, AdminPickaxe (with the “RCVR” role) said that, to his knowledge at the time, there were no current plans to raise the stated 250 MB upload limit. He intended to ask the team about it.

He described a local backup option: connect the headset to a computer by USB, allow the connection inside the headset, and copy the world folder to the computer. The location he provided was:

Android/data/com.TellurionMobile.RealmCraft/files/local

On Windows, this was accessed through “This PC → Quest 3S → Internal shared storage”. This Mac app uses ADB to access the same area and adds a library with timestamps, verified copies, ZIP export and restore.

The aim is to let players keep their own worlds on a Mac independently of server uploads and restore a selected version to the Quest later.

SOURCE AND CONTEXT
This account is based on a screenshot of the Discord message supplied by the tool's initiator. The 250 MB figure is the server upload limit mentioned at that time. It is neither a size limit built into this app nor a claim about current server rules. The message suggests local copying; it does not officially approve or endorse this app. This utility was developed independently for the community.
"""),
    .init(id: "development", icon: "chevron.left.forwardslash.chevron.right", deTitle: "Entwicklung & Quellcode", enTitle: "Development & source", de: """
Dieses Programm wurde vollständig mit OpenAI Codex und GPT-6 Astra entwickelt.

FÜR DIE COMMUNITY
Der vollständige Projektquellcode steht unter der MIT-Lizenz zur Verfügung: Swift-App, Übertragungslogik, deutsche und englische Texte, Hilfe, Tests, Build-Skript und die Quellen zur Erzeugung des Icons. Über den Button unten kannst du das Quellcode-Paket als ZIP speichern.

Das Paket enthält keine persönlichen Spielstände. Die Datei COMMUNITY.md erklärt das Erstellen und Testen auf einem Mac. Zum Erstellen werden Xcode Command Line Tools und Python 3 benötigt; zur normalen Nutzung der fertigen App nicht.

Die App verwendet Apple-Systemframeworks und Googles ADB als externe Komponenten. Diese wurden nicht für dieses Projekt entwickelt und unterliegen ihren eigenen Lizenzbedingungen. Diese unabhängige Community-App ist kein offizielles Produkt von OpenAI, Meta, Google oder Tellurion Mobile.
""", en: """
This program was developed entirely with OpenAI Codex and GPT-6 Astra.

FOR THE COMMUNITY
The complete project source is available under the MIT license: the Swift app, transfer logic, German and English text, help, tests, build script and original icon-generation code. Use the button below to save the source package as a ZIP.

The package contains no personal savegames. COMMUNITY.md explains how to build and test it on a Mac. Building requires Xcode Command Line Tools and Python 3; running the finished app does not.

The app uses Apple's system frameworks and Google's ADB as external components. These were not developed for this project and retain their own licenses. This independent community app is not an official product of OpenAI, Meta, Google or Tellurion Mobile.
"""),
    .init(id: "updates", icon: "clock.arrow.circlepath", deTitle: "Update Log (English)", enTitle: "Update Log", de: releaseDocument("CHANGELOG"), en: releaseDocument("CHANGELOG")),
    .init(id: "backlog", icon: "list.bullet.clipboard", deTitle: "Backlog (English)", enTitle: "Backlog", de: releaseDocument("BACKLOG"), en: releaseDocument("BACKLOG")),
    .init(id: "privacy", icon: "hand.raised", deTitle: "Datenschutz & Links", enTitle: "Privacy & links", de: """
Deine Spielstände bleiben im gewählten Library-Ordner und auf deiner Quest. Die App enthält keine Telemetrie und lädt keine Savegames hoch. ADB kommuniziert mit verbundenen Geräten. Beim Installieren der Platform Tools wird eine Verbindung zur offiziellen Google-Downloadadresse hergestellt.

Ein Speicherordner in iCloud Drive, Dropbox oder einem anderen synchronisierten Verzeichnis kann durch diesen Dienst hochgeladen werden. Das hängt von deinen Mac- und Cloud-Einstellungen ab.

Deine Gerätefreigabe für USB-Debugging verwaltet die Quest. Du kannst sie in den Headset-Einstellungen widerrufen.

RealmCraft Companion ist eine unabhängige Community-App. Sie ist nicht mit Meta, Google oder Tellurion Mobile verbunden. Die Marken und das Spiel gehören ihren jeweiligen Rechteinhabern.

Die folgenden Links öffnen offizielle Anleitungen im Browser.
""", en: """
Your savegames remain in your selected library folder and on your Quest. This app includes no telemetry and does not upload savegames. ADB communicates with connected devices. Installing Platform Tools connects to Google's official download address.

A folder inside iCloud Drive, Dropbox or another synced location may be uploaded by that service, depending on your Mac and cloud settings.

The Quest manages your USB debugging authorization. You can revoke it in the headset settings.

RealmCraft Companion is an independent community app. It is not affiliated with Meta, Google or Tellurion Mobile. The game and trademarks belong to their respective owners.

The following links open official guides in your browser.
""")
]

struct HelpView: View {
    var embedded = false
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("lastHelpTopic") private var selected = "start"
    @State private var search = ""
    @State private var sourceError: String?
    @State private var copiedInstructions = false
    private var english: Bool { language == "en" }
    private var articles: [HelpArticle] {
        helpArticles.filter { search.isEmpty || (english ? $0.enTitle + $0.en : $0.deTitle + $0.de).localizedCaseInsensitiveContains(search) }
    }
    private var article: HelpArticle { helpArticles.first(where: { $0.id == selected }) ?? helpArticles[0] }
    var body: some View {
        VStack(spacing: 0) {
            if !embedded {
            HStack {
                Label(english ? "Help & getting started" : "Hilfe & erste Schritte", systemImage: "questionmark.circle.fill").font(.title2.bold()).foregroundStyle(.teal)
                Spacer()
                Picker("Language / Sprache", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 185).fixedSize(horizontal: true, vertical: false)
            }.padding(22)
            Divider()
            }
            HStack(spacing: 0) {
                VStack {
                    TextField(english ? "Search help" : "Hilfe durchsuchen", text: $search).textFieldStyle(.roundedBorder).padding(12)
                    List(selection: $selected) {
                        ForEach(articles) { article in
                            Label(english ? article.enTitle : article.deTitle, systemImage: article.icon).padding(.vertical, 6).tag(article.id)
                        }
                    }.listStyle(.sidebar)
                }.frame(width: 230)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Label(english ? article.enTitle : article.deTitle, systemImage: article.icon).font(.title.bold())
                        HelpParagraphs(content: english ? article.en : article.de)
                        if article.id == "development" {
                            Button(action: exportSource) {
                                Label(english ? "Export complete source ZIP…" : "Vollständigen Quellcode als ZIP exportieren…", systemImage: "square.and.arrow.up")
                            }.buttonStyle(.borderedProminent)
                        }
                        if article.id == "agent" {
                            VStack(alignment: .leading, spacing: 12) {
                                Button(english ? "Save agent instructions as MD…" : "Agent-Anleitung als MD speichern …") { exportResource("AGENT-SETUP-" + language, extension: "md") }.buttonStyle(.borderedProminent)
                                Button(english ? "Copy agent instructions" : "Agent-Instruktionen kopieren") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(releaseDocument("AGENT-SETUP-" + language), forType: .string)
                                    copiedInstructions = true
                                }
                                if copiedInstructions { Text(english ? "Copied. Paste into your preferred AI chat." : "Kopiert. Im gewünschten KI-Chat einfügen.").font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: 10) {
                            if article.id == "setup" {
                                Link(english ? "Meta · Create a developer team" : "Meta · Entwicklerteam erstellen", destination: URL(string: "https://developers.meta.com/horizon/manage/organizations/create/")!)
                                Link(english ? "Meta · Verify your account" : "Meta · Konto verifizieren", destination: URL(string: "https://developers.meta.com/horizon/manage/verify/")!)
                                Link("Android · USB debugging", destination: URL(string: "https://developer.android.com/studio/run/device")!)
                            }
                            Link("Google · Android Platform Tools", destination: URL(string: "https://developer.android.com/tools/releases/platform-tools")!)
                            Link(english ? "Meta · Set up your device" : "Meta · Gerät einrichten", destination: URL(string: "https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/")!)
                            Link(english ? "Apple · Open apps safely" : "Apple · Apps sicher öffnen", destination: URL(string: english ? "https://support.apple.com/en-gb/102445" : "https://support.apple.com/de-de/102445")!)
                        }.font(.callout)
                    }.padding(28)
                }.id(article.id + language)
            }
        }.frame(minWidth: 820, minHeight: 650)
        .environment(\.locale, Locale(identifier: language))
        .alert(english ? "Export failed" : "Export fehlgeschlagen", isPresented: Binding(get: { sourceError != nil }, set: { if !$0 { sourceError = nil } })) {
            Button("OK") { sourceError = nil }
        } message: { Text(sourceError ?? "") }
    }
    private func exportSource() { exportResource("CommunitySource", extension: "zip") }
    private func exportResource(_ name: String, extension fileExtension: String) {
        guard let source = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            sourceError = english ? "The requested document is missing from this app build." : "Das angeforderte Dokument fehlt in dieser App-Version."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: fileExtension) ?? .plainText]
        panel.nameFieldStringValue = name == "CommunitySource" ? "RealmCraft-Savegame-Library-Source.zip" : "RealmCraft-" + name + "." + fileExtension
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        do {
            try Data(contentsOf: source).write(to: destination, options: .atomic)
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch { sourceError = error.localizedDescription }
    }
}
struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("appLanguage") private var language = "en"
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(language == "en" ? "RealmCraft Library Help" : "RealmCraft Library Hilfe") { openWindow(id: "help") }.keyboardShortcut("?", modifiers: .command)
        }
    }
}

private struct HelpParagraphs: View {
    let content: String
    private var paragraphs: [String] { content.components(separatedBy: "\n\n") }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(paragraphs.indices, id: \.self) { index in
                HelpParagraph(text: paragraphs[index])
            }
        }
    }
}
private struct HelpParagraph: View {
    let text: String
    private var heading: Bool { text == text.uppercased() && text.count < 100 && text.contains(where: { $0.isLetter }) }
    var body: some View {
        if heading {
            Text(text).font(.caption.weight(.bold)).tracking(1).foregroundStyle(.teal).padding(.top, 8)
        } else {
            Text(text).font(.system(size: 14)).lineSpacing(4).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
