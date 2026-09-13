import SwiftUI

// Use only the catalog's explicit numeric mapping, never translated names or recipe IDs.
struct CraftingItemIcon: View {
    let itemID: Int?
    let english: Bool
    var size: CGFloat = 32
    @ObservedObject var store = ItemIconStore.shared
    @AppStorage("companionItemIcons") private var enabled = false
    @AppStorage("companionIconPack") private var selectedPack = "kenney"

    var body: some View {
        if enabled {
            Group {
                if let itemID, let image = store.image(for: itemID, pack: IconPack(rawValue: selectedPack) ?? .kenney) {
                    Image(nsImage: image).resizable().interpolation(.none).scaledToFit()
                } else {
                    Image(systemName: "square.dashed").resizable().scaledToFit().padding(size * 0.2)
                        .foregroundStyle(.secondary)
                        .help(english ? "No mapped icon in the selected pack; use the item name." : "Kein zugeordnetes Icon im gewählten Pack; maßgeblich ist der Name.")
                }
            }.frame(width: size, height: size).accessibilityHidden(true)
        }
    }
}

struct CraftingItemLabel: View {
    let id: String
    let index: CraftingIndex
    let english: Bool
    var quantity: Int? = nil
    var body: some View {
        HStack(spacing: 8) {
            CraftingItemIcon(itemID: index.items[id]?.itemID, english: english)
            Text((quantity.map { "\($0) × " } ?? "") + (index.items[id]?.title.value(english) ?? id))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
