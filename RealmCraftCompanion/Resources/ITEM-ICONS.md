# Optionale Gegenstands-Icons

Recherche und Integration vom 2026-09-06. Optionaler Download über Einstellungen → Gegenstands-Icons.

## Ergebnis der Quellenprüfung

- Kenney Voxel Pack: 190 2D-Grafiken, 128 × 128, CC0. Kenney erlaubt auch kommerzielle Verwendung ohne verpflichtende Namensnennung. Geeigneter Kandidat für eigenständige Blockwelt-Grafiken; keine Original-Icons aus RealmCraft. Vollständige Abdeckung unserer Gegenstands-IDs wurde noch nicht geprüft.
  - https://kenney.nl/assets/voxel-pack
  - https://kenney.nl/support
- Game-icons.net: Werkzeug- und Gegenstandssymbole, beispielsweise die Schaufel von Lorc. CC BY 3.0; Autor, Quelle, Lizenz und gegebenenfalls Änderungen dokumentieren. Geeignet für reduzierte Symbole, keine spielidentischen Texturen.
  - https://game-icons.net/1x1/lorc/spade.html
  - https://game-icons.net/faq.html
- Originale RealmCraft-VR-Icons: Bei der Recherche keine ausdrückliche Freigabe zur Weiterverteilung im Companion gefunden. Vor Aufnahme in App und Quellcodepaket wäre eine belegte Erlaubnis des Rechteinhabers erforderlich.
- Minecraft-Originaltexturen sind keine frei lizenzierten Ersatzgrafiken für RealmCraft. Mojang/Microsoft behalten die Rechte; die Usage Guidelines beschränken Verwendung und Weitergabe.
  - https://www.minecraft.net/en-us/usage-guidelines
- Faithful ist kein unkomplizierter Ersatz: Lizenz v4 enthält unter anderem Paywall-Beschränkungen und verbietet die Verwendung als Ersatz für Minecraft-Grafiken, wenn deren Verwendung nicht erlaubt wäre.
  - https://faithfulpack.net/license

Empfehlung: freie, eigenständig gestaltete Icons verwenden und als solche kennzeichnen. Für exakt spielgleiche Icons zuerst eine ausdrückliche RealmCraft-Freigabe beschaffen. Die Quellenprüfung ist keine Garantie für sämtliche Grafiken eines Pakets; beim tatsächlichen Import die konkreten Dateien und ihre Lizenznachweise erfassen.

## Vorgesehene Bedienung

Im vorhandenen Optik-Menü eine unabhängige Auswahl „Gegenstände“ ergänzen:

- Nur Text: Standard, kompakte Darstellung ohne Icon-Platzhalter oder reservierte Bildspalte.
- Icons + Text: kleine Gegenstandsbilder neben unveränderten Namen und Mengen.

Die Auswahl global und über App-Neustarts hinweg speichern, unabhängig vom Skin „Blockwelt/Klassisch“. Einheitlich auf Spielerinventar, Ausrüstung, Kisteninhalte und geeignete Materiallisten anwenden. Namen bleiben auch bei aktivierten Icons erhalten.

## Technische Leitlinien für die Umsetzung

- Zentrale Zuordnung anhand der vorhandenen numerischen RealmCraft-itemID; keine Zuordnung über übersetzte Anzeigenamen und keine ungeprüfte Gleichsetzung mit Minecraft-IDs.
- Nur bestätigte Gegenstände abbilden. Fehlende oder unklare Zuordnungen bleiben Text, ohne ein möglicherweise falsches Bild anzuzeigen.
- Werkzeugmaterialien unterscheidbar halten; ein allgemeines Schaufelsymbol nicht als originalgetreue Diamantschaufel ausgeben.
- Ressourcen lokal bündeln, keine externen Bildabfragen beim Anzeigen von Inventaren.
- Lizenzverzeichnis mit Dateinamen, Urheber, Quelle, Lizenz, Änderungen und Paketversion führen. Fremde Assets nicht pauschal unter die MIT-Lizenz des App-Codes stellen.
- Vor Freigabe Umschalten, Persistenz, beide Sprachen, beide Skins, fehlende Icons und lesbare kompakte Listen prüfen.


## Implementierte Integration

