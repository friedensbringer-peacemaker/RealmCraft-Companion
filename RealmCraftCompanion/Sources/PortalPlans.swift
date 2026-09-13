import Foundation

struct PortalPlan: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let dimension: String
    let x: Int
    let z: Int
    let referenceY: Int?
    let createdAt: Date
    var targetDimension: String { dimension == "o" ? "n" : "o" }
    var targetX: Double { dimension == "o" ? Double(x) / 8 : Double(x) * 8 }
    var targetZ: Double { dimension == "o" ? Double(z) / 8 : Double(z) * 8 }
    var targetBlockX: Int { Int(targetX.rounded(.toNearestOrAwayFromZero)) }
    var targetBlockZ: Int { Int(targetZ.rounded(.toNearestOrAwayFromZero)) }
    var valid: Bool {
        UUID(uuidString: id) != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 100 && ["o", "n"].contains(dimension)
            && (-30_000_000...30_000_000).contains(x) && (-30_000_000...30_000_000).contains(z)
            && (referenceY == nil || (0...255).contains(referenceY!)) && createdAt.timeIntervalSince1970.isFinite
    }
    var mapValue: [String: Any] {
        var result: [String: Any] = ["id": id, "name": name, "dimension": dimension, "x": x, "z": z]
        if let referenceY { result["referenceY"] = referenceY }
        return result
    }
}
struct PortalPlanStore {
    let url: URL
    struct Document: Codable { var version = 1; var plans: [PortalPlan] }
    enum StoreError: LocalizedError {
        case invalid
        var errorDescription: String? { "Portal plans could not be read or saved / Portalpläne konnten nicht gelesen oder gespeichert werden." }
    }
    func load() throws -> [PortalPlan] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        guard data.count <= 2_000_000 else { throw StoreError.invalid }
        let document = try JSONDecoder().decode(Document.self, from: data)
        guard document.version == 1, document.plans.count <= 1000, document.plans.allSatisfy(\.valid), Set(document.plans.map(\.id)).count == document.plans.count else { throw StoreError.invalid }
        return document.plans
    }
    func add(_ plan: PortalPlan) throws -> [PortalPlan] {
        guard plan.valid else { throw StoreError.invalid }
        var plans = try load()
        guard plans.count < 1000, !plans.contains(where: { $0.id == plan.id }) else { throw StoreError.invalid }
        plans.append(plan)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(Document(plans: plans)).write(to: url, options: .atomic)
        return plans
    }
    static func request(_ body: [String: Any]) -> PortalPlan? {
        guard let name = body["name"] as? String, let dimension = body["dimension"] as? String,
              let x = body["x"] as? Double, let z = body["z"] as? Double,
              x.isFinite, z.isFinite, abs(x) <= 30_000_000, abs(z) <= 30_000_000,
              x.rounded(.towardZero) == x, z.rounded(.towardZero) == z else { return nil }
        var y: Int?
        if let raw = body["referenceY"], !(raw is NSNull) {
            guard let number = raw as? Double, number.isFinite, (0...255).contains(number), number.rounded(.towardZero) == number else { return nil }
            y = Int(number)
        }
        let result = PortalPlan(id: UUID().uuidString, name: name.trimmingCharacters(in: .whitespacesAndNewlines), dimension: dimension, x: Int(x), z: Int(z), referenceY: y, createdAt: Date())
        return result.valid ? result : nil
    }
}
