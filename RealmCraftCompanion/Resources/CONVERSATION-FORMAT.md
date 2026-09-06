# Conversation data and setup

## Respawn evidence and compatibility

Development inspected local RealmCraft v107 IL2CPP metadata. Component enum field 7690 is RespawnData; its UInt16 default is 15 (metadata default absolute byte 8094915). RespawnDataComponent declares Location and Rotation (fields 11235 and 11236). These facts identify the saved component; the app does not distribute or require the metadata/APK.

The supported player v2 prefix is checked at every relevant boundary before interpreting component 15 version 0. Three signed big-endian 32-bit location coordinates occupy offsets 87, 91, 95, followed by a zero byte and the Health component 5 version 1 at offset 100. Entity version, declared payload length, SpawnData/Position/Rotation/PlayerData boundaries and reasonable coordinate ranges are checked. Runtime also validates the entire player layout via PlayerReader and verifies the exact player_data checksum via Library.readPlayerData. Unknown/truncated/changed layouts return unavailable. The local regression save reports a stable respawn while its saved player position changes. Synthetic fixtures vary the coordinates and reject unknown component versions and every truncation.

The byte after the coordinates is deliberately not interpreted as dimension or a usability flag. Dimension and whether the respawn remains valid are not claimed. No bed, named home or origin is substituted. This reader covers the observed format, not every possible version. Dates and uncertainty accompany its answer.

## Own chests

Ownership is explicit user annotation, keyed by world and the existing chest ID (dimension and coordinates). No automatic NPC classification. Marked IDs not present in a later index and unreadable selected containers cause a partial result. Only the current selected backup's verified index is used. Savegame date and backup date are separate. No device/game writes are performed by the conversation.

## Test steps (Deutsch)

1. Companion öffnen → Einstellungen → Sprache Deutsch → Gespräch.
2. Zuerst ohne Mikrofon tippen: „Was brauche ich für ein Bett?“ oder „Wie crafte ich eine Kiste?“.
3. Die Zeile Apple Intelligence zeigt, ob das lokale Modell bereit ist. Falls nicht: Systemeinstellungen → Apple Intelligence & Siri prüfen. Die einfache Suche bleibt verfügbar.
4. Unter macOS Ton das richtige Eingabegerät und die gewünschte Ausgabe auswählen. Das Quest-Mikrofon ist nicht automatisch ein Mac-Mikrofon.
5. Mikrofon starten und die macOS-Freigabe erteilen. Beim ersten Start kann Apple ein lokales Sprachmodell laden. Erst bei „Höre zu“ sprechen. Eine kurze Pause sendet die Frage.
6. Gesprächsmodus aktivieren, dann Mikrofon starten. Nach jeder Antwort hört der Companion erneut zu. Stopp/Escape beendet Aufnahme und Ausgabe. Kein Siri-Aufruf erforderlich.
7. Einen Spielstand auswählen. „Wo ist mein Spawnpunkt?“ nennt gespeicherte Koordinaten, sofern das Format unterstützt wird. Kein Live-GPS/keine Live-Spielerposition.
8. Karten → Interessante Orte → Markierung auswählen → „Haus“ benennen und speichern. Danach „Wo ist mein Haus?“ fragen.
9. Gespräch → Eigene Kisten → Kisten des gewählten Spielstands einlesen. Nur eigene Kisten anhaken, NPC-Kisten unmarkiert lassen. Bei Doppelkisten beide Datensätze markieren. Danach „Wie viele Diamanten habe ich?“ fragen. Datum und Unsicherheit werden mitgesprochen.

Für aktuelle Daten zuerst eine neue Sicherung erstellen und deren Kisten erneut einlesen. Rezeptreferenzen müssen im RealmCraft-VR-Crafting-Menü geprüft werden.
