# Player appearance

Original models and textures were extracted locally from the installed RealmCraft APK on 2026-09-06. They remain game assets, not newly authored Companion artwork.

The game exposes Boy/Girl body models, three body textures each, 52/42 shirts, 49/40 pants and two VR hand types. Companion displays these choices using one-based texture numbers. Exact in-game ordering and labels have not been visually compared yet.

The selected appearance is a manually configured Mac preference, independent of savegame parsing and Codex. It is not claimed to be automatically recovered from player_data. Each body model remembers separate clothing choices. Use skin commits; Cancel discards changes.

Armor slots come from the selected player snapshot. Original armor meshes use approximate material colors. Female helmet geometry includes the original renderer's -90-degree X rotation. The VR hand preview displays the original right-hand model.

Version 1.7.14 anchors shirts at the top of the body atlas, matching torso UV islands. The prefab static offset was unsuitable for this composed atlas and caused uncovered torsos; the former edge-stretch workaround has been removed.
