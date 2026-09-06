# KI-Export

1. In der Seitenleiste **KI-Export** öffnen (auch über **Gespräch → KI-Export**).
2. Eine lokale Sicherung auswählen. Für aktuelle Daten vorher die Quest sichern.
3. **Alle gespeicherten Kisten mit Inhalten einbeziehen** aktiviert lassen, wenn Lagerbestände benötigt werden. Das verwendet die Kartenwerkzeuge; ihre Einrichtung wird bei Bedarf angeboten.
4. **Kontext erzeugen** wählen. Große Welten können mehrere Minuten benötigen.
5. Datenlücken und Dateigröße prüfen. **Markdown speichern …** oder **JSON speichern …** wählen.
6. Die Datei selbst beim gewünschten Agenten hochladen. Beispiel: „Nutze diesen Spielstand als Grundlage. Welche Ressourcen habe ich, und wo liegen sie?“

Markdown ist für die Unterhaltung gedacht; JSON für strukturierte Verarbeitung. Beide Dateien basieren auf demselben erzeugten Datenstand. Nur die Vorschau wird gekürzt. Es gibt keinen automatischen Upload und keine Zusicherung, dass jede beliebige Welt in das Kontextfenster jedes Modells passt.

## Eigene Bestände

Unter **Karten → Besitzbereich ziehen** mehrere Kisten gemeinsam markieren oder unter **Gespräch → Eigene Kisten** einzeln auswählen. Danach den KI-Kontext neu erzeugen. Der Export zählt Inventar, angelegte Rüstung und gelesene eigene Lagerbestände getrennt. Alle anderen gefundenen Kisten bleiben mit unbekanntem Besitz enthalten. Fehlende oder unlesbare Kisten ergeben Teilbestände. Besitz und Ortsnamen sind aktuelle Nutzerangaben pro Welt und können bei alten Sicherungen abweichen.

## Grenzen

Der Export beschreibt eine Sicherung, nicht das laufende Spiel. Spielerposition, Gesundheit, Hunger, Welt-Seed, Weltzeit, Rohstoffvorkommen im Gelände und aktuelle Kreaturen sind nicht decodiert. Der gespeicherte Respawnpunkt enthält keine verifizierte Dimension oder Nutzbarkeitsprüfung. Gespeicherte Chunk-Grenzen sind keine vollständige Geländeaufnahme. Minecraft-Wissen ist nicht automatisch für RealmCraft VR gültig.

# AI export

Open **AI export** in the sidebar (also linked from **Conversation**), choose a backup, include chests if needed and click **Generate context**. Review data gaps and file size, then save Markdown or JSON. Upload one format to the agent of your choice. Nothing is uploaded automatically.

Only chests marked in **Conversation → My chests** count as owned storage. Unmarked containers remain included with unknown ownership. Totals separate inventory, equipped armor and readable owned storage. Current annotations may differ from historical save state. Only the preview is shortened; exported lists are complete. External model context capacities vary.

Unknown fields and scan failures are explicit. This is a backup snapshot, not live game telemetry. Saved chunk bounds do not establish terrain resources, routes or complete explored coverage. Minecraft rules and recipes are not automatically verified for RealmCraft VR.
