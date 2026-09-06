import SwiftUI

struct PlayerSkinEditor: View {
    @Binding var saved: String
    let armor: [PlayerItem]
    let english: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var draft = PlayerSkinProfile()
    @State private var showArmor = false
    @State private var hands = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(english ? "Choose your skin" : "Deinen Skin auswählen").font(.title2.bold())
                Spacer()
                Button(english ? "Cancel" : "Abbrechen") { dismiss() }.keyboardShortcut(.cancelAction)
                Button(english ? "Use skin" : "Skin übernehmen") {
                    draft.configured = true; saved = draft.encoded; dismiss()
                }.keyboardShortcut(.defaultAction)
            }
            Text(english ? "Match the body, shirt and pants you selected in RealmCraft. This is a manual Companion profile; it does not change your game." : "Wähle Körper, Oberteil und Hose passend zu deiner Auswahl in RealmCraft. Dieses manuelle Companion-Profil verändert deinen Spielcharakter nicht.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 12) {
                    PlayerSkinScene(profile: draft, armor: showArmor ? armor : [], hands: hands)
                        .frame(width: 290, height: 380)
                    Picker(english ? "Preview" : "Vorschau", selection: $hands) {
                        Text(english ? "Character" : "Charakter").tag(false)
                        Text(english ? "VR hand" : "VR-Hand").tag(true)
                    }.pickerStyle(.segmented)
                    Text(english ? "Drag to rotate · scroll to zoom" : "Ziehen zum Drehen · Scrollen zum Zoomen").font(.caption).foregroundStyle(.secondary)
                    Toggle(english ? "Show saved armor" : "Gespeicherte Rüstung anzeigen", isOn: $showArmor)
                        .disabled(armor.isEmpty || hands)
                }
                VStack(alignment: .leading, spacing: 22) {
                    Picker(english ? "Character model" : "Charaktermodell", selection: $draft.gender) {
                        Text(english ? "Male" : "Männlich").tag("Boy")
                        Text(english ? "Female" : "Weiblich").tag("Girl")
                    }.pickerStyle(.segmented)
                    choice("body", english ? "Body" : "Körper")
                    choice("shirt", english ? "Shirt" : "Oberteil")
                    choice("pants", english ? "Pants" : "Hose")
                    Picker(english ? "VR hand model" : "VR-Handmodell", selection: $draft.hand) {
                        Text(english ? "Variant 1" : "Variante 1").tag(0)
                        Text(english ? "Variant 2" : "Variante 2").tag(1)
                    }.onChange(of: draft.hand) { _, _ in hands = true }
                    Text(english ? "Preview approximation; in-game appearance has not been compared yet. The numbers identify the original game textures. Each character model keeps its own selection. Armor comes from the last player read." : "Angenäherte Vorschau; der Abgleich mit dem Spiel steht noch aus. Die Nummern bezeichnen die Originaltexturen des Spiels. Jedes Charaktermodell behält seine eigene Auswahl. Die Rüstung stammt aus dem zuletzt ausgelesenen Spielerstand.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.frame(width: 285)
            }
        }.padding(24).frame(width: 650)
            .onAppear { draft = PlayerSkinProfile.decode(saved) }
    }
    private func choice(_ part: String, _ title: String) -> some View {
        let value = part == "body" ? draft.parts.body : part == "shirt" ? draft.parts.shirt : draft.parts.pants
        let count = SkinAssets.count(draft.gender, part)
        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            HStack {
                Button { change(part, (value + count - 1) % count) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel((english ? "Previous " : "Vorherige Auswahl: ") + title)
                Picker(title, selection: Binding(get: { value }, set: { change(part, $0) })) {
                    ForEach(0..<count, id: \.self) { index in
                        Text("\(index + 1) / \(count)").tag(index)
                    }
                }.labelsHidden().frame(maxWidth: .infinity)
                Button { change(part, (value + 1) % count) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel((english ? "Next " : "Nächste Auswahl: ") + title)
            }
        }
    }
    private func change(_ part: String, _ value: Int) {
        var parts = draft.parts
        if part == "body" { parts.body = value } else if part == "shirt" { parts.shirt = value } else { parts.pants = value }
        draft.parts = parts
    }
}