- Download erst auf ausdrücklichen Klick „Herunterladen & nutzen“, ca. 1,3 MB von Kenney; Aktivierung nach erfolgreicher Installation.
- SHA-256 des geprüften ZIP: `667c05e3f6d95718aaef888c7fc06f7137ba5dede95f4574deb17d4436257958`.
- 49 explizite ID-Zuordnungen in `ItemIcons.json`, basierend auf dem vorhandenen Gegenstandskatalog. Eigenständige, sinngemäße Darstellungen; keine Garantie für Übereinstimmung mit Spieltexturen. Materialien ohne passende Grafik (z. B. Holz-/Steinwerkzeuge) bleiben Text.
- Anzeige in Spielerinventar und Kisten. Ausrüstung unterstützt denselben Mechanismus, das Kenney-Pack enthält jedoch keine passenden Rüstungsicons. Bauanleitungs-Materiallisten haben keine verlässliche Gegenstands-ID-Zuordnung und bleiben vorerst Text.
- Speicherung unter `~/Library/Application Support/RealmCraftCompanion/OptionalAssets/KenneyVoxel-1`, inklusive unveränderter `License.txt` des Autors. PNG-Dateien werden unverändert verwendet.
- Umschalten auf „Nur Text“ behält das Pack lokal; „Heruntergeladenes Pack entfernen“ entfernt es und schaltet auf Text zurück.
- App und Community-Quellcode enthalten nur Zuordnungen und Downloadfunktion, keine Kenney-Grafiken. Der Pack-Download erfolgt unabhängig vom App-Download.
- Die Lizenz bleibt CC0, Urheber Kenney Vleugels / Kenney; sie wird nicht durch die MIT-Lizenz des App-Codes ersetzt.


## Grafikpaket-Auswahl · 2026-09-06

Die Einstellungen bieten nun Kenney Voxel Pack (49 Zuordnungen, CC0, 1,3 MB) und Pixel Perfection Legacy 26.2-88.0-1 (686 Zuordnungen, 36,5 MB). „Nur Text“ bleibt unabhängig auswählbar. Auswahl eines Pakets im Auswahlfeld zeigt zunächst dessen Details; „Dieses Pack nutzen“ aktiviert ein installiertes Pack, „Herunterladen & nutzen“ lädt und aktiviert erst nach erfolgreicher Prüfung. Beide Packs bleiben unabhängig installiert und können einzeln entfernt werden. Entfernen des inaktiven Packs verändert die aktive Anzeige nicht. Ältere Kenney-Installationen und ihre Einstellungen bleiben nutzbar.

Pixel Perfection: https://modrinth.com/resourcepack/pixel-perfection-legacy

Konkrete Version: https://cdn.modrinth.com/data/6w3F4SEu/versions/M27tmode/Pixel%20Perfection%20Legacy%2026.2-88.0-1.zip

SHA-256: `be579ea5be914b0673ecdde0a869a0ddca6c6653b732b3193e86a760579105d6` (zusätzlich beim Abruf gegen Modrinths SHA-512 verifiziert).

Urheber: XSSheep; Fortführung Nova_Wostra; weitere Beiträge freejusticehere und HexaBlu. Original-Credits aus `pack.txt` werden unverändert installiert. Projektbeschreibung und CurseForge nennen CC BY-SA 4.0 für das Original; das Modrinth-Metadatenfeld nennt CC BY 4.0. Beide Angaben bleiben sichtbar erhalten, die Integration beachtet auch die ShareAlike-Bedingungen. Das ZIP enthält Credits, jedoch keine separate vollständige Lizenzdatei. Ein zusätzlicher lokaler Lizenzhinweis dokumentiert Quellen, Lizenzlinks, Urheber und unveränderte Verwendung der ausgewählten PNGs.

- https://www.curseforge.com/minecraft/texture-packs/pixel-perfection-legacy/license
- https://creativecommons.org/licenses/by-sa/4.0/
- https://creativecommons.org/licenses/by/4.0/

Es werden nur explizit zugeordnete PNG-Dateien und `pack.txt` entpackt, keine Shader, Musik, Minecraft-Credits, verschachtelten Zusatzpacks oder anderen Bestandteile. Dateien bleiben unverändert. Die fremden Grafiken stehen nicht unter der MIT-Lizenz des Companion-Codes.

Zuordnung: vorhandene englische Katalognamen wurden zur Entwicklungszeit mit exakt gleichnamigen Minecraft-Item-/Blockdateien abgeglichen und als numerische ID-Zuordnung gespeichert (`PixelItemIcons.json`). Laufzeit und Sprache verändern die Zuordnung nicht. Quadratische Einzeltexturen werden verwendet; Animationstreifen und ausgewählte Grafiken, die zusätzliche Einfärbung benötigen, sind ausgenommen. Blockgrafiken erscheinen als flache 2D-Texturen. Die 686 Zuordnungen sind keine Aussage über vollständige oder spielidentische RealmCraft-Abdeckung; Grundlage bleibt der bestehende Namenskatalog.
