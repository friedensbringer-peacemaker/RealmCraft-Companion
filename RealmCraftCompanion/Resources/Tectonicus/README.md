# Tectonicus integration

Companion 1.7.31 provides an experimental, local Overworld rendering workflow. No external binaries or Minecraft resources ship in the source bundle.

- `worker.py`: official HTTPS downloads, checksum validation, signed/notarized Temurin installer assessment and private extraction, versioned tool activation, rendering, cancellation and loopback-only preview.
- `exporter.py`: strict existing RealmCraft v9 decoder, Java 1.17.1 Anvil output, bounded-memory region writes, mapping/coverage manifest and source-hash checks. The exporter never writes its input.
- `TectonicusView.swift`: library selection, exclusive library operation, source verification before/after rendering, immutable output runs, progress and latest-successful-preview restoration.

The renderer is pinned to [Tectonicus 2.31](https://github.com/tectonicus/tectonicus/releases/tag/v2.31). Minecraft 1.17.1 client resources are downloaded from Mojang's content-addressed endpoint and SHA-1 checked against the published version metadata. The [Adoptium API](https://api.adoptium.net) selects current Java 21 for the Mac architecture; package SHA-256, Eclipse Foundation installer signature and macOS installation assessment must pass. Java is extracted privately using pkgutil; no administrator installation, quarantine removal or Gatekeeper bypass is performed. Existing toolchains survive a failed setup. User confirmation of Minecraft Java ownership and resource downloads is required before first setup.

Maps and the rendering intermediate remain local under Application Support/RealmCraftLibrary/Tectonicus. Each run has a fresh folder containing the export manifest, XML configuration, renderer log and result. Only a completed run whose entire source library manifest passed final verification receives `.library-verified` and becomes eligible for automatic restoration. The preview serves only that run's map directory on an ephemeral 127.0.0.1 port and exits when its parent Companion exits.

Known approximations: Overworld only; default block properties, full skylight, no block light, constant plains biome, no original entity/inventory/sign text. Blank sign entities satisfy Tectonicus's geometry reader. The center spawn marker is synthetic. Unknown blocks become counted magenta placeholders. This is not a playable-world or round-trip converter. Repeated renders currently preserve old output rather than reuse their cache.

Run `python3 Tests/TectonicusTests.py` from the Companion directory for synthetic regression checks. A complete macOS acceptance test additionally runs setup from an empty tool directory, renders a separately approved fixture, checks browser zoom, cancellation, latest-result restoration and an isolated GUI build. Intel builds require separate runtime/device verification; the installed architecture is selected at runtime.
