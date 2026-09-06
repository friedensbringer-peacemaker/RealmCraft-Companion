import Foundation

@main struct MobFeedbackTests {
    static func main() throws {
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = try JSONDecoder().decode(MobCatalog.self, from: Data(contentsOf: source))
        try catalog.validate()
        precondition(catalog.entries.filter { $0.status == "released" }.count == 24)
        precondition(catalog.entries.first { $0.id == "horse" }?.status == "planned")
        precondition(catalog.entries.first { $0.id == "chicken" }?.status == "unverified")
        precondition(catalog.entries.allSatisfy { $0.habitat?.isValid == true })
        precondition(catalog.entries.first { $0.id == "baby_hoglin" }?.name.en == "Hoglin (Baby)")
        for english in [false, true] {
            let sorted = catalog.entries.sorted { $0.name.value(english).localizedStandardCompare($1.name.value(english)) == .orderedAscending }.map(\.id)
            precondition(sorted.firstIndex(of: "baby_hoglin")! == sorted.firstIndex(of: "hoglin")! + 1)
            precondition(sorted.firstIndex(of: "baby_piglin")! == sorted.firstIndex(of: "piglin")! + 1)
        }
        precondition(catalog.entries.count == 47)
        let babies = catalog.entries.filter { $0.id.hasPrefix("baby_") }
        precondition(babies.count == 20)
        precondition(babies.allSatisfy { $0.name.de.contains("Baby)") && $0.name.en.contains("Baby)") && !$0.name.en.hasPrefix("Baby ") })
        precondition(babies.filter { $0.status == "released" }.count == 2)
        precondition(catalog.entries.first { $0.id == "baby_zombie" }?.name.en == "Zombie (Baby)")
        precondition(catalog.entries.first { $0.id == "baby_cow" }?.status == "unverified")
        precondition(catalog.entries.first { $0.id == "baby_zombified_piglin" }?.name.de == "Piglin (Zombifiziert, Baby)")
        let hoglin = catalog.entries.first { $0.id == "baby_hoglin" }!
        precondition(hoglin.matches("hoglin baby nether") && hoglin.habitat?.basis == "vr_release")
        precondition(catalog.entries.first { $0.id == "ocelot" }!.matches("dschungel"))
        precondition(catalog.entries.first { $0.id == "zoglin" }?.habitat?.dimension == "unknown")
        precondition(catalog.entries.first { $0.id == "horse" }?.habitat?.dimension == "unknown")
        let piglin = catalog.entries.first { $0.id == "zombified_piglin" }!
        precondition(piglin.matches("zombifiziert piglin"))
        precondition(piglin.matches("1.0.3"))
        precondition(!piglin.matches("cat"))
        precondition(MobArtwork.available.count == 24)
        precondition(MobArtwork.referenceID(for: "baby_cow") == "cow")
        precondition(MobArtwork.referenceID(for: "baby_zombified_piglin") == "zombified_piglin")
        precondition(MobArtwork.referenceID(for: "horse") == nil)
        precondition(MobArtwork.referenceID(for: "../../cow") == nil)
        for id in MobArtwork.available {
            precondition(MobArtwork.url(for: id, resources: source.deletingLastPathComponent()) != nil)
        }
        precondition(MobArtwork.url(for: "cow", resources: URL(fileURLWithPath: "/nonexistent")) == nil)
        let image = FeedbackAttachment(data: Data([1, 2, 3]), fileExtension: "png")
        let report = FeedbackReport(schemaVersion: 1, createdAt: "2026-09-06T00:00:00Z", type: "data",
            summary: "Quotes \" and Unicode 🐾", description: "line 1\nline 2: {nested}\n# not a comment",
            stepsToReproduce: "a\\b", expectedResult: "ÄÖÜ", actualResult: "wrong",
            application: ["version": "test"], context: FeedbackContext(area: "mobs", entryID: piglin.id),
            attachments: FeedbackReport.attachmentNames([image]), catalogNotice: MobCatalog.disclaimer(false))
        let decoded = try JSONDecoder().decode(FeedbackReport.self, from: Data(try report.document().utf8))
        precondition(decoded.description == report.description && decoded.summary == report.summary)
        precondition(decoded.context.entryID == piglin.id && decoded.catalogNotice != nil)
        let staging = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: staging) }
        let files = try report.writePackage(to: staging, images: [image])
        precondition(files.map(\.lastPathComponent) == ["report.hjson", "screenshot-01.png"])
        let savedImage = try Data(contentsOf: files[1])
        precondition(savedImage == image.data)
        do { _ = try report.writePackage(to: staging, images: []); fatalError("Mismatched attachments accepted") }
        catch is CocoaError { }
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: files[0])) as! [String: Any]
        precondition(json["deviceSerial"] == nil && json["savegame"] == nil)
        let archive = staging.appendingPathComponent("archive.zip")
        try report.writeArchive(to: archive, images: [image])
        let unzip = Process()
        let output = Pipe()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-Z", "-1", archive.path]
        unzip.standardOutput = output
        try unzip.run()
        let names = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        unzip.waitUntilExit()
        precondition(unzip.terminationStatus == 0 && !names.contains("._") && !names.contains("__MACOSX"))
        precondition(names.contains("report.hjson") && names.contains("screenshot-01.png"))
        print("PASS: catalog evidence, bilingual search, multiline Hjson/JSON round-trip, attachment export, metadata-free ZIP and mismatch rejection")
    }
}
