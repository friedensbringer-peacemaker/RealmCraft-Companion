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
private enum HelpCategory: String, CaseIterable, Identifiable {
    case gettingStarted, world, ai, knowledge, support, background, updates
    var id: String { rawValue }
    func title(english: Bool) -> String {
        switch self {
        case .gettingStarted: return english ? "Getting started" : "Einstieg & Bedienung"
        case .world: return english ? "Your world" : "Deine Welt"
        case .ai: return english ? "AI tools" : "KI-Werkzeuge"
        case .knowledge: return english ? "Knowledge & help" : "Wissen & Hilfe"
        case .support: return english ? "Support" : "Unterstützung"
        case .background: return english ? "About the app" : "Über die App"
        case .updates: return english ? "Updates & plans" : "Updates & Ausblick"
        }
    }
}

private extension HelpArticle {
    var category: HelpCategory {
        switch id {
        case "start", "companion", "setup", "manualTransfer", "appearance": return .gettingStarted
        case "library", "backup", "restore", "zip", "maps", "navigation", "places", "biomes", "chests", "player", "statistics", "editor": return .world
        case "aiExport", "skills", "conversation": return .ai
        case "videos", "builds", "mobs", "resources": return .knowledge
        case "trouble", "feedback", "agent": return .support
        case "updates", "backlog": return .updates
        default: return .background
        }
    }
}

