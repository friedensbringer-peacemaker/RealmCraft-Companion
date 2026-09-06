import Foundation

struct SkinParts: Codable, Equatable {
    var body = 0
    var shirt = 0
    var pants = 0
}
struct PlayerSkinProfile: Codable, Equatable {
    var version = 1
    var gender = "Boy"
    var boy = SkinParts()
    var girl = SkinParts()
    var configured = false
    var hand = 0
    var parts: SkinParts {
        get { gender == "Girl" ? girl : boy }
        set { if gender == "Girl" { girl = newValue } else { boy = newValue } }
    }
    static func decode(_ text: String) -> PlayerSkinProfile {
        guard let data = text.data(using: .utf8), var profile = try? JSONDecoder().decode(Self.self, from: data), profile.version == 1 else { return Self() }
        if profile.gender != "Boy" && profile.gender != "Girl" { profile.gender = "Boy" }
        profile.hand = min(max(0, profile.hand), 1)
        for gender in ["Boy", "Girl"] {
            var parts = gender == "Boy" ? profile.boy : profile.girl
            for part in ["body", "shirt", "pants"] {
                let count = SkinAssets.count(gender, part)
                let value = part == "body" ? parts.body : part == "shirt" ? parts.shirt : parts.pants
                let valid = min(max(0, value), max(0, count - 1))
                if part == "body" { parts.body = valid } else if part == "shirt" { parts.shirt = valid } else { parts.pants = valid }
            }
            if gender == "Boy" { profile.boy = parts } else { profile.girl = parts }
        }
        return profile
    }
    var encoded: String { (try? String(data: JSONEncoder().encode(self), encoding: .utf8)) ?? "" }
}
enum SkinAssets {
    static func count(_ gender: String, _ part: String) -> Int {
        switch (gender, part) {
        case (_, "body"): return 3
        case ("Girl", "shirt"): return 42
        case ("Girl", "pants"): return 40
        case (_, "shirt"): return 52
        case (_, "pants"): return 49
        default: return 0
        }
    }
    static var root: URL? { Bundle.main.resourceURL?.appendingPathComponent("PlayerSkins", isDirectory: true) }
    static func texture(_ profile: PlayerSkinProfile, _ part: String) -> URL? {
        let folder = part == "body" ? "Body" : part == "shirt" ? "Shirts" : "Pants"
        let value = part == "body" ? profile.parts.body : part == "shirt" ? profile.parts.shirt : profile.parts.pants
        return root?.appendingPathComponent("\(profile.gender)/\(folder)/\(value).png")
    }
}
