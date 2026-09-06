# Realmcraft Atlas 0.1.0

Eigenständiges, lokales Kartenprojekt für Realmcraft. Der Importer liest gespeicherte Chunks und erzeugt eine zoombare Browserkarte. Er verändert keine Spielstände und braucht weder das laufende Spiel noch ADB.

## Öffnen und bedienen

Auf macOS `Karte öffnen.command` doppelklicken oder `output/index.html` im Browser öffnen. Eine bereits erstellte Karte funktioniert komplett offline. **Den gesamten Kartenordner zusammenhalten**, einschließlich `tiles`, `regions` und JavaScript-Dateien. Zum Betrachten sind Python und ein Webserver nicht nötig. Aktuelle Browser mit `DecompressionStream` unterstützen auch die Höhenebenen.

- Oberwelt und Nether; im Nether blendet die Übersicht zunächst das Dach oberhalb Y 90 aus.
- **Oberfläche:** schnelle, vorberechnete Übersicht.
- **Einzelebene:** nur die Blöcke auf dem gewählten Y. Luft erscheint dunkel.
- **Oberfläche bis Ebene:** oberster Nicht-Luft-Block bis zum gewählten Y. Damit lassen sich unterirdische Böden ansehen, wenn ihre Decke oberhalb des Schnitts liegt.
- Höhen **0–255**, Regler, direkte Eingabe und Schaltflächen **±1, ±5, ±10**. Eine Höheneingabe aus der Übersicht aktiviert die Einzelebene.
- Bild↑/Bild↓ auf der fokussierten Karte: ±1; mit Alt ±5; mit Shift ±10.
- Ziehen/Pfeiltasten zum Verschieben, Mausrad/Trackpad/Pinch und +/− zum Zoomen, F für den Überblick.
- X/Z-Suche, Chunk-Raster, Landschafts- und Höhenfarben.
- Klick auf einen Block: Name und X/Y/Z; eigene Orte mit Höhe und Ansicht speichern. Die Orte bleiben im lokalen Browserspeicher und können als JSON exportiert werden. Bei `file://` behandeln Browser diesen Speicher unterschiedlich; die Oberfläche meldet fehlende Speicherung.

Die Farben sind eigene schematische Materialfarben, keine Originaltexturen. Ungespeicherte Chunks bleiben transparent. Unbekannte IDs erscheinen magenta. Fehlende oder nicht unterstützte Dateien werden ausdrücklich gemeldet. Eine Teilkarte nennt ihre importierte und noch fehlende Chunk-Anzahl.

## Import

Python 3.10+, NumPy und Pillow:

```sh
python3 -m pip install -r requirements.txt
python3 -m realmcraft_map /Pfad/zum/Weltordner --output output --open
```

Danach kann auf macOS `Karte erstellen.command` einen Weltordner auswählen. Den einzelnen Ordner mit Dateien wie `o.0,0` wählen, nicht die gesamte Savegame Library.

```sh
# Kleiner Ausschnitt um den Ursprung
python3 -m realmcraft_map /Pfad/zur/Welt --output preview --radius 128

# Cache außerhalb eines synchronisierten Ordners
python3 -m realmcraft_map /Pfad/zur/Welt --output output --cache /tmp/realmcraft-atlas-cache

# Explizite Teilkarte aus dem bereits vorhandenen Cache
python3 -m realmcraft_map /Pfad/zur/Welt --output preview --cache /tmp/realmcraft-atlas-cache --cached-only
```

Der erste Import muss die Chunk-Dateien lesen. Bei noch nicht lokal verfügbaren Dateien kann das dauern. Folgeläufe verwenden den Cache nach Dateipfad, Größe, Änderungszeit und Decoder-Version. Für einen garantierten Neuimport einen neuen Cache-Ordner angeben. Die eingelesenen Quelldateien erhalten SHA-256-Einträge in `audit.json`.

Exitcodes: 0 vollständig, 1 fehlgeschlagen, 2 Teilkarte oder ausgelassene Dateien. Bestehende Karten werden erst nach erfolgreichem Export ersetzt. Andere Ausgabeordner und Überschneidungen mit dem Savegame werden abgelehnt. Ein Ausgabeordner darf nicht im Quellspielstand liegen.

## Modul für ein gemeinsames Realmcraft Tool

- `realmcraft_map/chunks.py`: Decoder und vertikale Blockspalten.
- `realmcraft_map/build.py`: Import, Cache, Bildkacheln und Ebenenexport.
- `realmcraft_map/palette.py` und `blocks.json`: geprüfte ID-Namen, eigene Farben.
- `realmcraft_map/web/`: vollständig lokale Browseroberfläche.
- `docs/FORMAT.md`: Format, Herkunft und Grenzen.

Die Savegame Library kann später einen fertig übertragenen lokalen Weltordner an `build(source, output, cache=...)` übergeben oder den CLI-Prozess starten. Danach öffnet sie `output/index.html`. Backup und Wiederherstellung bleiben im Exporter. Die Projekte sind derzeit noch getrennt.

Optional `python3 -m pip install .`; anschließend steht `realmcraft-atlas` als Kommando bereit.

## Prüfen

```sh
python3 -m unittest discover -s tests -v
node tests/geometry.test.cjs
node tests/columns.test.cjs
node tests/ui-state.test.cjs
PYTHONPATH=. python3 tests/make_renderer_fixture.py /tmp/atlas-render-fixture
node tests/renderer.test.cjs /tmp/atlas-render-fixture/map
```

11 Python-Tests und vier JavaScript-Prüfungen decken Decoder, Achsen, RLE-Grenzen, Höhenschnitte, Cave Air, Koordinaten, die tatsächlichen Y-Bedienelemente, Cache, unveränderte Quellen und den kompletten Offline-Regionslader bis zu seinen Bildpixeln ab. Browserdarstellung wurde nicht durch einen automatisierten Browserlauf geprüft; die erzeugten Kartenbilder wurden visuell kontrolliert.

Die Ebenenbedienung orientiert sich an den [Höhlenebenen von JourneyMap](https://teamjm.github.io/journeymap-docs/latest/client/full-screen-map/). Es wird kein Minecraft-Mapper geforkt. Keine Spielbibliotheken, APK-Dateien, Originaltexturen oder persönlichen Spielstände im Quellcodepaket.

Entwickelt mit OpenAI Codex und GPT-6 Astra.