private func releaseDocument(_ name: String) -> String {
    guard let url = Bundle.main.url(forResource: name, withExtension: "md"),
          let content = try? String(contentsOf: url, encoding: .utf8) else { return "This document is unavailable in this build." }
    return content
}
private let helpArticles: [HelpArticle] = [
    .init(id: "start", icon: "sparkles", deTitle: "Willkommen", enTitle: "Welcome", de: """
RealmCraft Companion begleitet dich beim Sichern, Erkunden und Auswerten deiner RealmCraft-Welten auf dem Mac.

ERSTER START
Die Einrichtung führt dich durch Mac-Voraussetzungen, ADB, Meta-Konto, Entwicklermodus, USB-Freigabe, Spielprüfung und Speicherort. „Später“ merkt sich deinen Fortschritt. „Companion öffnen“ beendet die Anleitung und startet keine Übertragung. Über Einstellungen → Quest einrichten öffnest du sie erneut; „Alle Einstellungen“ führt zu den Detailoptionen.

ERSTE SICHERUNG
1. Speichere in RealmCraft und beende das Spiel vollständig.
2. Öffne Savegames. Wähle im Aktionsmenü (…) unter „Gerät & Welt“ das richtige Gerät und die gewünschte Welt.
3. Klicke „Vom Gerät sichern“ und warte auf die bestätigte, geprüfte Sicherung.
4. Wähle die Sicherung anschließend in Karten, Kisten, Spieler oder Statistiken aus.

VORAUSSETZUNGEN
Die App ist für macOS 14 oder neuer auf Apple Silicon und Intel gebaut. ADB lässt sich in der Einrichtung installieren. Für Karten und Kistensuche installiert „Kartenwerkzeuge installieren“ zusätzlich eine eigene Python-Umgebung mit NumPy und Pillow. Ein Coding-Agent oder API-Schlüssel ist dafür nicht nötig. Optionale Sprach- und KI-Funktionen haben eigene Voraussetzungen; siehe „Gespräch · Beta“.

Die meisten Ansichten lesen gespeicherte Daten. Änderungen im laufenden Spiel werden erst nach dem Speichern und einer neuen Sicherung sichtbar. Der Editor erstellt dagegen ausdrücklich bestätigte, experimentelle Kopien.
""", en: """
RealmCraft Companion helps you back up, explore and inspect your RealmCraft worlds on a Mac.

FIRST LAUNCH
The setup guide covers Mac requirements, ADB, your Meta account, developer mode, USB authorization, game checks and storage. Later remembers your progress. Open Companion ends the guide without starting a transfer. Reopen it through Settings → Quest setup; All settings opens the detailed options.

FIRST BACKUP
1. Save in RealmCraft and fully close the game.
2. Open Savegames. In the actions menu (…), use Device & world to select the correct headset and world.
3. Click Backup from device and wait for the verified success message.
4. Select that backup in Maps, Chests, Player or Statistics.

REQUIREMENTS
The app is built for macOS 14 or later on Apple Silicon and Intel. Setup can install ADB. For maps and chest search, Install map tools adds a private Python environment with NumPy and Pillow. No coding agent or API key is required. Optional speech and AI features have separate requirements; see Conversation · Beta.

Most views read saved data. Changes in the running game become visible after saving and creating a new backup. The editor instead creates explicitly confirmed experimental copies.
"""),
    .init(id: "companion", icon: "square.grid.2x2", deTitle: "Der Companion", enTitle: "The companion", de: """
Die Hilfe folgt den Gruppen und der Reihenfolge im linken Hauptmenü. „Willkommen“ und allgemeine Bedienung stehen davor.

DEINE WELT
• Savegames: Welten sichern, importieren, organisieren, wiederherstellen und als ZIP archivieren.
• Karten: Gespeicherte Landschaft, Ebenen, Orte, Biome und Kisten erkunden; die 3D-Ansicht ist eine Beta.
• Kisten: Materialien suchen, Fundorte vergleichen und eigene oder bereits entdeckte Behälter markieren.
• Spieler: Inventar, Rüstung, Level, Haltbarkeit und Reparaturprognosen lesen; eine lokale Skin-Vorschau einstellen.
• Statistiken · Beta: Bau-/Abbauzähler und aktuelle Truhenbestände nach Item und Thema auslesen.
• Editor · Beta / Preview: Gegenstände oder Level in einer neuen Sicherungskopie bearbeiten.

KI-WERKZEUGE
• KI-Export: Einen geprüften Weltkontext als Markdown oder JSON für externe Assistenten erzeugen; optional Navigation beifügen und per iCloud oder AirDrop weitergeben.
• Gespräch · Beta: Per Text oder Mac-Mikrofon nach gespeicherten Orten, eigenen Vorräten, Rezepten und Anleitungen fragen.
• Skills: Wiederverwendbare Agenten-Anweisungen und optionalen persönlichen Kontext verwalten.

WISSEN & HILFE
• Videos & Tipps: Videos nach Thema, Material und Bearbeitungsstand finden und Zeitmarken öffnen.
• Bauanleitungen: Offline-Testaufbauten mit Materiallisten, Bauschritten und Testnotizen.
• Mobs & Animals: Kreaturenregister mit Quellen und ausdrücklich gekennzeichneten Unsicherheiten.
• Links & Wissen: Community-Verweise und Minecraft-Vergleich.
• Hilfe: Bedienung, Einrichtung, Fehlerhilfe, Quellcode und Versionshinweise.

BEDIENUNG
Das Aktionsmenü (…) enthält zusätzliche Funktionen eines Bereichs. Einstellungen unten links enthalten Quest-Einrichtung, Optik, Erkundung & Spoiler, Gegenstands-Icons und Sprache. Dort kannst du auch Companion-Instanzen beenden oder neu starten. Laufende Arbeiten müssen vorher abgeschlossen sein. „Daten / Bug melden“ öffnet einen prüfbaren Berichtsentwurf.
""", en: """
Help follows the groups and order of the main sidebar, with Welcome and general guidance first.

YOUR WORLD
• Savegames: Back up, import, organize, restore and archive worlds as ZIPs.
• Maps: Explore saved terrain, layers, places, biomes and chests; the 3D view is a beta.
• Chests: Search materials, compare locations and mark owned or discovered containers.
• Player: Read inventory, armor, level, durability and repair forecasts; configure a local skin preview.
• Statistics · Beta: Read the build/dig counter and current chest stock by item and theme.
• Editor · Beta / Preview: Edit items or level in a new backup copy.

AI TOOLS
• AI export: Generate verified world context as Markdown or JSON for external assistants; optionally include navigation and share through iCloud or AirDrop.
• Conversation · Beta: Use text or the Mac microphone to ask about saved places, owned supplies, recipes and guides.
• Skills: Manage reusable agent instructions and optional personal context.

KNOWLEDGE & HELP
• Videos & tips: Find videos by topic, material and review coverage, then open timestamps.
• Build guides: Offline test builds with materials, steps and test notes.
• Mobs & Animals: A creature reference with sources and explicit uncertainty labels.
• Links & Knowledge: Community links and Minecraft comparison.
• Help: Instructions, setup, troubleshooting, source code and release notes.

CONTROLS
The actions menu (…) contains additional operations for each area. Settings at the bottom left contains Quest setup, Appearance, Exploration & spoilers, Item icons and Language. It also offers quitting or restarting Companion instances; active work must finish first. Report data / bug opens a report draft for you to review.
"""),
    .init(id: "setup", icon: "cable.connector", deTitle: "Einrichtung", enTitle: "Step-by-step setup", de: releaseDocument("SETUP-de"), en: releaseDocument("SETUP-en")),
    .init(id: "manualTransfer", icon: "externaldrive.badge.wifi", deTitle: "Übertragung ohne ADB", enTitle: "Transfer without ADB", de: releaseDocument("TRANSFER-de"), en: releaseDocument("TRANSFER-en")),
    .init(id: "appearance", icon: "paintpalette", deTitle: "Optik, Icons & Spoiler", enTitle: "Appearance, icons & spoilers", de: """
SPRACHE UND OPTIK
Einstellungen unten links enthält „Optik“ mit Blockwelt/Klassisch sowie Deutsch/English. Die Gesprächssprache wird separat im Bereich Gespräch eingestellt. Eigene Weltnamen werden nicht übersetzt.

GEGENSTANDS-ICONS
1. Öffne Einstellungen → Gegenstands-Icons.
2. Wähle Nur Text oder Icons + Text und das gewünschte Grafikpaket.
3. Lies Quelle und Lizenz. „Herunterladen & nutzen“ installiert das Paket nach deiner Aktion; anschließend ist es offline verfügbar.
4. Bereits installierte Pakete lassen sich aktivieren oder entfernen. Nicht zugeordnete Gegenstände behalten ihre Textbezeichnung.

Kenney und Pixel Perfection Legacy sind alternative Grafikpakete, keine automatische Rekonstruktion der Spielgrafik. Ihre Lizenz- und Quellenangaben stehen im Dialog. Die lokale Spieler-Skin-Vorschau wird gesondert im Bereich Spieler eingestellt.

ERKUNDUNG & SPOILER
Über Einstellungen → Erkundung & Spoiler steuerst du den Umgang mit noch nicht entdeckten beziehungsweise vermuteten Kisten. Der spoilerarme Modus gilt für alle Welten: Kisten zeigt nur eigene oder manuell als bekannt markierte Behälter, auch in der Suche. Karten zeigt die Oberflächenhöhe ohne unterirdische Ebenen, Blockabfrage und automatische Fundorte. Bekannte Kisten und eigene Kartenpunkte bleiben verfügbar. Zum Markieren weiterer Entdeckungen den Modus ausschalten.

Gespeicherte Chunks können trotzdem unbekannte Landschaft enthalten; dies ist keine Karte ausschließlich bereits besuchter Gebiete. Roh-JSON und KI-Exporte werden nicht durch diesen Anzeigefilter eingeschränkt.
""", en: """
LANGUAGE AND APPEARANCE
Settings at the bottom left offers Block world/Classic appearance and German/English. Conversation language is configured separately in Conversation. Your own world names are not translated.

ITEM ICONS
1. Open Settings → Item icons.
2. Choose Text only or Icons + text and a graphics pack.
3. Read its source and license. Download & use installs the pack after your action; it then works offline.
4. Installed packs can be activated or removed. Unmapped items retain text labels.

Kenney and Pixel Perfection Legacy are alternative graphics packs, not an automatic reconstruction of game graphics. Their license/source information is in the dialog. The local player skin preview is configured separately in Player.

EXPLORATION AND SPOILERS
Settings → Exploration & spoilers controls handling of undiscovered or suspected chests. Spoiler-light mode applies to all worlds: Chests shows only owned or manually known containers, including searches. Maps shows surface elevation without underground layers, block inspection or automatic places. Known chests and your own pins remain available. Disable the mode to mark additional discoveries.

Saved chunks can still contain unfamiliar terrain; this is not a map limited to visited areas. Raw JSON and AI exports are not restricted by this display filter.
"""),
    .init(id: "library", icon: "archivebox", deTitle: "Savegames & Speicherort", enTitle: "Savegames & storage", de: """
Unter Deine Welt → Savegames sind Sicherungen nach Welt gruppiert; innerhalb einer Welt stehen neuere Sicherungen oben. Wähle einen Eintrag und prüfe Weltname, ID und Datum. Die Suche hilft beim Wiederfinden.

AKTIONEN
Das Menü (…) enthält Umbenennen, Im Finder anzeigen, ZIP-Export, Wiederherstellung sowie weitere Bibliotheksaktionen. „Savegame löschen“ fragt nach und verschiebt den ausgewählten Eintrag in den Mac-Papierkorb. Es löscht keine Welt auf der Quest.

DATUM UND UHRZEIT
Das Sicherungsdatum bezeichnet die Sicherung beziehungsweise den Import. „Letzte Dateiänderung“ zeigt den neuesten Änderungszeitpunkt der Weltdateien. App-eigene ZIPs können das ursprüngliche Sicherungsdatum erhalten; andere Importe verwenden den Importzeitpunkt.

SPEICHERORDNER
Unter Einstellungen → Quest einrichten → Alle Einstellungen kannst du den Speicherordner ändern. Vorhandene Einträge lassen sich mitkopieren und prüfen; der bisherige Ordner bleibt erhalten. Deaktiviere das Kopieren, wenn du eine andere bestehende Library öffnen möchtest.

Standardmäßig liegt die Library unter ~/Library/Application Support/RealmCraftLibrary/Savegames.

PLATZ SPAREN
### Backup- und Speicherstatus
Die Savegame-Details prüfen den tatsächlichen Dateispeicher. „Optimiert“ bedeutet, dass alle Dateien den gemeinsamen Speicherpool nutzen; „Teilweise optimiert“ gilt für einen Teil der Dateien. Klappe die Liste gemeinsam genutzter Dateien auf und klicke einen Spielstand an, um ihn auszuwählen.

Hardlinks erzeugen keine Abhängigkeit von einem anderen Savegame: Jeder vollständige Stand bleibt beim Löschen anderer Stände nutzbar. Eine Editor-Herkunft wird separat angezeigt und ist keine Voraussetzung zum Wiederherstellen. Fehlende Dateien oder symbolische Verknüpfungen führen zu einem unbekannten Status. Diese Prüfung ersetzt keine SHA-256-Inhaltsprüfung.

Der Cloud-Status sucht Library-ZIP-Archive im eingestellten Cloud-Backup-Ordner und vergleicht das Manifest dieses Spielstands. Ein Treffer kann im Finder angezeigt werden. Archivinhalt und Upload beim Anbieter werden dabei nicht erneut geprüft. Kein Treffer bedeutet nur, dass dort kein passendes Library-Archiv gefunden wurde. RealmCraft-/Meta-Online-Spielstände bleiben unbekannt, weil keine Verbindung zu diesen Diensten besteht. Nach Änderungen „Status erneut prüfen“ verwenden.

„Speicher optimieren“ prüft die Sicherungen und legt identische Dateiinhalte nur einmal ab. Die einzelnen Sicherungen behalten ihre normale Ordnerstruktur. Neue Sicherungen können ebenfalls platzsparend gespeichert werden. Das reduziert den lokalen Speicherbedarf, macht den Geräteimport aber nicht automatisch inkrementell oder schneller.

Weltdateien in der Library nicht direkt bearbeiten: Identische Dateien können zwischen Sicherungen geteilt sein. Verwende den Editor für eine getrennte Kopie oder importiere eine separat bearbeitete Welt als neuen Eintrag. Für eine externe Komplettsicherung verwende den Library-Backup-ZIP-Export.
""", en: """
Under Your world → Savegames, backups are grouped by world with newer backups first within each world. Select an entry and check its world name, ID and date. Search helps you find entries.

ACTIONS
The (…) menu contains Rename, Show in Finder, ZIP export, restore and library actions. Delete savegame asks for confirmation and moves the selected entry to the Mac Trash. It does not delete a Quest world.

DATES AND TIMES
The backup date identifies the backup or import. Last file change is the latest modification time among the world files. App-created ZIPs can preserve their original backup date; other imports use the import time.

STORAGE FOLDER
Use Settings → Quest setup → All settings to change the storage folder. Existing entries can be copied and verified; the previous folder remains intact. Disable copying to open a different existing library.

The default location is ~/Library/Application Support/RealmCraftLibrary/Savegames.

SAVE DISK SPACE
### Backup & storage status
Savegame details inspect actual file storage. Optimized means every file uses the shared storage pool; Partially optimized applies to some files. Expand the shared-files list and click a snapshot to select it.

Hard links do not create dependencies on another savegame: each complete snapshot survives deletion of other snapshots. Editor provenance is shown separately and is not required for restoration. Missing files or symbolic links produce an unavailable status. This inspection does not replace SHA-256 content verification.

Cloud status searches library ZIP archives in the configured cloud backup folder and compares this snapshot's manifest. Reveal a match in Finder. Archive contents and provider upload are not reverified by this check. No match only means no matching library archive was found there. RealmCraft / Meta online saves remain unknown because Companion does not connect to those services. Use Check status again after changes.

Optimize storage verifies backups and stores identical file contents only once while retaining each backup's normal folder structure. New backups can also use this deduplicated storage. It reduces local disk use but does not automatically make device imports incremental or faster.

Do not edit world files directly inside the library: identical files may be shared across backups. Use the editor to create a separate copy or import a separately modified world as a new entry. Use the full-library ZIP export for an external archive.
"""),
    .init(id: "backup", icon: "arrow.down.to.line", deTitle: "Vom Gerät sichern", enTitle: "Backup from device", de: """
1. Speichere deinen Fortschritt in RealmCraft.
2. Beende das Spiel vollständig.
3. Prüfe unter Savegames → (…) → Gerät & Welt das ausgewählte Gerät und die Welt-ID.
4. Klicke „Vom Gerät sichern“ und lasse die Quest verbunden.
5. Warte auf „Gesichert und geprüft“. Der neue Eintrag wird ausgewählt.

Die App vergleicht die Dateien per SHA-256 auf Quest und Mac. Außerdem prüft sie, ob sich die Quest-Dateien während der Sicherung geändert haben. Unvollständige Sicherungen werden nicht als fertiger Library-Eintrag angezeigt.

SPIEL VOM MAC BEENDEN
Savegames → (…) → Gerät & Welt → RealmCraft auf Quest beenden führt „am force-stop“ aus. Er beendet RealmCraft sofort und löst KEIN Speichern aus. Speichere zuerst im Spiel, damit kein ungespeicherter Fortschritt verloren geht. Die App fragt vor dem Beenden nach.

Während einer Übertragung sind weitere Aktionen gesperrt. Das normale Beenden der Mac-App wird während einer laufenden Übertragung verhindert.
""", en: """
1. Save your progress in RealmCraft.
2. Fully close the game.
3. Check the selected headset and world ID under Savegames → (…) → Device & world.
4. Click “Backup from device” and keep the Quest connected.
5. Wait for “Backed up and verified”. The new entry is selected.

The app compares SHA-256 file checksums on the Quest and Mac. It also checks whether the Quest files changed during the backup. Incomplete backups do not appear as completed library entries.

CLOSE THE GAME FROM YOUR MAC
Savegames → (…) → Device & world → Close RealmCraft on Quest runs “am force-stop”. It closes RealmCraft immediately and does NOT save the game. Save in the game first to avoid losing unsaved progress. The app asks for confirmation before stopping it.

Other actions are disabled during a transfer. Normal quitting of the Mac app is blocked while a transfer is in progress.
"""),
    .init(id: "restore", icon: "arrow.up.to.line", deTitle: "Mac → Quest laden", enTitle: "Restore Mac → Quest", de: """
1. Speichere und beende RealmCraft.
2. Wähle in der linken Liste den gewünschten Spielstand aus.
3. Kontrolliere Datum, Uhrzeit, Welt-ID und Zielgerät.
4. Wähle im Aktionsmenü (…) „Auf Quest wiederherstellen“ und bestätige „Sichern & wiederherstellen“.
5. Starte das Spiel erst nach der Erfolgsmeldung.

Vor dem Ersetzen wird die aktuelle Zielwelt automatisch auf dem Mac gesichert. Diesen Eintrag erkennst du an „Auto“ und „Vor Wiederherstellung“. Anschließend wird der gewählte Stand in einen separaten Quest-Ordner übertragen und geprüft. Erst danach wird er aktiviert.

Die Welt-ID des gewählten Library-Eintrags bestimmt die Zielwelt. Die Welt-Auswahl unter „Gerät & Welt“ gilt für neue Sicherungen. Andere Quest-Welten werden nicht ersetzt.

ZUSÄTZLICHE RÜCKFALLKOPIE
Die vorherige Welt bleibt außerdem auf der Quest außerhalb der aktiven Welten unter files/.library-previous-<UUID> erhalten. Das belegt zusätzlichen Speicher. Fehlgeschlagene Übertragungen können .library-stage-<UUID> hinterlassen. Die App löscht diese Ordner nicht automatisch.

Bei einem USB-Abbruch oder einer unbestätigten Aktivierung: Spiel geschlossen lassen, Verbindung wiederherstellen und die Fehlermeldung beachten. Die automatische Sicherung in der Library kann erneut wiederhergestellt werden. Das Ende der Übertragung wurde dann nicht sicher bestätigt.
""", en: """
1. Save and close RealmCraft.
2. Select the backup you want in the left-hand list.
3. Check its date, time, world ID and the target device.
4. Choose “Restore to Quest” in the actions menu (…), then confirm “Back up & restore”.
5. Only start the game after the success message.

Before replacing an existing target world, the app automatically backs it up to your Mac. This entry is marked “Auto” and “Before restore”. The selected backup is then uploaded to a separate folder on the Quest and verified before activation.

The selected library entry's world ID determines which world is restored. The Device & world selector is used when creating new backups. Other Quest worlds are not replaced.

EXTRA RECOVERY COPY
The previous world also remains on the Quest outside the active worlds directory, under files/.library-previous-<UUID>. This uses extra storage. Failed transfers can leave .library-stage-<UUID> folders. The app does not remove these folders automatically.

If USB disconnects or activation cannot be confirmed: keep the game closed, reconnect and follow the error message. You can restore the automatic library backup again. Completion of the interrupted transfer has not been confirmed.
"""),
    .init(id: "zip", icon: "doc.zipper", deTitle: "ZIP & Weitergeben", enTitle: "ZIP & sharing", de: """
EINZELNEN SPIELSTAND EXPORTIEREN
Wähle unter Savegames eine Sicherung und dann (…) → ZIP exportieren. Der Export prüft die Weltdateien und enthält die vollständige Welt mit Library-Metadaten und Prüfsummen.

SPIELSTAND IMPORTIEREN
Über (…) → Spielstand importieren wählst du einen Weltordner mit seiner ursprünglichen numerischen Welt-ID oder ein ZIP mit genau einer solchen Welt. world_data und player_data müssen enthalten sein. Unsichere Archivpfade und symbolische Verknüpfungen werden abgewiesen.

Unter Quest einrichten → Alle Einstellungen kannst du außerdem einen Backup-Ordner nach importierbaren ZIPs und Weltordnern durchsuchen lassen.

GESAMTE LIBRARY SICHERN
1. Öffne (…) → Library-Backup-ZIP exportieren.
2. Wähle einen externen Datenträger oder einen anderen Zielordner.
3. Warte auf die Bestätigung. Die enthaltenen Sicherungen werden für den Export geprüft.

Für wiederholte Exporte wähle zuerst „Cloud-Backup-Ordner festlegen“ und danach „Library in Cloud-Ordner sichern“. Jeder Aufruf erstellt ein eigenes Archiv mit Zeitstempel. Der Companion startet keine automatische Sicherungsplanung. Die Synchronisierung eines iCloud-/Cloud-Ordners übernimmt der jeweilige Dienst.

Ein vollständiges Library-Archiv ist kein einzelnes Welt-ZIP. Für die Rückübernahme einer bestimmten Welt das Archiv separat entpacken und deren Weltordner importieren; ein geführter Komplett-Restore ist noch nicht enthalten.

DIE APP WEITERGEBEN
Teile die App, nicht deine persönlichen Spielstände. Auf dem anderen Mac lassen sich ADB und Kartenwerkzeuge in der Einrichtung installieren. Die App ist lokal signiert, aber nicht von Apple notarisiert; beachte bei Startproblemen die verlinkte Apple-Anleitung.
""", en: """
EXPORT ONE SAVEGAME
Select a backup in Savegames, then (…) → Export ZIP. Export verifies the world files and includes the complete world, library metadata and checksums.

IMPORT A SAVEGAME
Use (…) → Import savegame to select a world folder named with its original numeric world ID, or a ZIP containing exactly one such world. world_data and player_data must be present. Unsafe archive paths and symbolic links are rejected.

Quest setup → All settings can also search a selected backup folder for importable ZIPs and world folders.

BACK UP THE ENTIRE LIBRARY
1. Open (…) → Export library backup ZIP.
2. Choose an external disk or another destination folder.
3. Wait for confirmation. Included backups are verified for export.

For repeated exports, choose Set cloud backup folder, then Back up library to cloud folder. Each invocation creates a separate timestamped archive. Companion does not schedule automatic backups. iCloud or another cloud provider handles synchronization of its folder.

A full-library archive is not a single-world ZIP. To recover a particular world, extract the archive separately and import that world's folder; guided full-library restoration is not yet included.

SHARE THE APP
Share the app rather than your personal saves. ADB and map tools can be installed through setup on the other Mac. The app is locally signed but not Apple-notarized; consult the linked Apple guide if macOS blocks launch.
"""),
    .init(id: "maps", icon: "map", deTitle: "Karten erstellen", enTitle: "Create maps", de: """
1. Sichere deine Welt im Bereich „Savegames“ oder importiere eine vorhandene Sicherung. Für Karten brauchst du keine angeschlossene Quest.
2. Öffne „Karten“ und wähle den Spielstand anhand von Name, Datum und Uhrzeit.
3. Klicke bei fehlenden Werkzeugen auf „Kartenwerkzeuge installieren“. Die App lädt eine eigene Python-Laufzeit von Astral/GitHub sowie NumPy und Pillow von PyPI herunter, prüft den Python-Download und testet die Werkzeuge. Dafür ist Internet nötig, aber weder ein Administratorpasswort noch eine vorherige Python-Installation. Du findest denselben Button auch unter Einstellungen → Quest einrichten. Vorhandene Python-Installationen bleiben unverändert.
4. Starte mit „Ursprung ±128 Blöcke“. Weitere Bereiche sind ±256, ±512, ±1024, ±2048 oder „Alle gespeicherten Chunks“. Große Welten benötigen mehr Zeit und freien Speicher.
5. Klicke „Karte erzeugen“. Die Sicherung wird vor und nach der Berechnung auf Integrität geprüft. Die Karte wird separat unter Library/Application Support/RealmCraftLibrary/Maps gespeichert.
6. Kompass anklicken: 90° drehen, mit Umschalt rückwärts. Rechtsklick auf den Kompass richtet nach Norden aus. Option/Alt + Scrollen dreht in 90°-Schritten. Ausrichtung und Spiegelung werden für die Karte gemerkt. Bei fokussierter Karte drehen Q/E; R setzt die Richtung zurück.
7. Ziehe die Karte zum Verschieben, scrolle zum Zoomen oder suche X-/Z-Koordinaten. Wechsle zwischen Landschaft, Höhenkarte, Oberfläche und einzelnen Y-Ebenen. Nether erscheint nur, wenn gespeicherte Daten vorhanden sind.
8. „Im Browser öffnen“ zeigt die Karte im Standardbrowser. „Im Finder anzeigen“ im Aktionsmenü zeigt den Kartenordner; teile bei Bedarf den gesamten Kartenordner, da Bilder und Kartendaten dazugehören. Für den JSON-Export markierter Orte verwende die Browseransicht.

ATLAS-VORSCHAU
Dieser Kartenbereich integriert einen eigenständigen Stand des parallelen Realmcraft-Atlas-Projekts. Er liest gespeicherte Chunks und verwendet schematische Farben. Es ist keine Live-Karte und keine exakte Nachbildung der Spielgrafik. Unbekannte Blöcke und beschädigte Chunks werden gekennzeichnet. Die zuletzt erzeugte Karte wird je Sicherung, Bereich und Sprache wieder geöffnet. Erneutes Erzeugen legt einen neuen Kartenordner an. Nicht benötigte Karten kannst du im Finder entfernen; Savegames liegen separat.

Routen, Messungen und die Weitergabe an einen Agenten beschreibt „Wegeplanung & Navigation · Beta“.

3D · BETA
Der 3D-Button öffnet die experimentelle räumliche Ansicht. Bei einem ausgewählten Ort kannst du „Hier in 3D · Beta“ verwenden. Auch diese Darstellung basiert nur auf den gespeicherten, verarbeiteten Chunks; unbekannte Blöcke oder fehlende Daten können abweichen.

EIGENE KISTEN MARKIEREN
Öffne die Bereichsauswahl für Kistenbesitz, ziehe ein Rechteck auf der Karte und prüfe die angezeigte Anzahl. Markiere die enthaltenen Kisten als eigene oder entferne ihre Besitzmarkierung. Die Auswahl gilt in der aktuellen Dimension über alle Höhen hinweg, auch für aktuell ausgefilterte Kisten. Grüne Ringe zeigen eigene Kisten.

Das Rechteck reserviert kein dauerhaftes Gebiet. Neue Kisten später erneut markieren. Die Zuordnung ist eine lokale Angabe für Gespräch und KI-Export und verändert keine Spielwelt.

""", en: """
1. Back up your world in Savegames or import an existing backup. A connected Quest is not required for maps.
2. Open Maps and choose a savegame by name, date and time.
3. If tools are missing, click Install map tools. The app downloads its own Python runtime from Astral/GitHub and NumPy and Pillow from PyPI, verifies the Python download and tests the tools. Internet is required, but no administrator password or existing Python installation. The same button is available under Settings → Quest setup. Existing Python installations are unchanged.
4. Start with Origin ±128 blocks. Larger choices are ±256, ±512, ±1024, ±2048 and All saved chunks. Large worlds need more time and free disk space.
5. Click Generate map. The backup is checked for integrity before and after rendering. Maps are stored separately under Library/Application Support/RealmCraftLibrary/Maps.
6. Click the compass to rotate 90°, or Shift-click to reverse. Right-click the compass to face north. Option/Alt + scroll rotates in 90° steps. The map remembers orientation and mirroring. With the map focused, Q/E rotate and R resets north.
7. Drag to pan, scroll to zoom or search X/Z coordinates. Switch between terrain, height map, surface and individual Y levels. Nether appears only when saved data is available.
8. Open in browser uses your default browser. Show in Finder in the actions menu reveals the map folder; share the complete map folder because its images and data are required. Use the browser view to export marked places as JSON.

ATLAS PREVIEW
This feature integrates an independent snapshot of the parallel Realmcraft Atlas project. It reads saved chunks and uses schematic colors. It is not a live map or an exact reproduction of game graphics. Unknown blocks and damaged chunks are identified. The last map is reopened for each savegame, area and language. Generating again creates a new map folder. Remove unneeded maps in Finder; savegames are stored separately.

See Route planning & navigation · Beta for measurements, route candidates and agent handoff.

3D · BETA
The 3D button opens the experimental spatial view. For a selected place, use Here in 3D · Beta. This also uses only saved, processed chunks; unknown blocks or missing data can differ.

MARK OWNED CHESTS
Open the chest-ownership area selector, drag a rectangle on the map and review the count. Mark the included chests as owned or remove ownership. Selection applies across all heights in the current dimension, including chests hidden by marker filters. Green rings show owned chests.

The rectangle is not a permanent claim area. Mark new chests again later. Ownership is a local annotation for Conversation and AI export, not a game-world change.

"""),
    .init(id: "navigation", icon: "point.topleft.down.curvedto.point.bottomright.up", deTitle: "Wegeplanung & Navigation · Beta", enTitle: "Route planning & navigation · Beta", de: """
In Karten planst du anhand gespeicherter Oberflächen einen Routenvorschlag. Ein Agent kann die exportierten Hinweise vorlesen; der Companion verfolgt deine Position im Spiel nicht.

ROUTE PLANEN
1. Erzeuge die Karte einer Sicherung. Öffne Messen und setze Start A und Ziel B.
2. Prüfe Entfernung und Oberflächenprofil. Die Messlinie ist noch kein begehbarer Weg.
3. Öffne Navigation & KI-Export. Wähle Nur zu Fuß, Zu Fuß + Boot oder Zu Fuß + Boot + Minecart. Aktiviere bei Bedarf POIs in der Nähe · 250 Blöcke.
4. Klicke Englische Navigation planen. Die Suche verwendet gespeicherte Oberflächen, Höhenwechsel und modellierte Fahrtzeiten. Fehlende Abschnitte werden nicht als sichere Verbindung ergänzt.
5. Prüfe den Vorschlag im Spiel. Boote und Loren müssen verfügbar sein; Schienenanschlüsse, Antrieb, Türen, Tunnel und Durchgangshöhen sind nicht verifiziert. Zwischenziele und automatische Rundreise-Optimierung sind noch nicht vorhanden.

WEITERGEBEN
Navigation kopieren überträgt das vollständige Briefing in die Zwischenablage. Navigation als Markdown speichern erzeugt eine Datei. In iCloud speichern verwendet einen eigenen, gemerkten Navigationsordner; unter Einstellungen → Kartenexport oder im Karten-Aktionsmenü lässt er sich wählen. Jeder Export erhält eine neue Datei. Ein abgebrochener Ordnerdialog verwirft die Route nicht.

Für KI-Export übernehmen hinterlegt den Vorschlag für diese Sicherung. Wähle anschließend denselben Spielstand unter KI-Export, aktiviere Englische Navigation beifügen · Beta und erzeuge den Kontext erneut. Die lokale Qwen-Auswahl ist optional und markiert nur vorhandene Referenzen; sie erfindet keine Route.

MIT EINEM SPRACHAGENTEN
Das englische Briefing bestätigt zuerst Ziel, Dimension, aktuelle X/Y/Z-Koordinaten und Blickrichtung. Gesprochene Abschnitte zielen auf etwa 75 Wegblöcke, normalerweise 50–100; kritische Bereiche werden kürzer zusammengefasst. Alle genauen Wendungen und Koordinaten bleiben als Referenz erhalten. Bestätige das Abschnittsende, bevor der Agent fortfährt. Der Endpunkt ist keine Erlaubnis für eine gerade Abkürzung durch das Gelände.

POIs sind optionale Orientierungspunkte im horizontalen Umkreis von 250 Blöcken um einen Routenschritt, keine bestätigten Zwischenziele. Bei Hindernissen, abweichenden Koordinaten oder geändertem Ziel anhalten und neu planen. Laufzeit ist keine Positionsmessung.

Siehe auch „Karten erstellen“, „KI-Export“ und „Skills verwalten“.
""", en: """
In Maps, plan a route candidate from saved surfaces. An agent can read the exported instructions; Companion does not track your position in the game.

PLAN A ROUTE
1. Generate the map for a backup. Open Measure and set start A and destination B.
2. Inspect distance and surface profile. The measurement line is not yet a walkable route.
3. Open Navigation & AI export. Choose Walking only, Walk + boat or Walk + boat + minecart. Optionally enable Nearby POIs · 250 blocks.
4. Click Plan English navigation. The search uses saved surfaces, elevation changes and modeled travel time. Missing sections are not filled in as safe connections.
5. Check the candidate in-game. Boats and minecarts must be available; rail connectivity, power, doors, tunnels and clearance are unverified. Intermediate waypoints and automatic round-trip optimization are not implemented.

SHARE
Copy navigation puts the complete briefing on the clipboard. Save navigation Markdown creates a file. Save to iCloud uses a separate remembered navigation folder; choose it under Settings → Map export or in the Maps actions menu. Every export creates a new file. Cancelling the folder picker does not discard the route.

Use in AI export stores the candidate for this backup. Select the same savegame in AI export, enable Include English navigation · Beta and generate context again. Local Qwen cue selection is optional and highlights supplied references only; it does not invent a route.

WITH A VOICE AGENT
The English briefing first confirms destination, dimension, current X/Y/Z coordinates and facing. Spoken sections target about 75 route blocks, normally 50–100; critical areas are grouped into shorter sections. Exact turns and coordinates remain available as references. Confirm section arrival before the agent continues. A section endpoint is not permission to cut straight across terrain.

POIs are optional orientation cues within 250 horizontal blocks of a route step, not verified intermediate destinations. Stop and replan when obstacles, coordinates or the destination differ. Elapsed time is not a position measurement.

See also Create maps, AI export and Manage skills.
"""),
    .init(id: "places", icon: "mappin.and.ellipse", deTitle: "Orte finden & benennen", enTitle: "Find & name places", de: """
1. Erzeuge im Bereich „Karten“ eine neue Karte. Die Suche bezieht sich auf den dafür gewählten Bereich; für die ganze gespeicherte Welt wähle „Alle gespeicherten Chunks“.
2. Scrolle in der Karten-Seitenleiste zu „Interessante Orte“.
3. Wähle mögliche Gebäude, Kisten, Betten, Glasgruppen, Werkbänke oder Öfen. „Markierungen anzeigen“ schaltet die Punkte ein und aus.
4. Mit ← und → springst du zum vorherigen/nächsten Fund. Am Ende beginnt die Auswahl wieder von vorne. Alternativ klicke einen Punkt direkt an.
5. Gib dem ausgewählten Ort einen Namen, etwa „Lager zu Hause“, und klicke „Namen speichern“. Ein leer gespeicherter Name setzt die automatische Bezeichnung zurück.

SCHILDER ALS MARKIERUNGEN
Setze und beschrifte im Spiel ein Schild, beispielsweise „Hauptlager“, „Mine“ oder „Farm“. Speichere die Welt, sichere sie und erzeuge die Karte für diese Sicherung neu. Im Kartenbereich „Schilder“ kannst du die Markierungen einschalten, nach Schildtext oder Koordinaten suchen und mit den Pfeilen zwischen Treffern wechseln. Das Schild braucht keinen besonderen Namenszusatz. Schilder werden auf allen Höhen berücksichtigt; nicht lesbare Beschriftungen bleiben als Schildposition erkennbar. Der spoilerarme Modus blendet die Schildsuche aus.

Ein Schild kann zugleich benachbarte Kisten als Player-Kisten kennzeichnen (30 Blöcke horizontal, höchstens 10 Höhenblöcke; danach „Kisten einlesen“). In der App gesetzte Kartenpunkte und benannte Orte sind separate Markierungen: Sie erzeugen kein Schild im Spiel und lösen diese Schild-Regel nicht aus.

Eigene Ortsnamen bleiben in der App für dieselbe Welt gespeichert, auch nach dem Schließen, Sprachwechsel oder erneuten Erzeugen einer Karte. Im externen Browser werden sie separat im jeweiligen Browserspeicher abgelegt.

Gebäude sind Vermutungen: Mindestens zwei Arten von Hinweisen innerhalb eines Rasterbereichs von 32 × 32 × 16 Blöcken ergeben einen Vorschlag. Ein Gebäudekomplex kann mehrere Vorschläge haben; Höhlen, Ruinen oder Lagerplätze können ebenfalls als Vorschlag erscheinen. Die App erkennt damit keine Hausgrenzen oder Besitzverhältnisse. Glas wird gruppiert, damit einzelne Scheiben die Karte nicht überladen. Kistenmarkierungen zeigen die Position; den Inhalt findest du im Bereich „Kisten“.

SCHILDTEXTE
Aktiviere Schilder in den Kartenebenen, um lesbare Beschriftungen direkt zu sehen. Suchfilter, Dimension und Spoiler-Einstellungen gelten weiterhin. Ein Klick öffnet die vollständige Inschrift und Koordinaten. Benachbarte, eindeutig zuordenbare Schildtexte können Kisten benennen; manuelle Namen bleiben vorrangig.
""", en: """
1. Generate a new map in Maps. Detection covers the selected area; choose All saved chunks to cover the stored world.
2. Scroll the map sidebar to Interesting places.
3. Choose possible buildings, chests, beds, glass groups, crafting tables or furnaces. Show markers toggles the overlay.
4. Use ← and → to jump to the previous/next place, wrapping around at the end. You can also click a marker directly.
5. Enter a name such as Home storage and click Save name. Saving an empty name restores the automatic label.

SIGNS AS MARKERS
Place and label a sign in the game, for example Home storage, Mine or Farm. Save the world, back it up and generate the map for that backup again. In the map's Signs section, enable markers, search inscriptions or coordinates and use the arrows to move between results. No special text prefix is required. Signs at all heights are included; an unreadable inscription still retains its sign location. Spoiler-light mode hides sign search.

A sign also identifies nearby chests as player-owned (30 blocks horizontally, at most 10 vertically; then run Read chests). App-created map pins and named places are separate annotations: they do not create a sign in the game and do not trigger the sign rule.

The app remembers custom names for the same world after closing, switching language or generating another map. An external browser stores names separately in its own browser storage.

Buildings are suggestions: at least two indicator categories within a 32 × 32 × 16 block grid area produce a suggestion. Large complexes may have several suggestions; caves, ruins or storage areas may also qualify. This does not detect house boundaries or ownership. Glass is grouped to avoid clutter from individual panes. Chest markers show the location; use Chests to inspect contents.

SIGN TEXT
Enable Signs in the map layers to show readable labels immediately. Search, dimension and spoiler filters still apply. Click for the full inscription and coordinates. Unambiguous nearby sign text can name chests; manual names take precedence.
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
    .init(id: "chests", icon: "shippingbox", deTitle: "Kisten & Gegenstandssuche", enTitle: "Chests & item search", de: """
Kisten durchsucht einen lokalen Spielstand. Für aktuelle Bestände zuerst eine neue Sicherung erstellen; die Ansicht ist keine Live-Abfrage der Quest.

EINLESEN UND SUCHEN
1. Wähle eine Sicherung und klicke „Kisten einlesen“. Fehlende Kartenwerkzeuge lassen sich per Button installieren.
2. Suche nach deutschen oder englischen Gegenstandsnamen, IDs oder wähle Materialien aus. Bei mehreren Materialien bestimmt die Kombination, ob alle oder eines davon passen müssen.
3. Wähle einen Lagerort und darin eine Kiste. Nahe Kisten werden zu Lagerorten zusammengefasst. Rechts siehst du Slots, Mengen und Koordinaten.
4. Nutze das Sortiermenü für passende Mengen auf- oder absteigend. „Ab ausgewählter Kiste messen“ setzt eine feste Bezugskiste für die Entfernungssortierung.

Entfernungen sind räumliche Luftlinien innerhalb derselben Dimension, keine Laufwege. Die Bezugskiste bleibt fest, bis du eine andere festlegst. Unbekannte Mengen und nicht vergleichbare Entfernungen stehen hinten.

BESITZ UND SICHTBARKEIT
Im Kistenmenü kannst du „Gehört mir“, „Bereits entdeckt“ und Ein-/Ausblenden setzen. Eine eigene Kiste kann einen Namen erhalten. Filter für Dimension, Kistengruppe, Sichtbarkeit und vermutete Dungeon-Kisten helfen beim Erkunden. Eine Vermutung ist kein gesicherter Nachweis der Herkunft.

Kistennamen von Schildern: Ein lesbares, nicht leeres Schild direkt neben, über oder unter einer Kiste liefert automatisch ihren Namen. Es zählen nur die sechs unmittelbar angrenzenden Blockpositionen, keine diagonalen oder weiter entfernten Schilder. Leerzeilen werden zusammengefasst; widersprüchliche benachbarte Beschriftungen bleiben ohne automatische Zuordnung. Eigene Namen haben Vorrang, Koordinaten bleiben sichtbar. Nach Änderungen „Kisten einlesen“ bzw. die Karte neu erstellen. Mehrere Kisten am Lagerort behalten ihre individuellen Namen.

Du kannst Besitz selbst markieren. Zusätzlich markiert „Kisten einlesen“ Behälter automatisch als eigene, wenn ein decodiertes Schild in derselben Dimension höchstens 30 Blöcke horizontal und 10 Höhenblöcke entfernt ist. Die Nähe zu einem Schild ist ein Hinweis, kein sicherer Besitznachweis. Prüfe die Markierungen und korrigiere sie bei Bedarf. Beim nächsten Einlesen kann die Schild-Regel eine entfernte Markierung erneut setzen. Eigene Kisten liefern Vorräte für Gespräch und KI-Export. Ausgeblendete Kisten sind nicht gelöscht; der vollständige KI-Export kann sie weiterhin enthalten.

„Koordinaten kopieren“ hilft beim Wiederfinden in Karten. Das Aktionsmenü exportiert die eingelesene Übersicht als JSON. Lesefehler und unvollständige Bestände bleiben gekennzeichnet.
""", en: """
Chests searches a local backup. Create a new backup for current quantities; this view is not a live Quest query.

READ AND SEARCH
1. Select a backup and click Read chests. Missing map tools can be installed with a button.
2. Search German or English item names, IDs, or select materials. For multiple materials, choose whether all or any must match.
3. Select a storage location and a chest within it. Nearby chests are grouped into locations. The detail shows slots, quantities and coordinates.
4. Use sorting for ascending or descending matching quantities. Measure from selected chest sets a fixed reference chest for distance sorting.

Distances are 3D straight lines within the same dimension, not walking routes. The reference stays fixed until you choose another chest. Unknown quantities and incomparable distances sort last.

OWNERSHIP AND VISIBILITY
The chest menu offers Belongs to me, Already discovered and show/hide. An owned chest can have a name. Dimension, chest-group, visibility and suspected-dungeon filters help exploration. A suspicion is not proof of origin.

Chest names from signs: A readable, non-empty sign directly beside, above or below a chest supplies its name. Only the six face-adjacent block positions count, excluding diagonal or more distant signs. Whitespace is collapsed; conflicting adjacent inscriptions receive no automatic name. Manual names take precedence and coordinates remain visible. Run Read chests or rebuild the map after changes. Chests at a shared storage location keep their individual names.

You can mark ownership manually. Read chests also marks containers as owned when a decoded sign in the same dimension lies within 30 horizontal blocks and 10 vertical blocks. Sign proximity is a clue, not proof of ownership. Review and correct marks as needed; the sign rule may reapply a removed mark on the next scan. Owned chests supply stock data for Conversation and AI export. Hidden chests are not deleted and may still appear in a complete AI export.

Copy coordinates helps locate a chest in Maps. The actions menu exports the scanned overview as JSON. Read failures and incomplete stock remain explicitly labeled.
"""),
    .init(id: "player", icon: "person.crop.rectangle", deTitle: "Spieler & Inventar", enTitle: "Player & inventory", de: """
Unter Deine Welt → Spieler wählst du „Quest“ für den zuletzt gespeicherten Gerätestand oder „Sicherung“ für eine lokale Sicherung. Speichere zuvor im Spiel und klicke „Spieler auslesen“ beziehungsweise „Aktualisieren“.

INVENTAR UND ZUSTAND
Angezeigt werden Level, Inventarslots mit Mengen und IDs sowie die Rüstung. Die Suche berücksichtigt deutsche und englische Namen, IDs und Verzauberungen. Unbekannte IDs bleiben sichtbar; nicht unterstützte Daten werden nicht als leeres Inventar ausgegeben.

Haltbarkeit wird für unterstützte Werkzeuge, Waffen und Rüstung als Restwert und Balken angezeigt. Orange kennzeichnet weniger als 50 %, Rot weniger als 20 %. Unbekannte oder abweichende Maximalwerte bleiben gekennzeichnet.

REPARATURPROGNOSE
Die Prognose nennt für volle Haltbarkeit eine Materialmenge oder ein gleichartiges Ersatzstück mit benötigter Resthaltbarkeit. Amboss und Erfahrung werden als Voraussetzungen genannt. Nicht berechnete Levelkosten und ungesicherte Materialzuordnungen werden ausdrücklich ausgewiesen. Prüfe das Ergebnis im Spiel; die Vorschau führt keine Reparatur durch.

SKIN-VORSCHAU
„Skin“ öffnet die lokale Charakterauswahl mit dreh- und zoombarer 3D-Vorschau. Wähle Modell, Körper, Shirt, Hose und Hände und bestätige „Übernehmen“. „Abbrechen“ verwirft die Auswahl. Die Einstellung verändert keine Quest-Datei und rekonstruiert nicht automatisch deinen tatsächlichen Spiel-Skin. Rüstungsfarben sind angenähert.

DATENSTAND
Quest-Dateien werden zweimal gelesen und verglichen. „Ausgelesen“ ist der Abfragezeitpunkt, nicht der Speicherzeitpunkt im Spiel. Nicht gespeicherte Änderungen fehlen. Bei einem fehlgeschlagenen Aktualisieren bleibt der ältere Stand mit Hinweis sichtbar. Lokale Abfragen prüfen die Spielerdatei; Wiederherstellung und Export prüfen weiterhin die gesamte Welt. Über (…) kannst du JSON exportieren.

Die Spieleransicht arbeitet nativ und benötigt weder Python noch einen KI-Dienst.
""", en: """
Under Your world → Player, choose Quest for the device's last saved state or Backup for a local backup. Save in the game first, then click Read player or Refresh.

INVENTORY AND CONDITION
The view shows level, inventory slots with quantities and IDs, and armor. Search includes German/English names, IDs and enchantments. Unknown IDs remain visible; unsupported data is not presented as an empty inventory.

Supported tools, weapons and armor show remaining durability and a condition bar. Orange indicates less than 50%; red indicates less than 20%. Unknown or differing maximum values remain labeled.

REPAIR FORECAST
The forecast lists a material quantity or an identical replacement item with the required remaining durability to reach full condition. An anvil and experience are prerequisites. Uncalculated level costs and uncertain material assignments are explicit. Check the result in the game; the preview does not perform a repair.

SKIN PREVIEW
Skin opens the local character selector with a rotatable, zoomable 3D preview. Choose model, body, shirt, pants and hands, then Apply. Cancel discards the edits. This does not change Quest files or automatically reconstruct your actual in-game skin. Armor colors are approximate.

DATA TIMING
Quest files are read twice and compared. Read time is the query time, not the in-game save time. Unsaved changes are absent. A failed refresh retains the older result with a notice. Local queries verify the player file; restore and export still verify the full world. Use (…) to export JSON.

The Player view is native and needs neither Python nor an AI service.
"""),
    .init(id: "statistics", icon: "chart.bar.xaxis", deTitle: "Statistiken · Beta", enTitle: "Statistics · Beta", de: """
1. Öffne Deine Welt → Statistiken · Beta.
2. Wähle eine lokale Sicherung anhand von Welt und Datum.
3. Klicke „Statistik auslesen“.

Die Anzeige liest den gespeicherten gemeinsamen Zähler für Bau- und Abbauaktionen. Sowohl Bauen als auch Abbauen erhöht diesen Wert. Er ist keine reine Abbaumenge und kann nicht nach Material oder Spieler aufgeteilt werden.

Für neuere Aktivitäten zuerst eine neue Sicherung erstellen. Geprüft werden das relevante world_data und seine Zuordnung zur Welt. Nicht unterstützte Formate oder beschädigte Daten erzeugen einen sichtbaren Fehler.

TRUHENBESTÄNDE · BETA
1. Klicke im Abschnitt „Truhenbestände“ auf „Truhen auslesen“. Die Kartenwerkzeuge müssen eingerichtet sein; siehe „Karten erstellen“. Ein bereits unter Kisten gelesener Index wird wiederverwendet. Der Scan prüft die Sicherung vor und nach dem Lesen.
2. Suche nach deutschem/englischem Itemnamen oder ID. Filtere nach Dimension, Thema und Items in vermutlichen Spielertruhen.
3. Sortiere nach Anzahl aller Truhen, Spieler-Anzahl, Itemname oder ID, auf- oder absteigend. Die Sortierung gilt innerhalb der Themen; deaktiviere „Nach Thema gruppieren“ für eine gemeinsame Rangliste.

Die Spalten zeigen Stückzahlen und die Anzahl der Truhen, die das Item enthalten. Spielertruhen sind eine Teilmenge aller Truhen, keine zusätzliche Menge. Die vermutliche Zuordnung übernimmt Eigentumsmarkierungen und automatisch über nahe Schilder erkannte Truhen aus Kisten. Thematische Gruppen sind Companion-Zuordnungen, keine ausgelesenen Spielkategorien. Unbekannte Items bleiben mit ihrer ID unter „Sonstiges / nicht zugeordnet“ sichtbar.

Alle Truhen schließt ausgeblendete und generierte Truhen ein. Im spoilerarmen Modus werden nur bekannte Truhen gezählt. Dimensionsfilter ändern die Truhenabdeckung; Suche und Itemfilter ändern die angezeigten Bestandsummen. Unlesbare Inhalte fehlen in den Summen, Scanprobleme kennzeichnen ein Teilergebnis. Diese Bestände sind eine Momentaufnahme der gewählten Sicherung.

Historische Summen zu einzelnen Ressourcen, getöteten Kreaturen, Laufstrecke, Todesfällen und Crafting sind derzeit nicht zuverlässig auslesbar. Fehlende Werte bedeuten nicht null. Das persönliche Inventar findest du unter Spieler.
""", en: """
1. Open Your world → Statistics · Beta.
2. Select a local backup by world and date.
3. Click Read statistics.

This reads the saved combined build/dig action counter. Both building and digging increase it. It is not a mined-block total and cannot be split by material or player.

Create a new backup for newer activity. The relevant world_data and its world identity are checked. Unsupported formats or damaged data produce a visible error.

CHEST CONTENTS · BETA
1. Click Read chests in Chest contents. Map tools must be set up; see Create maps. An index already read in Chests is reused. The scan verifies the backup before and after reading.
2. Search by English/German item name or ID. Filter by dimension, theme and items in presumed player chests.
3. Sort by all-chest quantity, player quantity, item name or ID, ascending or descending. Sorting applies within themes; disable Group by theme for a global ranking.

Columns show quantities and the number of chests containing each item. Player chests are a subset of all chests, not an additional quantity. Presumed ownership reuses ownership marks and automatic assignments from nearby signs in Chests. Themes are Companion assignments, not saved game categories. Unknown items remain visible by ID under Other / unclassified.

All chests includes hidden and generated chests. Spoiler-light mode counts only known chests. The dimension filter changes chest coverage; search and item filters change displayed stock totals. Unreadable contents are missing from totals and scan issues indicate a partial result. These quantities describe the selected backup snapshot.

Historical totals for individual resources, creature kills, distance, deaths and crafting are not currently readable reliably. Missing values do not mean zero. See Player for personal inventory.
"""),
    .init(id: "editor", icon: "slider.horizontal.3", deTitle: "Editor · Beta / Preview", enTitle: "Editor · Beta / Preview", de: """
Der Editor ist eine experimentelle Beta/Preview. Änderungen können einen Spielstand unbrauchbar machen. Bewahre vor Tests eine unabhängige, rückspielbare Sicherung auf.

KOPIE BEARBEITEN
1. Wähle unter Deine Welt → Editor eine lokale Sicherung.
2. Wähle „Gegenstände“ oder „Spielerlevel“. Für Slot-Änderungen müssen die Kartenwerkzeuge bereit sein; Kisten bei Bedarf einlesen.
3. Wähle links Rucksack oder Kiste und einen belegten Slot. Du kannst unterstützte Gegenstände duplizieren, verschieben, ihre Menge ändern oder sortieren. Für Verschieben/Duplizieren einen leeren Zielslot wählen. Zusatzdaten können mitkopiert werden.
4. Prüfe die Zusammenfassung über „Änderung prüfen“. Erst nach Risikobestätigung erstellt „Kopie speichern“ einen neuen Library-Spielstand.

Der ursprüngliche Eintrag bleibt erhalten. Geteilte Dateien platzsparender Sicherungen werden für Editor-Kopien vor Änderungen getrennt. Nicht unterstützte Daten und ungültige Eingaben können eine Aktion verhindern.

OPTIONALER QUEST-TEST
„Quest-Test“ → „Separate Quest-Testwelt vorbereiten“ erstellt eine Testkopie mit neuer Welt-ID. Die eigentliche Geräteübertragung wird danach separat bestätigt. Speichere und beende RealmCraft vorher und prüfe Gerät, Quelle und Testwelt-ID genau.

Ob die neue Welt in RealmCraft erscheint, lädt und dauerhaft speichert, ist nicht garantiert. Teste eine kleine Änderung, Speichern und erneutes Laden. Die normale Wiederherstellung ersetzt dagegen die Welt mit der passenden ID; sie ist kein Ersatz für den getrennten Beta-Testweg.
""", en: """
The editor is an experimental beta/preview. Changes may make a save unusable. Keep an independent, restorable backup before testing.

EDIT A COPY
1. Select a local backup under Your world → Editor.
2. Choose Items or Player level. Slot edits need ready map tools; read chests if needed.
3. Select backpack or chest on the left and an occupied slot. Supported items can be duplicated, moved, quantity-edited or sorted. Choose an empty destination for moving/duplicating. Additional item data can be copied too.
4. Use Review change to inspect the summary. Only after risk confirmation does Save copy create a new library entry.

The original entry is preserved. Shared files in deduplicated backups are separated before editing a copy. Unsupported data and invalid inputs can prevent an action.

OPTIONAL QUEST TEST
Quest test → Prepare separate Quest test world creates a test copy with a new world ID. Device transfer is confirmed separately afterwards. Save and close RealmCraft first, and carefully check the device, source and test world ID.

Appearance in RealmCraft, successful loading and continued saving are not guaranteed. Test a small change, save and reload. Normal restore instead replaces the matching world ID; it is not a substitute for the separate beta test workflow.
"""),
    .init(id: "aiExport", icon: "doc.text.magnifyingglass", deTitle: "KI-Export", enTitle: "AI export", de: """
Unter KI-Werkzeuge → KI-Export erzeugst du aus einer geprüften Sicherung einen lesbaren Weltkontext für einen externen Assistenten.

KONTEXT ERZEUGEN
1. Wähle die gewünschte Sicherung.
2. Entscheide, ob alle gespeicherten Kisten mit Inhalten einbezogen werden sollen. Dafür werden die Kartenwerkzeuge benötigt. Der Export liest auch Kisten, die ein Ansichtsfilter ausblendet.
3. Klicke „Kontext erzeugen“ und prüfe Vorschau, Größe und Hinweise zu fehlenden Daten.
4. Speichere Markdown oder JSON. Beide enthalten denselben Kontext; Listen werden nicht still gekürzt.

Je nach lesbaren Daten enthält der Export Weltname und Seed, Inventar, Rüstung, Level, Verzauberungen, Haltbarkeit, Reparaturprognosen, Respawn, benannte Orte, Kisten und Besitzmarkierungen. Ressourcen im Inventar, eigenen Kisten und Behältern mit unbekanntem Besitz werden getrennt ausgewiesen. Referenzwissen, Baupläne und lokale Checklisten sind kein Nachweis, dass diese Bauten oder Mobs in deiner Welt existieren.

WEITERGEBEN
„In iCloud speichern“ schreibt jeweils eine neue vollständige Markdown-Datei in den gewählten, gemerkten Ordner. macOS übernimmt die Synchronisierung. „Per AirDrop senden“ öffnet die native Freigabe. Prüfe Weltname, Koordinaten und Bestände, bevor du die Datei weitergibst.

Der Companion sendet den Kontext nicht automatisch an einen KI-Dienst. Der Export ist ein Daten- und Wissensauszug, keine rückspielbare Savegame-Sicherung.

OPTIONALE INHALTE
Wähle bei Bedarf einen Skill und entscheide separat über persönlichen Kontext. Ausgewählte Videohinweise lassen sich einbeziehen oder als zweite Markdown-Datei speichern. Große kombinierte Videonotizen werden automatisch ausgelagert, nicht abgeschnitten. Die Bildschirmvorschau zeigt nur einen Anfang des vollständigen Dokuments. Nach geänderten Optionen Kontext erneut erzeugen.

NAVIGATION
Übernimm zuerst einen Routenvorschlag aus Karten und aktiviere Englische Navigation beifügen · Beta für dieselbe Sicherung. Der Export enthält das Agenten-Briefing, gesprochene Abschnitte, genaue Schritte und optional POIs. Siehe „Wegeplanung & Navigation · Beta“.
""", en: """
Under AI tools → AI export, generate readable world context from a verified backup for an external assistant.

GENERATE CONTEXT
1. Select the desired backup.
2. Choose whether to include all saved chests and their contents. This needs map tools. Export also scans chests hidden by view filters.
3. Click Generate context and review the preview, size and missing-data notices.
4. Save Markdown or JSON. Both contain the same context; lists are not silently truncated.

Depending on readable data, export includes world name and seed, inventory, armor, level, enchantments, durability, repair forecasts, respawn, named places, chests and ownership marks. Inventory, owned-chest stock and containers with unknown ownership are reported separately. Reference knowledge, build plans and local checklists do not prove those builds or mobs exist in your world.

SHARE
Save to iCloud writes a new complete Markdown file to the selected, remembered folder each time. macOS handles synchronization. Send via AirDrop opens native sharing. Review world names, coordinates and stock before sharing.

Companion does not automatically send context to an AI service. This is a data/knowledge extract, not a restorable savegame backup.

OPTIONAL CONTENT
Choose a skill if wanted and decide separately whether to include personal context. Selected video notes can be included or saved as a second Markdown file. Large combined video notes are moved to a separate file, not truncated. The on-screen preview shows only the beginning of the complete document. Regenerate context after changing options.

NAVIGATION
First hand off a candidate from Maps, then enable Include English navigation · Beta for the same backup. Export includes the agent briefing, spoken sections, detailed steps and optional POIs. See Route planning & navigation · Beta.
"""),
    .init(id: "conversation", icon: "bubble.left.and.bubble.right", deTitle: "Gespräch · Beta", enTitle: "Conversation · Beta", de: """
Gespräch · Beta beantwortet Fragen zu den gespeicherten Daten der ausgewählten Welt sowie zu enthaltenen Rezept- und Anleitungshinweisen. Es ist keine Live-Verbindung zum Spiel und keine Navigation im Headset.

BEGINNEN
1. Wähle eine Sicherung. Benenne gewünschte Orte vorher in Karten.
2. Für Vorratsfragen öffne „Mehr“ → „Eigene Kisten“, lies die Kisten ein und prüfe die durch Schilder erkannten Markierungen und wähle nur Behälter, die dir gehören. Die Auswahl gilt für den jeweiligen Weltkontext und die Koordinate.
3. Tippe eine Frage und klicke „Senden“, zum Beispiel „Wo ist mein Zuhause?“ oder eine Materialfrage. Nachfragen können Koordinaten oder weitere Details liefern.

SPRACHE UND MIKROFON
In den Gesprächseinstellungen wählst du die Sprache für Erkennung und Antworten getrennt von der Oberfläche. „Mac-Mikrofon einstellen“ öffnet die Mac-Einstellungen; das Quest-Mikrofon wird nicht automatisch verwendet. Mikrofon und Spracherkennung benötigen gegebenenfalls macOS-Freigaben beziehungsweise Sprachdateien.

„Erkannten Text vor dem Senden prüfen“ und „Nach einer Sprechpause automatisch senden“ steuern die Übergabe. Bei Automatik löst eine Pause von 2,5 Sekunden das Senden aus. Für längere Fragen Automatik ausschalten und „Jetzt antworten“ verwenden. Gesprächsmodus hört nach einer Antwort erneut zu. „Stopp“ oder Escape beendet Aufnahme und Ausgabe.

FRAGEN VERSTEHEN
„Einfache Suche“ benötigt kein zusätzliches Sprachmodell. Apple Intelligence ist optional und nur bei passender System-/Geräteunterstützung verfügbar. Für Qwen über LM Studio muss das lokale Modell separat eingerichtet und der Server gestartet werden; nutze die integrierte Anleitung und „Verbindung prüfen“. Der Companion verbindet sich dafür ausschließlich mit 127.0.0.1:1234. Die Kartenwerkzeuge installieren dieses Modell nicht.

Materialprüfungen vergleichen die Zutaten einer Ausführung der enthaltenen Referenzrezepte mit markierten eigenen Kisten. Spielerinventar, Zwischenprodukte und Werkstationen werden dabei nicht mitgerechnet. Rezeptangaben sind als ungeprüfte Minecraft-Referenzen gekennzeichnet. Erkennung und Antworten können falsch sein; Datum, Datenlücken und Quellenhinweise beachten.
""", en: """
Conversation · Beta answers questions about saved data from the selected world and included recipe/guide references. It is not a live game connection or headset navigation.

GET STARTED
1. Select a backup. Name places in Maps first if needed.
2. For stock questions, open More → My chests, scan chests, review sign-derived ownership and select only containers you own. Selection is stored for the corresponding world context and coordinate.
3. Type a question and click Send, for example “Where is my home?” or a material question. Follow-ups can provide coordinates or details.

SPEECH AND MICROPHONE
Conversation settings select recognition/answer language separately from the interface. Mac microphone settings opens system settings; the Quest microphone is not used automatically. Microphone and speech recognition may require macOS permission or language assets.

Review recognized text before sending and Send automatically after a pause control submission. Automatic sending triggers after a 2.5-second pause. Disable it for longer questions and use Answer now. Conversation mode listens again after answering. Stop or Escape ends recording and speech.

QUESTION UNDERSTANDING
Basic lookup needs no additional language model. Apple Intelligence is optional and requires compatible system/device support. Qwen through LM Studio needs a separately configured model and running local server; use the in-app setup guide and Check connection. Companion connects only to 127.0.0.1:1234 for this. Map tools do not install that model.

Material checks compare ingredients for one execution of included reference recipes with marked owned chests. Player inventory, intermediate products and workstations are excluded. Recipes are labeled as unverified Minecraft references. Recognition and answers can be wrong; check dates, data gaps and source notes.
"""),
    .init(id: "skills", icon: "text.book.closed", deTitle: "Skills verwalten", enTitle: "Manage skills", de: """
Öffne Skills in der Navigation unter KI-Werkzeuge. Die zentrale Bibliothek enthält wiederverwendbare Anweisungen für Weltassistenz, Spielstand-Arbeit, Hilfe und Companion-Entwicklung.

BEARBEITEN UND VERSIONIEREN
Mit „Neuer Skill“ legst du eigene Anweisungen an. „Bearbeiten / Umbenennen“ ändert Titel, Beschreibung, Anweisungen und eigene Ergänzungen. Jede Speicherung eines bestehenden Skills bewahrt den vorherigen Stand in der Versionshistorie. Dort kannst du einen Stand ansehen und als neue Version wiederherstellen. Archivieren blendet einen Skill aus der aktiven Auswahl aus; Löschen entfernt auch seine lokale Historie.

IMPORT UND EXPORT
Das obere Aktionsmenü (…) importiert Markdown oder ein Skill-Paket und exportiert die gesamte Bibliothek. Im Aktionsmenü eines Skills kannst du SKILL.md oder ein Paket mit Versionen exportieren und den Skill duplizieren. Pakete enthalten Skill-Ergänzungen und Historie, aber kein persönliches Profil. Bei gleichen IDs entstehen Importkopien; bestehende Skills bleiben erhalten. Markdown importiert die Textanweisung, keine Versionshistorie. Importierte Anweisungen werden nicht ausgeführt.

SPRACHEN UND LOKALE ÜBERSETZUNG
Mitgelieferte Skills enthalten Deutsch und Englisch; die Ansicht folgt der App-Sprache. Im Editor wechselst du zwischen den Fassungen. Das Exportmenü bietet Deutsch, Englisch oder beide Sprachen in einer Markdown-Datei; JSON-Pakete enthalten alle vorhandenen Fassungen und deren Historie.

„Aus anderer Sprache mit lokalem Qwen übersetzen“ erstellt einen Entwurf aus der anderen Fassung. Starte dafür LM Studio mit Qwen3.5-4B und dem lokalen Server auf Port 1234. Bei langen Skills kann eine größere Kontextgröße nötig sein; maximal 18 KB Text werden angenommen. Der Entwurf ersetzt den sichtbaren Editorinhalt. Prüfe Bedeutung, Zahlen und Befehle vor dem Speichern. Abbrechen oder Modellfehler bewahren den bisherigen Text. Ohne lokalen Server bleibt manuelles Übersetzen möglich; es gibt keinen Cloud-Fallback.

MIT AGENTEN VERWENDEN
„Für KI-Export verwenden“ wählt den Skill im KI-Export aus. Alternativ Markdown kopieren oder SKILL.md an einen Agenten übergeben. Die automatische Erkennung hängt vom Agenten ab. Entwicklungsskills können ohne Weltexport verwendet werden. Persönliche Angaben werden im KI-Export separat und freiwillig beigefügt.
""", en: """
Open Skills under AI tools in the navigation. The central library contains reusable instructions for world assistance, savegame work, help maintenance and Companion development.

EDIT AND VERSION
New skill creates your own instructions. Edit / Rename changes the title, description, instructions and additions. Each save of an existing skill preserves its previous state in Version history. Inspect an earlier state and restore it as a new version. Archiving removes a skill from active selection; deleting also removes its local history.

IMPORT AND EXPORT
The top actions menu (…) imports Markdown or a skill package and exports the entire library. Each skill's actions menu exports SKILL.md or a package with versions and duplicates the skill. Packages include skill notes and history but exclude the personal profile. Matching IDs create import copies and preserve existing skills. Markdown imports instructions without history. Importing instructions does not execute them.

LANGUAGES AND LOCAL TRANSLATION
Bundled skills include German and English; the view follows the app language. Switch language versions in the editor. Export German, English or both in one Markdown document; JSON packages contain all available languages and their history.

Translate from other language with local Qwen creates a draft from the other version. Start LM Studio with Qwen3.5-4B and its local server on port 1234. Long skills may need a larger context; inputs up to 18 KB are accepted. The result replaces the visible editor draft. Check meaning, numbers and commands before saving. Cancellation or a model error preserves the existing text. Manual translation remains available without a server; there is no cloud fallback.

USE WITH AGENTS
Use for AI export selects the skill in AI export. Alternatively, copy Markdown or pass SKILL.md to an agent. Automatic recognition depends on the agent. Development skills work without a world export. Personal context is a separate opt-in in AI export.
"""),
    .init(id: "videos", icon: "play.rectangle", deTitle: "Videos & Tipps", enTitle: "Videos & tips", de: """
Unter Wissen & Hilfe → Videos & Tipps findest du den lokalen Videokatalog mit deutschen und englischen Suchhilfen.

SUCHEN UND ÖFFNEN
1. Suche nach Thema, Material oder Titel und wähle bei Bedarf eine Themenkategorie.
2. Filtere nach Inhalt beziehungsweise Bearbeitungsstand. Ein Video kann ausgearbeitete Hinweise, rein visuelle Notizen, einen Transkript-Suchindex oder noch keine Auswertung enthalten.
3. Wähle einen Treffer und öffne den passenden Schritt oder Zeitlink auf YouTube. Bei vielen Treffern lassen sich weitere Suchstellen anzeigen.

QUELLEN RICHTIG LESEN
Ausgearbeitete Hinweise sind redaktionelle Zusammenfassungen. Rein visuelle Beiträge wurden nur anhand von Bildstichproben ausgewertet. Transkript-Indizes enthalten Suchbegriffe und ungefähre Zeitfenster, keine vollständig geprüften Bauanleitungen. „Noch nicht ausgewertet“ bedeutet nicht, dass das Video keine passenden Inhalte hat.

PCVR, Quest und andere Spielversionen können abweichen. Eine Videoauswertung ist kein eigener Funktionstest in deiner Welt. Beachte die jeweilige Quellen- und Abdeckungsangabe.

VORLESEN UND INTERNET
Bei vorhandenen Zusammenfassungen kannst du die Vorlesesprache wählen und den Text oder einzelne Schritte mit einer Mac-Systemstimme anhören. „Stopp“ beendet die Ausgabe. Dies ist keine synchrone Übersetzung der Originaltonspur.

Der Katalog ist lokal verfügbar. Beim Anzeigen können offizielle YouTube-Vorschaubilder aus dem Internet geladen werden; dies startet keine Videowiedergabe. Onlinevideos werden erst durch deine Wiedergabe-/Linkaktion geöffnet. Es gibt keinen automatischen Video-Download oder laufenden Hintergrundimport.

SORTIEREN UND EXPORTIEREN
Sortiere nach Upload-Datum, Originaltitel, Kanal oder Dauer; Zurücksetzen stellt die neueste Veröffentlichung zuerst wieder her. „Video als Markdown exportieren“ gibt die vorhandenen Hinweise mit Quellen und Zeitmarken aus. „Dieses Video in den KI-Gesamtexport aufnehmen“ wählt den Beitrag für einen anschließend neu erzeugten KI-Export aus.
""", en: """
Knowledge & help → Videos & tips contains the local video catalog with German and English search aids.

SEARCH AND OPEN
1. Search a topic, material or title and optionally choose a topic category.
2. Filter by content or review coverage. A video may contain authored notes, visual-only notes, a transcript search index or no review yet.
3. Select a match and open its step or timestamp on YouTube. More matching locations can be shown when there are many results.

READ COVERAGE LABELS
Authored notes are edited summaries. Visual-only contributions were reviewed through image samples. Transcript indexes contain search terms and approximate time windows, not fully verified build instructions. Pending review does not mean the video lacks relevant content.

PCVR, Quest and other game versions can differ. A video review is not an independent functionality test in your world. Check each source and coverage note.

READING AND INTERNET
Available summaries or individual steps can be read with a Mac system voice in the chosen language. Stop ends speech. This is not a synchronized translation of the original audio track.

The catalog is available locally. Browsing can load official YouTube thumbnail images from the internet; this does not start video playback. Videos open only through your playback/link action. There is no automatic video downloader or ongoing background import.

SORT AND EXPORT
Sort by upload date, original title, channel or duration; Reset restores newest uploads first. Export video as Markdown saves the available notes with sources and timestamps. Include this video in the overall AI export selects it for the next generated AI context.
"""),
    .init(id: "builds", icon: "square.grid.3x3", deTitle: "Bauanleitungen & Blockpläne", enTitle: "Build guides & block plans", de: """
Unter Wissen & Hilfe → Bauanleitungen findest du Offline-Testaufbauten, unter anderem für Lagerung, Farmen, Türen, Lore-Schaltungen und HQ-Verteidigung. Die angezeigte Sammlung bestimmt die verfügbaren Anleitungen; eine feste Zahl wird hier nicht vorausgesetzt.

SCHRITT FÜR SCHRITT
1. Suche nach Aufbau oder Material beziehungsweise wähle eine Kategorie.
2. Lies Materialliste, Voraussetzungen und Quellenstatus. Die Einkaufsliste lässt sich kopieren; gesammelte Materialien kannst du abhaken.
3. Wähle Bauschritt und Ansicht/Ebene. Die Diagramme zeigen den jeweiligen Aufbauzustand. Ein großes Rasterfeld entspricht einem Block; feine Linien sind Zeichenhilfen.
4. Klicke ein Blockfeld für Bezeichnung und Platzierungsdetails. x läuft links nach rechts, z in Draufsichten hinten nach vorne und y bezeichnet die Höhe. Koordinaten sind relativ zum Aufbau.
5. Führe die angegebenen Zwischen- und Rücksetztests aus. Notiere Ergebnis, Spielversion und Beobachtungen im Testprotokoll.

Checklisten und Testnotizen werden lokal pro Anleitung gespeichert. Sie sind keine automatisch ermittelten Vorräte einer Welt.

STATUS DER PLÄNE
Viele Pläne sind KI-generierte, noch nicht in RealmCraft VR geprüfte Übertragungen. Türen, Loren, Fallen und Farmen können je nach Spielmechanik abweichen. Beachte die Hinweise zu Mob-Verhalten, Spielerwegen und Tests mit leeren beziehungsweise besetzten Loren. Ein gezeichneter Plan ist kein Nachweis seiner Funktion.

Die eigene Video-Sammlung findest du unter „Videos & Tipps“. Sie kennzeichnet Quellen, Zeitmarken und Auswertungsumfang getrennt von diesen Offline-Plänen.

2D, 3D UND MATERIALIEN
Materialien, Darstellung & Iconpacks, Audioguide, Gesamtpläne, Testdetails und Quellen lassen sich ein- und ausklappen. Unter Bauvorschau wechselst du zwischen 2D und 3D; beide folgen demselben Bauschritt. Drehen, Neigen, Zoom und Zurücksetzen steuern die zentrierte 3D-Kamera. Normales Seitenscrollen verändert sie nicht. Ein Höhenschnitt hilft beim Prüfen innerer Ebenen.

Darstellung & Iconpacks bietet Symbole oder Block-Icons mit optionalen Grafikpaketen. Unbekannte Zuordnungen bleiben schematisch. Generische Vollblöcke verwenden eine Bruchstein-Referenz; geeignetes anderes Vollblockmaterial ist möglich, sofern der Plan nichts anderes verlangt. Frühe Teilmodelle sind ausdrücklich als unvollständige Schichtvorschau gekennzeichnet. Eine 3D-Darstellung simuliert keine Spielmechanik.

AUDIOGUIDE
Öffne Audioguide für einen Sprachagenten. Kopiere den Auftrag oder speichere ihn als Text und übergib ihn dem gewünschten Agenten. Materialliste, Schritte und Grenzen begleiten den Auftrag. Kein Agent wird automatisch gestartet.
""", en: """
Knowledge & help → Build guides contains offline test builds, including storage, farms, doors, minecart circuits and HQ defense. The loaded collection determines the available guides; no fixed count is assumed here.

STEP BY STEP
1. Search a build or material, or select a category.
2. Read materials, prerequisites and source status. Copy the shopping list and check off collected materials.
3. Select a step and view/layer. Diagrams show that stage of construction. A large grid cell is one block; fine lines are drawing aids.
4. Click a cell for its name and placement details. x runs left to right, z runs back to front in top views and y is height. Coordinates are relative to the build.
5. Perform the stated intermediate/reset tests. Record your result, game version and observations in the test log.

Checklists and test notes are saved locally per guide. They are not automatically measured world inventories.

PLAN STATUS
Many plans are AI-generated adaptations not yet tested in RealmCraft VR. Doors, minecarts, traps and farms may differ with game mechanics. Follow notes about mob behavior, player bypasses and empty/occupied-cart tests. A diagram is not proof that a build works.

The separate Videos & tips library labels sources, timestamps and review coverage independently from these offline plans.

2D, 3D AND MATERIALS
Materials, Display & icon packs, audio guide, complete plans, test details and sources can be expanded or collapsed. Build preview switches between 2D and 3D; both follow the same construction step. Rotate, tilt, zoom and reset controls operate the centered 3D camera. Normal page scrolling does not change it. A height cutaway helps inspect inner layers.

Display & icon packs offers Symbols or Block icons using optional graphics packs. Unmapped items remain schematic. Generic full blocks use a cobblestone reference; other suitable full blocks are allowed unless the guide requires a particular material. Early partial models explicitly identify incomplete slice previews. A 3D rendering does not simulate game mechanics.

AUDIO GUIDE
Open Audio guide for a voice agent. Copy the prompt or save it as text and give it to your chosen agent. Materials, steps and limitations accompany the instructions. No agent is started automatically.
"""),
    .init(id: "mobs", icon: "pawprint", deTitle: "Mobs & Animals", enTitle: "Mobs & Animals", de: """
Wissen & Hilfe → Mobs & Animals ist ein lokales Kreaturenregister, kein Scan deiner Welt.

Suche nach Namen oder beschriebenen Eigenschaften und verwende Kategorie- beziehungsweise Statusfilter. Varianten stehen bei ihrem Grundnamen. Die Detailansicht nennt Quellen, Dimensionen und Biome, soweit diese belegt sind.

BELEGE UND UNSICHERHEIT
Hinweise aus VR-Veröffentlichungen, dem allgemeinen RealmCraft-Wiki und Minecraft-Vergleichen werden getrennt gekennzeichnet. Babyformen und andere Referenzen können unbestätigt sein. Ein Eintrag bedeutet weder, dass die Kreatur sicher in deiner Spielversion vorhanden ist, noch dass sie in deiner Welt entdeckt wurde.

BILDER
Im Darstellungsmenü des Registers beziehungsweise im macOS-Menü „Darstellung“ kannst du Mob-Bilder ein- oder ausschalten. Fehlende Modelle bleiben als Platzhalter sichtbar; bei Babyformen kann ausdrücklich ein erwachsenes Referenzbild gezeigt werden.

Die Inhalte sind als KI-generiert gekennzeichnet. Bei Fehlern verwende die Meldemöglichkeit am Eintrag oder „Daten / Bug melden“ und ergänze nachvollziehbare Beobachtungen.
""", en: """
Knowledge & help → Mobs & Animals is a local creature reference, not a scan of your world.

Search names or described properties and use category/status filters. Variants appear under their base names. Details list sources, dimensions and biomes where established.

EVIDENCE AND UNCERTAINTY
VR release information, the general RealmCraft wiki and Minecraft comparisons are labeled separately. Baby forms and other references may remain unconfirmed. An entry does not prove that a creature exists in your game version or has been discovered in your world.

PICTURES
Toggle mob pictures in the register's Appearance menu or macOS View menu. Missing models retain placeholders; baby entries may explicitly show an adult reference image.

Content is labeled as AI-generated. Report mistakes through the entry-specific action or Report data / bug and include reproducible observations.
"""),
    .init(id: "resources", icon: "globe", deTitle: "Links & Wissen", enTitle: "Links & Knowledge", de: """
Unter Wissen & Hilfe → Links & Wissen findest du die Website, YouTube, Store-Seiten, Community und das Wiki zu RealmCraft.

1. Wähle den gewünschten Bereich. Die Suche filtert die Einträge in diesem Bereich.
2. Unter „Minecraft-Vergleich“ findest du Informationen zu Blöcken, Gegenständen, Mobs und Spielmechaniken sowie Unterschiede mit Quellenlinks.
3. Öffne einen Link, um die jeweilige Quelle im Browser zu lesen. „Quelle“ zeigt den Ursprung eines Verweises.

Das allgemeine RealmCraft-Wiki ist nicht speziell für die VR-Version; Inhalte können abweichen. Für externe Links benötigst du Internet.
""", en: """
Knowledge & help → Links & Knowledge contains the RealmCraft website, YouTube, store pages, community and wiki.

1. Select a section. Search filters the entries in that section.
2. Minecraft comparison covers blocks, items, mobs, game mechanics and differences with source links.
3. Open a link to read its source in your browser. Source identifies where a reference comes from.

The general RealmCraft wiki is not specific to the VR version; content may differ. External links require internet.
"""),
    .init(id: "trouble", icon: "wrench.and.screwdriver", deTitle: "Probleme lösen", enTitle: "Troubleshooting", de: """
KEINE QUEST GEFUNDEN
Quest aufwecken, USB-Kabel neu verbinden und einen anderen USB-Anschluss oder ein Datenkabel versuchen. Entwicklermodus prüfen. Der Verbindungsbutton startet die Suche sofort.

USB NICHT AUTORISIERT
Setze das Headset auf und bestätige die USB-Debugging-Abfrage. Danach erneut prüfen. Die reine Freigabe für Dateiübertragung ist nicht dasselbe wie USB-Debugging.

REALMCRAFT ODER WELT FEHLT
Prüfe das ausgewählte Gerät. Installiere RealmCraft auf der Quest und starte es einmal. Lege eine Welt an, speichere und beende das Spiel. Welten benötigen world_data und player_data.

DAS SPIEL LÄUFT NOCH
Speichere im Spiel und beende es vollständig. Alternativ kannst du nach dem Speichern Savegames → (…) → Gerät & Welt → RealmCraft auf Quest beenden verwenden.

DATEIEN STIMMEN NICHT ÜBEREIN
Lasse das Spiel während der Übertragung geschlossen. Übertrage erneut. Eine manuell veränderte Library-Kopie muss als neuer Weltordner importiert werden, damit neue Prüfsummen entstehen.

SPEICHER VOLL / ZUGRIFF VERWEIGERT
Prüfe freien Speicher auf Mac und Quest sowie Schreibrechte für den Library-Ordner. In macOS unter Datenschutz & Sicherheit → Dateien und Ordner den Zugriff prüfen. Wähle bei Bedarf einen anderen Speicherordner.

DOWNLOAD FEHLGESCHLAGEN
Internetverbindung prüfen und erneut versuchen. Alternativ Platform Tools von Google herunterladen und die adb-Datei über „Vorhandenes ADB auswählen“ angeben.

Für Unterstützung kannst du in der Einrichtung „Diagnose kopieren“ verwenden. Prüfe den Text vor dem Weitergeben; Fehlermeldungen können lokale Dateipfade enthalten.

KARTENWERKZEUGE
Bei fehlender oder beschädigter Python-Umgebung „Kartenwerkzeuge installieren“ beziehungsweise „neu installieren“ verwenden. Internet und freien Speicher prüfen. Eine vorhandene Installation bleibt bei einem fehlgeschlagenen Versuch erhalten.

GESPRÄCH UND EXPORTE
Bei fehlendem Mikrofonpegel den Mac-Eingang und die macOS-Freigaben prüfen. Bei Qwen-Verbindungsfehlern LM Studio, geladenes Modell und lokalen Server prüfen oder „Einfache Suche“ wählen. Leere Vorratsauskünfte können an einer alten Sicherung, nicht eingelesenen Kisten oder fehlenden Besitzmarkierungen liegen.

VIDEO- UND REFERENZINHALTE
Ein Transkriptindex oder eine visuelle Notiz ist keine vollständig geprüfte Anleitung. Fehler über „Daten / Bug melden“ mit Quelle und Beobachtung melden.

""", en: """
NO QUEST FOUND
Wake the headset, reconnect USB and try another port or a data cable. Check developer mode. The connection refresh button starts a scan immediately.

USB UNAUTHORIZED
Put on the headset and accept the USB debugging prompt, then check again. Permission for file transfer alone is not the same as USB debugging.

GAME OR WORLD MISSING
Check the selected device. Install and launch RealmCraft on the Quest. Create a world, save and close the game. Worlds must contain world_data and player_data.

GAME STILL RUNNING
Save in the game and close it fully. After saving, use Savegames → (…) → Device & world → Close RealmCraft on Quest.

FILES DO NOT MATCH
Keep the game closed throughout the transfer and try again. A manually modified library copy must be imported as a new world folder to create new checksums.

DISK FULL / PERMISSION DENIED
Check free storage on both Mac and Quest and write access to your library folder. Review macOS Privacy & Security → Files and Folders permissions. Select another library location if needed.

DOWNLOAD FAILED
Check your internet connection and retry. You can also download Platform Tools from Google and use “Select existing ADB” to choose the adb file.

Use “Copy diagnostics” in Setup when requesting support. Review the text before sharing it; error messages may contain local file paths.

MAP TOOLS
For a missing or damaged Python environment, use Install map tools or Reinstall map tools. Check internet access and free storage. A failed attempt preserves an existing installation.

CONVERSATION AND EXPORTS
For missing microphone input, check the Mac input and macOS permissions. For Qwen connection failures, check LM Studio, the loaded model and local server, or select Basic lookup. Missing stock answers may result from an old backup, unscanned chests or absent ownership marks.

VIDEO AND REFERENCE CONTENT
A transcript index or visual note is not a fully verified guide. Use Report data / bug with the source and your observations.

"""),
    .init(id: "feedback", icon: "flag", deTitle: "Daten & Bugs melden", enTitle: "Report data & bugs", de: """
„Daten / Bug melden“ unten links oder die Meldung an einem Wissenseintrag öffnet einen Berichtsentwurf.

1. Wähle die Art der Meldung und beschreibe das Problem möglichst konkret.
2. Ergänze Schritte zum Nachstellen sowie erwartetes und tatsächliches Verhalten. Prüfe die automatisch angezeigten App-Angaben.
3. Optional kannst du bis zu fünf Screenshots hinzufügen oder ausdrücklich das App-Fenster aufnehmen.
4. Prüfe die Vorschau. Kopiere den Text, exportiere ein ZIP oder öffne einen Mail-Entwurf mit Anhängen.

Das ZIP enthält report.hjson und ausgewählte Bilder. Der Empfänger des Mail-Entwurfs wird von dir gewählt; die App sendet keine Nachricht automatisch.

Automatische Metadaten enthalten keine Spielstände, Weltnamen, Geräte-IDs oder lokalen Quellpfade. Freitext und Screenshots können solche Angaben trotzdem enthalten: Prüfe sie vor der Weitergabe. Eine Bugmeldung ist keine Savegame-Sicherung.
""", en: """
Report data / bug at the bottom left, or a reference entry's report action, opens a draft.

1. Select the report type and describe the issue concretely.
2. Add reproduction steps and expected/actual behavior. Review the automatically displayed app information.
3. Optionally add up to five screenshots or explicitly capture the app window.
4. Review the preview, then copy the text, export a ZIP or open a mail draft with attachments.

The ZIP contains report.hjson and selected images. You choose the mail recipient; the app does not send messages automatically.

Automatic metadata excludes savegames, world names, device IDs and local source paths. Free text and screenshots can still contain such information, so review them before sharing. A bug report is not a savegame backup.
"""),
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
    .init(id: "privacy", icon: "hand.raised", deTitle: "Datenschutz & Links", enTitle: "Privacy & links", de: """
LOKALE DATEN
Spielstände bleiben im gewählten Library-Ordner und auf deiner Quest. Der Companion enthält keine Telemetrie und lädt Spielstände nicht automatisch hoch. Karten, Kistenmarkierungen, Checklisten, Skin-Auswahl und Testnotizen werden lokal verarbeitet beziehungsweise gespeichert.

OPTIONALE VERBINDUNGEN
• ADB kommuniziert mit dem verbundenen Gerät. Die Installation lädt Platform Tools von Google.
• Kartenwerkzeuge laden Python von Astral/GitHub sowie NumPy und Pillow von PyPI.
• Optionale Grafikpakete werden von den im jeweiligen Dialog angegebenen Quellen heruntergeladen.
• Externe Quellenlinks und YouTube-Zeitmarken öffnen auf deine Aktion Onlineinhalte.
• Spracherkennung arbeitet lokal, soweit auf dem Mac unterstützt; Sprachdateien können nachgeladen werden. Die Qwen-Anbindung verwendet den lokalen LM-Studio-Server. Dessen Einrichtung erfolgt separat.

BEWUSST WEITERGEBEN
Library-Archive und KI-Exporte in Cloud-Ordnern können durch den jeweiligen Dienst synchronisiert werden. AirDrop und Mail-Entwürfe sind ausdrückliche Freigabewege. Prüfe Exporte, Freitext und Screenshots auf persönliche Angaben, Weltkoordinaten und Bestände.

Die Quest verwaltet die USB-Debugging-Freigabe; du kannst sie im Headset widerrufen. Mikrofon- und Spracherkennungsrechte verwaltet macOS.

RealmCraft Companion ist eine unabhängige Community-App und kein offizielles Produkt von Meta, Google oder Tellurion Mobile. Spiel und Marken gehören ihren Rechteinhabern.
""", en: """
LOCAL DATA
Savegames remain in your selected library folder and on your Quest. Companion contains no telemetry and does not automatically upload savegames. Maps, chest annotations, checklists, skin choices and test notes are processed or stored locally.

OPTIONAL CONNECTIONS
• ADB communicates with the connected device. Installation downloads Google's Platform Tools.
• Map setup downloads Python from Astral/GitHub and NumPy and Pillow from PyPI.
• Optional graphics packs download from the sources shown in their dialogs.
• External source links and YouTube timestamps open online content after your action.
• Speech recognition runs locally where supported by the Mac; language assets may need downloading. Qwen integration uses a local LM Studio server, configured separately.

EXPLICIT SHARING
Library archives and AI exports in cloud folders may be synchronized by that provider. AirDrop and mail drafts are explicit sharing paths. Review exports, free text and screenshots for personal information, world coordinates and stock.

Quest manages USB debugging authorization, which you can revoke in the headset. macOS manages microphone and speech-recognition permissions.

RealmCraft Companion is an independent community app, not an official product of Meta, Google or Tellurion Mobile. The game and trademarks belong to their respective owners.
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
    .init(id: "windows", icon: "desktopcomputer", deTitle: "Windows-Version", enTitle: "Windows version", de: """
Derzeit gibt es keine Windows-Version des RealmCraft Companion. Die verfügbare App wurde für macOS entwickelt.

PORTIERUNG BEI INTERESSE
Eine Umsetzung für Windows dürfte grundsätzlich möglich sein. Ein Coding-Agent kann dabei helfen, den vorhandenen Quellcode zu verstehen, geeignete Teile zu übernehmen und die nötigen Anpassungen umzusetzen.

Die bestehende App lässt sich jedoch nicht einfach für Windows neu kompilieren: Ihre Oberfläche und mehrere Systemfunktionen verwenden Apple-Frameworks. Diese Teile müssten ersetzt oder neu entwickelt werden. Die vorhandenen Python-Werkzeuge und Teile der Verarbeitungslogik bieten eine Grundlage; auch sie müssten unter Windows geprüft und gegebenenfalls angepasst werden.

QUELLCODE ALS AUSGANGSPUNKT
Wenn du eine Windows-Portierung angehen möchtest, kannst du unter „Entwicklung & Quellcode“ den vollständigen Quellcode als ZIP exportieren und ihn einem Coding-Agenten als Ausgangspunkt geben. Besonders Geräteverbindung, Dateipfade sowie Sicherung und Wiederherstellung müssten unter Windows sorgfältig getestet werden.

Eine Windows-Version wird damit nicht angekündigt; einen Veröffentlichungstermin gibt es derzeit nicht.
""", en: """
There is currently no Windows version of RealmCraft Companion. The available app was developed for macOS.

PORTING IF THERE IS INTEREST
A Windows implementation should be feasible in principle. A coding agent can help explain the existing source, reuse suitable parts and implement the necessary changes.

However, the existing app cannot simply be recompiled for Windows: its interface and several system features use Apple frameworks. Those parts would need to be replaced or rebuilt. The existing Python tools and parts of the processing logic provide a starting point; they would also need Windows testing and potentially some adaptation.

START WITH THE SOURCE
If you would like to work on a Windows port, export the complete source ZIP under “Development & source” and give it to a coding agent as a starting point. Device connectivity, file paths, backup and restore would need careful testing on Windows in particular.

This is not an announcement of a Windows release; there is currently no release date.
"""),
    .init(id: "updates", icon: "clock.arrow.circlepath", deTitle: "Update Log (English)", enTitle: "Update Log", de: releaseDocument("CHANGELOG"), en: releaseDocument("CHANGELOG")),
    .init(id: "backlog", icon: "list.bullet.clipboard", deTitle: "Backlog (English)", enTitle: "Backlog", de: releaseDocument("BACKLOG"), en: releaseDocument("BACKLOG"))
]

struct HelpView: View {
    @Environment(\.companionTheme) private var theme
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
            CompanionPageHeader(title: english ? "Help" : "Hilfe") {
                if !embedded {
                    Picker("Language / Sprache", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }
                        .labelsHidden().frame(width: 140)
                }
                TextField(english ? "Search help" : "Hilfe durchsuchen", text: $search).textFieldStyle(.roundedBorder).frame(width: CompanionLayout.searchWidth)
            }
            HStack(spacing: 0) {
                VStack {
                    List(selection: $selected) {
                        ForEach(HelpCategory.allCases) { category in
                            let topics = articles.filter { $0.category == category }
                            if !topics.isEmpty {
                                Section(category.title(english: english)) {
                                    ForEach(topics) { article in
                                        Label(english ? article.enTitle : article.deTitle, systemImage: article.icon)
                                            .padding(.vertical, 6)
                                            .tag(article.id)
                                    }
                                }
                            }
                        }
                    }.listStyle(.sidebar).scrollContentBackground(.hidden)
                }.frame(width: CompanionTheme.sidebarWidth).background(theme.surface)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Label(english ? article.enTitle : article.deTitle, systemImage: article.icon).font(CompanionLayout.detailTitle)
                        HelpParagraphs(content: english ? article.en : article.de)
                        if article.id == "development" {
                            Button(action: exportSource) {
                                Label(english ? "Export complete source ZIP…" : "Vollständigen Quellcode als ZIP exportieren…", systemImage: "square.and.arrow.up")
                            }.buttonStyle(CompanionButtonStyle(prominent: true))
                        }
                        if article.id == "agent" {
                            VStack(alignment: .leading, spacing: 12) {
                                Button(english ? "Save agent instructions as MD…" : "Agent-Anleitung als MD speichern …") { exportResource("AGENT-SETUP-" + language, extension: "md") }.buttonStyle(CompanionButtonStyle(prominent: true))
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
                        }.buttonStyle(.plain).foregroundStyle(theme.accent).font(.callout)
                    }.padding(CompanionLayout.pageInset).frame(maxWidth: 880, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
                }.id(article.id + language)
            }
        }.frame(minWidth: embedded ? 0 : 900, minHeight: embedded ? 0 : 600)
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

private enum HelpBlock {
    case heading(String)
    case paragraph(String)
    case item(marker: String, text: String)

    static func parse(_ content: String) -> [HelpBlock] {
        var blocks: [HelpBlock] = []
        var paragraph: [String] = []
        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(paragraph.joined(separator: "\n")))
            paragraph.removeAll()
        }

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if let prefix = line.range(of: "^#{1,6} +", options: .regularExpression) {
                flushParagraph()
                blocks.append(.heading(String(line[prefix.upperBound...])))
            } else if let prefix = line.range(of: "^(?:[0-9]+[.)]|[•*–-]) +", options: .regularExpression) {
                flushParagraph()
                let marker = String(line[prefix]).trimmingCharacters(in: .whitespaces)
                blocks.append(.item(marker: marker.first?.isNumber == true ? marker : "•",
                                    text: String(line[prefix.upperBound...])))
            } else if line == line.uppercased() && line.count < 100 && line.contains(where: { $0.isLetter }) {
                flushParagraph()
                blocks.append(.heading(line))
            } else {
                paragraph.append(line)
            }
        }
        flushParagraph()
        return blocks
    }
}

private struct HelpParagraphs: View {
    @Environment(\.companionTheme) private var theme
    let content: String

    var body: some View {
        let blocks = HelpBlock.parse(content)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks.indices, id: \.self) { index in
                switch blocks[index] {
                case .heading(let text):
                    Text(text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.accent)
                        .padding(.top, index == 0 ? 0 : 12)
                        .padding(.bottom, 10)
                        .accessibilityAddTraits(.isHeader)
                case .paragraph(let text):
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 18)
                case .item(let marker, let text):
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(marker)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.accent)
                            .frame(minWidth: 26, alignment: .trailing)
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 14)
                }
            }
        }
        .font(.system(size: 14))
        .lineSpacing(5)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
}
