# Companion read-only readers

Chest reader supports observed v9 chunk serialization. It validates coordinates against the decoded chest block (IDs 153/342), length-bounded records, 27-slot framing and item counts. Item entries require matching outer/inner IDs, known item headers, slot footers and unique slots. Extra item data is retained as a presence flag, not interpreted as enchantments. Empty means exactly zero entries and no residual body. Unsupported records produce explicit issues. The separate experimental `editor.py` writer supports validated v9 container patches on disposable copies only. It preserves item payload bytes, rewrites slot/count/record-size fields, and reparses modified containers. Game compatibility is not guaranteed.

The bundled ItemNames catalog contains factual enum identifiers/numeric mappings from the installed RealmCraft build, checked against controlled in-game references Diamond=3157, LapisLazuli=3170 and Chest=153. GoldIngot=3165. No game executable, textures, metadata binary, personal save or generated index is distributed. Labels are community translations, not official localization.

Place detection uses decoded saved blocks at all heights. Glass is grouped per chunk and 16-block height band. Building suggestions use 32x32x16 spatial cells with at least two indicator categories. These are heuristic location hints, not recognized house boundaries.

## Saved biomes
For observed v9 chunks, Serialize/DeserializeBiomes follow block serialization. The first 16 bytes are the Chunk.Biomes byte array, copied directly; the following carving-mask data is outside this reader. Chunk.GetBiome indexes it with `(local_x & 12) | ((local_z >> 2) & 3)`, ignoring Y. The biome enum contains IDs 0–60 (e.g. Plains=1, Forest=4, NetherWastes=8). Metadata signed constants use compressed zig-zag encoding, unlike unsigned item IDs. Unknown biome IDs are preserved. Short/missing biome payloads yield no map data rather than a guessed label. No game binary is distributed.

## Signs (observed v9)

Sign positions come from packed block IDs 162–167, 172–177, 736–739. Eight oak wall signs (block 172) have entity record type 162, followed by u32be body length, u8 version 1, i32be X/Y/Z, two uninterpreted bytes, u32be UTF-8 byte length, text and the nine-byte trailer `00 0f 00 00 00 00 00 0f 00`. Record coordinates must match a sign block; all boundaries, version, UTF-8 and trailer are checked. Other wood record families are not yet validated. Unsupported, missing or duplicate records show position with unavailable text, never an inferred empty inscription. The sign's block position is independent of coordinate strings written in its text.
