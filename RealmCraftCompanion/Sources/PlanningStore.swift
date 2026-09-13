import Foundation

/// Small companion-only documents. Never substitutes an empty document after a decoding error.
struct PlanningStore<Value: Codable & Equatable> {
    let url: URL
    let empty: Value
    func load() throws -> Value {
        guard FileManager.default.fileExists(atPath: url.path) else { return empty }
        let data = try Data(contentsOf: url)
        guard data.count <= 8_000_000 else { throw PlanningError.invalid }
        return try JSONDecoder().decode(Value.self, from: data)
    }
    /// Caller holds the existing library lock across read/modify/write.
    func save(_ value: Value, replacing expected: Value) throws {
        guard try load() == expected else { throw PlanningError.changed }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        guard data.count <= 8_000_000 else { throw PlanningError.invalid }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
enum PlanningError: LocalizedError {
    case invalid, changed
    var errorDescription: String? {
        switch self {
        case .invalid: return "Invalid planning data / Ungültige Planungsdaten."
        case .changed: return "Planning data changed. Reload before continuing / Planungsdaten geändert. Vor dem Fortsetzen neu laden."
        }
    }
}
