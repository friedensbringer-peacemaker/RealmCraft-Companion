# TarantNET Gaming channel catalog · 6 September 2026

All 170 public regular uploads and six Shorts were enumerated from https://www.youtube.com/@TarantNETGaming. 142 regular videos and six Shorts were identified as RealmCraft; 28 other-game uploads were excluded. Titles containing RC VR, or neither game name, were checked through descriptions: DBsd2Quk2h8, cuOCBF0ujiw and PmTxtG47crU belong to RealmCraft. Re-mastered videos and separate uploads remain distinct; each video ID appears once.

The Companion contains 148 entries with German titles and topic search. 114 have usable caption indexes covering 8,638 approximately thirty-second windows. German search vocabulary is mapped to English source terms; this is a search aid, not a translation of the complete spoken content. Each match opens the original video five seconds before its window. Search uses AND across words; phrases are not asserted to be consecutive.

The three previously edited guides retain their 18 independently linked steps. Remaining entries contain automatically detected topics or title-based overviews, and explicitly do not claim a complete, visually verified build guide. Only the three pilot videos have the previously documented visual samples. No new video or audio was played during this channel import.

## Coverage and limitations

- `inventory.json` records inclusion/exclusion, source metadata availability, retrieved caption languages and window counts per video.
- Full metadata was retrieved for 147 of the 148 included entries. a7IR-MlqZzo required a sign-in/bot challenge; no cookies were exported and the challenge was not bypassed. Its channel title and duration remain included with an unknown publication date.
- YouTube throttled translated captions. Downloads were stopped, later resumed for original English captions only after a pause, then stopped again on HTTP 429 without automatic retries. Other missing entries had no English captions listed.
- Music-only caption labels were excluded. The no-commentary landscaping timelapse Jo4V7a-kW6Q and music-only light-banner Short HseIKVxE7nM remain topic entries.
- No video/audio was downloaded. Raw caption and player metadata files were used temporarily for indexing and are not bundled in the application or shared source archive. The bundled index stores unordered normalized words, not a sequential transcript.
- Exact dimensions, material quantities, mechanic validity and compatibility with Quest are not inferred from titles or automatic captions. PCVR/Steam is shown only where the title or description identifies it.

## Rebuild the local content pack

`import_video_channel.py` is a deterministic, offline importer. It takes channel/Shorts JSON inventories, a folder of public `.info.json` metadata and available `.en-orig.json3`, `.en.json3` or `.de.json3` caption files, the existing catalog (preserves only edited guides), and the maintained German title table. It does not fetch anything, play media, overwrite the source inputs or call an AI service.

```sh
python3 import_video_channel.py --metadata /path/to/metadata-and-captions --channel /path/to/channel.json --shorts /path/to/shorts.json --seed Resources/VideoTips.json --titles Research/tarantnet-channel-2026-09-06/titles-de.tsv --output /path/to/new-catalog
```

Review the generated inventory, then replace Resources/VideoTips.json and rebuild the app. New video titles require an explicit German title entry. This is a dated snapshot, not a recurring channel monitor.

`Tests/VideoChannelTests.swift` checks all 148 IDs, Shorts, preserved guides, real German-to-English transcript matches, empty search and malformed entries. The existing pilot tests select the three edited entries so they continue to validate their content after catalog expansion.
