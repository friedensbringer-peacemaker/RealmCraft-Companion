REALMCRAFT COMPANION 1.1.0
Deutsch / English

DEUTSCH

Eine unabhängige Community-App für lokale RealmCraft-Backups von der Meta Quest.
Für macOS 14 oder neuer, Apple Silicon und Intel.

INSTALLATION
1. Die ZIP entpacken.
2. „RealmCraft Companion.app“ in den Mac-Ordner „Programme“ ziehen.
3. App starten. Beim ersten Start ist Englisch eingestellt. Danach bleibt die zuletzt gewählte Sprache erhalten. Die gesamte App einschließlich Hilfe ist umschaltbar.
4. Unter „Einrichtung“ ADB prüfen oder die offiziellen Google Platform Tools
   nach Zustimmung zu Googles Lizenzbedingungen installieren.
5. Quest per USB-Datenkabel verbinden, Entwicklermodus aktivieren und
   USB-Debugging im Headset erlauben. Gerät, Spiel und Welten werden erkannt.

BEDIENUNG
Vor jeder Übertragung im Spiel speichern und RealmCraft beenden.
„Quest → Mac sichern“ legt einen neuen, geprüften Library-Eintrag an.
„Auf Quest wiederherstellen“ sichert zunächst automatisch die vorhandene
Zielwelt und überträgt dann den gewählten Stand. Das Spiel erst nach der
Erfolgsmeldung starten. Der Stopp-Button beendet das Spiel sofort OHNE Speichern.

ZIP-Import/-Export, Umbenennen, Backup-Suche und ein wählbarer Library-Ordner
sind enthalten. Beim Wechsel können bisherige Einträge mitkopiert werden.
Die ursprüngliche Library bleibt dabei erhalten.

APPLE-SICHERHEITSHINWEIS
Diese Ausgabe ist lokal ad-hoc signiert, nicht mit einem Apple Developer ID
Zertifikat signiert und nicht notarisiert. macOS kann den ersten Start blockieren.
Öffne nur eine vertrauenswürdige Kopie. Apples Anleitung erklärt die Prüfung
und die Möglichkeit „Dennoch öffnen“ unter Datenschutz & Sicherheit:
https://support.apple.com/de-de/102445
Es ist nicht erforderlich, Gatekeeper global zu deaktivieren.

URSPRUNG
Eine Discord-Antwort von AdminPickaxe im Kanal #general vom 31.08.2026, 10:21,
beschrieb lokale USB-Kopien der Weltordner als Backup-Möglichkeit. Anlass war
das damals genannte Server-Uploadlimit von 250 MB. Diese App macht lokale
Sicherungen auf dem Mac komfortabler. Die zweisprachige Hilfe erläutert die
Quelle und den historischen Kontext. Es besteht keine offizielle Verbindung
zu Meta, Google oder Tellurion Mobile.

Diese App-ZIP enthält keine persönlichen Savegames und kein ADB.
Die App lädt keine Savegames hoch. Ein Cloud-synchronisierter Library-Ordner
kann allerdings durch den jeweiligen Cloud-Dienst synchronisiert werden.

ENGLISH

An independent community utility for local RealmCraft backups from Meta Quest.
Requires macOS 14 or later; supports Apple Silicon and Intel.

INSTALLATION
1. Extract the ZIP.
2. Drag “RealmCraft Companion.app” into Applications.
3. Launch it. First launch uses English; later launches remember your chosen language. The entire app, including help, supports German and English.
4. Open “Setup” to check ADB or install Google's official Platform
   Tools after accepting Google's license terms.
5. Connect the Quest with a USB data cable, enable developer mode and allow
   USB debugging in the headset. Device, game and worlds are detected.

USAGE
Save in the game and close RealmCraft before every transfer.
“Back up Quest → Mac” creates a new verified backup on your Mac.
“Restore to Quest” automatically backs up the existing target world
before restoring the selected version. Wait for success before opening the game.
The stop button force-closes RealmCraft WITHOUT saving.

ZIP import/export, renaming, backup discovery and a configurable library folder
are included. Existing entries can be copied and verified when changing folders;
the old library is preserved.

APPLE SECURITY
This build is ad-hoc signed, not Developer ID signed or notarized. macOS may
block the first launch. Only open a trusted copy. Apple's guide explains the
checks and the “Open Anyway” option in Privacy & Security:
https://support.apple.com/en-gb/102445
There is no need to disable Gatekeeper globally.

ORIGIN
A Discord reply from AdminPickaxe in #general on August 31, 2026 at 10:21
explained that world folders could be copied to a computer over USB. The
question was prompted by the 250 MB server upload limit mentioned at the time.
This app makes local backups easier on a Mac. The bilingual help explains the
source and historical context. The utility is not affiliated with Meta, Google
or Tellurion Mobile.

This app ZIP contains no personal savegames or ADB installation.
The app does not upload savegames. Your cloud provider may sync the selected
library folder if it is located in a cloud-synced directory.

OFFICIAL RESOURCES
Google Platform Tools / SDK license:
https://developer.android.com/tools/releases/platform-tools
Meta device setup / developer mode:
https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/

TRANSFER RECOVERY
Keep the game closed after an interrupted restore. Reconnect and follow the
error message. The automatic library backup is available for recovery.
Additional previous-world copies remain on the Quest outside the active worlds
folder as files/.library-previous-<UUID>. Failed transfers may also leave
.library-stage-<UUID> folders. These use storage and are not automatically
removed by the app. See built-in help for details.


Entwicklung / Development
Dieses Programm wurde vollständig mit OpenAI Codex und GPT-6 Astra entwickelt.
This program was developed entirely with OpenAI Codex and GPT-6 Astra.
Vollständiger Community-Quellcode unter MIT-Lizenz: siehe COMMUNITY.md und das Quellcode-ZIP; auch direkt über Hilfe → Entwicklung & Quellcode exportierbar.
Complete MIT-licensed community source: see COMMUNITY.md and the source ZIP, also available in Help → Development & source.
