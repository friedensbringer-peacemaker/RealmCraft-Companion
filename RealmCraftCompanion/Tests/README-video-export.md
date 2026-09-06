# Video export regression checks

From the RealmCraftCompanion directory:

```sh
xcrun swiftc -module-cache-path /tmp/realmcraft-video-test-cache Sources/BuildGuideModels.swift Sources/VideoKnowledgeExport.swift Tests/VideoKnowledgeExportTests.swift -o /tmp/realmcraft-video-export-tests
/tmp/realmcraft-video-export-tests Resources/VideoTips.json
```

Checks persistent selection serialization, reviewed and pending summaries, timestamp links, deduplication, inline/forced/threshold splitting, complete JSON content, two-file writing, symlink destination protection and companion rollback.

`AIContextDocument` is defined in `Sources/VideoKnowledgeExport.swift`; include it when compiling AI export, sharing or agent handoff tests. `AgentSkillsTests.swift` additionally checks archival round trips including the supplemental video Markdown.
