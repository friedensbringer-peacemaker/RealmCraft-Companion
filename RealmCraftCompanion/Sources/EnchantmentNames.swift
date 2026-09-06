import Foundation

struct EnchantmentName: Decodable { let en: String; let de: String; let symbol: String }
enum EnchantmentNames {
    static let catalog: [String:EnchantmentName] = {
        guard let url = Bundle.main.url(forResource: "EnchantmentNames", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String:EnchantmentName].self, from: data)) ?? [:]
    }()
    static func name(_ enchantment: PlayerEnchantment, english: Bool) -> String {
        let item = catalog[String(enchantment.enchantmentID)]
        return item.map { english ? $0.en : $0.de } ?? (english ? "Unknown enchantment · ID \(enchantment.enchantmentID)" : "Unbekannte Verzauberung · ID \(enchantment.enchantmentID)")
    }
    static func label(_ enchantment: PlayerEnchantment, english: Bool) -> String {
        let roman = [1:"I",2:"II",3:"III",4:"IV",5:"V",6:"VI",7:"VII",8:"VIII",9:"IX",10:"X"]
        return name(enchantment, english: english) + " " + (roman[enchantment.level] ?? String(enchantment.level))
    }
    static func summary(_ item: PlayerItem, english: Bool) -> String {
        item.enchantments.map { label($0, english: english) }.joined(separator: " · ")
    }
}
