import Foundation

private struct TranslationPattern: Decodable { let de: String; let en: String }
private let translationPatterns: [TranslationPattern] = {
    guard let url = Bundle.main.url(forResource: "patterns", withExtension: "json"),
          let data = try? Data(contentsOf: url) else { return [] }
    return (try? JSONDecoder().decode([TranslationPattern].self, from: data)) ?? []
}()
func tr(_ source: String) -> String {
    let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    guard language == "en" else { return source }
    if let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) {
        let result = bundle.localizedString(forKey: source, value: source, table: nil)
        if result != source { return result }
    }
    for item in translationPatterns {
        var expression = NSRegularExpression.escapedPattern(for: item.de)
        for index in 0...9 { expression = expression.replacingOccurrences(of: NSRegularExpression.escapedPattern(for: "{\(index)}"), with: "(.*?)") }
        guard let regex = try? NSRegularExpression(pattern: "^" + expression + "$", options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)) else { continue }
        var result = item.en
        if match.numberOfRanges > 1 {
            for i in 1..<match.numberOfRanges {
                if let range = Range(match.range(at: i), in: source) { result = result.replacingOccurrences(of: "{\(i-1)}", with: String(source[range])) }
            }
        }
        return result
    }
    return source
}
func displayDate(_ date: Date, language: String? = nil) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: (language ?? UserDefaults.standard.string(forKey: "appLanguage") ?? "en") == "en" ? "en_GB" : "de_AT")
    formatter.dateStyle = .medium; formatter.timeStyle = .medium
    return formatter.string(from: date)
}
func restoreMessage(_ save: Savegame, device: String) -> String {
    if (UserDefaults.standard.string(forKey: "appLanguage") ?? "en") == "en" {
        return "“\(save.title)” from \(displayDate(save.date)) will replace world \(save.world) on \(device). The current world will be backed up first. Keep RealmCraft closed."
    }
    return "„\(save.title)“ vom \(displayDate(save.date)) ersetzt Welt \(save.world) auf \(device). Zuerst wird der aktuelle Stand automatisch gesichert. RealmCraft muss beendet bleiben."
}

func displayCount(_ value: Int) -> String {
    let formatter = NumberFormatter(); formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: (UserDefaults.standard.string(forKey: "appLanguage") ?? "en") == "en" ? "en_GB" : "de_AT")
    return formatter.string(from: NSNumber(value: value)) ?? String(value)
}
func displayBytes(_ bytes: Int64) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var value = Double(bytes); var index = 0
    while value >= 1000 && index < units.count - 1 { value /= 1000; index += 1 }
    let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 1
    formatter.locale = Locale(identifier: (UserDefaults.standard.string(forKey: "appLanguage") ?? "en") == "en" ? "en_GB" : "de_AT")
    return (formatter.string(from: NSNumber(value: value)) ?? String(value)) + " " + units[index]
}
