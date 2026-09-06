# Mobs & Animals: source notes / Quellenstand

AI-generated research snapshot, 2026-09-06. All catalog prose and classifications were prepared by AI and may be wrong or differ from the actual game. Sources are external publications, not AI-generated evidence. No gameplay verification or savegame mob scan was performed. This is a selected reference catalog, not an exhaustive census. Babies explicitly named in release notes are separate variant entries.

KI-generierter Recherche-Stand vom 06.09.2026. Alle Katalogtexte und Einordnungen wurden von KI aufbereitet und können falsch sein oder vom tatsächlichen Spiel abweichen. Die verlinkten externen Quellen sind keine KI-generierten Beweise. Keine Prüfung im Spiel oder Mob-Auslesung aus Spielständen. Auswahlkatalog ohne Vollständigkeitsanspruch. In Veröffentlichungen ausdrücklich benannte Jungtierformen sind eigene Varianteneinträge.

## Evidence hierarchy

- [Developer announcements on Steam](https://steamcommunity.com/app/2943620/allnews/): integration evidence, with a release/version label per record. This evidence does not identify the user's installed Quest build.
- [Latest developer announcements including 1.0.3](https://steamcommunity.com/app/2943620/?curator_clanid=4777282): consulted for Piglin/Hoglin variants and newly released Nether entries.
- [Feeding update, 2025-03-21, mirrored by SteamDB](https://steamdb.info/patchnotes/17807925/): Ocelot, Llama, Cow and Sheep. [Linked original](https://steamcommunity.com/games/2943620/announcements/detail/523086487782162494) did not expose readable article text to the research tool.
- [Pathfinding update, 2025-01-17, mirrored by SteamDB](https://steamdb.info/patchnotes/17039452/): Pufferfish and Drowned. [Linked original](https://steamcommunity.com/games/2943620/announcements/detail/764023363746136286) did not expose readable article text.
- [Ghast update, 2025-04-17, mirrored by SteamDB](https://steamdb.info/patchnotes/18147050/): Ghast. [Linked original](https://steamcommunity.com/games/2943620/announcements/detail/523088842745446638) exposed only navigation.
- [Publisher-linked roadmap](https://realmcraft-vr.canny.io/): Horse, Frog, Zombie Horse are in progress at research time. Roadmap status can lag release notes; these are not marked released without a release source.

## Wikis

[Publisher FAQ](https://www.tellurionmobile.com/faq/) links the [RealmCraft Game Wiki](https://realmcraftgame.fandom.com/wiki/RealmCraft_Game_Wiki), a community-maintained general/mobile wiki. We did not find a verified official VR-specific wiki. The UI does not label the community wiki as official VR documentation.

Direct species pages found: [Wolf](https://realmcraftgame.fandom.com/wiki/Wolf), [Ocelot](https://realmcraftgame.fandom.com/wiki/Ocelot), [Horse](https://realmcraftgame.fandom.com/wiki/Horse), and Pig listed in the [entity index](https://realmcraftgame.fandom.com/wiki/Category%3AEntities). Otherwise the catalog links the [general mob overview](https://realmcraftgame.fandom.com/wiki/Mobs) and a species-specific Minecraft Wiki reference. No fabricated RealmCraft species URL is used.

[Breeding](https://realmcraftgame.fandom.com/wiki/Breeding) explicitly describes outdated content. Chicken and Rabbit are included only as unconfirmed VR references. Its food, growth and breeding rules have not been imported as VR facts.

[Minecraft Wiki](https://minecraft.wiki/) links use the canonical `/w/` species pages, with baby variants pointing to the parent species. Automated page reads were blocked by robots policy. These links are alternative references only; Minecraft mechanics are not treated as evidence of RealmCraft integration.

## Maintenance

`Mobs.json` stores release status, evidence URL, evidence label, optional RealmCraft species/reference URL and Minecraft URL independently. Update the research date and evidence when changing a status. Keep `aiGenerated: true` and the visible disclaimer. Catalog loading validates the schema and source URL structure; failure is visible, not replaced with an empty fabricated list.


## Variant and location revision · 2026-09-06

47 entries: 24 release-evidenced, 3 planned, 20 unconfirmed. 20 baby entries comprise the two previously release-evidenced Nether babies and 18 unconfirmed references. These counts describe this catalog, not a complete inventory of the game.

[General RealmCraft breeding documentation](https://realmcraftgame.fandom.com/wiki/Breeding) supports baby references for cow, sheep, pig, wolf, ocelot, horse, chicken and rabbit. Its historical/mobile scope cannot establish current VR support. [Minecraft Bedrock 26.10 release notes](https://feedback.minecraft.net/hc/en-us/articles/44418129038733-Minecraft-Bedrock-Edition-26-10-Tiny-Takeover) explicitly list baby forms for bee, cat, llama, turtle, zombie, drowned, villager, zombified piglin, zoglin and zombie horse. These additional entries are comparison references only, never inferred VR releases.

Every entry has a habitat object. `dimension` and `basis` distinguish a dimension supported by a VR update from an orientation based on general RealmCraft or Minecraft documentation. `biomes` describes VR evidence; `reference` labels the comparison and `sourceURL` links its basis. No exact VR spawn biome was established. Zoglin and new unconfirmed babies have no asserted VR dimension. Variant identifiers remain stable even when display names change.
