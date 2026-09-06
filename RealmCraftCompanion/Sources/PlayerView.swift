import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor final class PlayerController: ObservableObject {
    @Published var snapshot: PlayerSnapshot?
    @Published var source = ""
    @Published var readAt: Date?
    @Published var quest = true
    @Published var query = ""
    @Published var refreshError: String?
    private var sourceKey: String?
    private func key(_ model: Model) -> String {
        if quest { return "quest:\(model.serial):\(model.library.package):\(model.world)" }
        return "backup:\(model.library.root.path):\(model.selection ?? "")"
    }
    func validateSource(_ model: Model) {
        if sourceKey != key(model) { reset() }
    }
    func reset() { snapshot = nil; source = ""; readAt = nil; sourceKey = nil; refreshError = nil }
    func read(_ model: Model, quest: Bool, english: Bool) {
        guard !model.busy, !model.scanning else { return }
        let backend = model.library, serial = model.serial, world = model.world, save = model.selected
        let remote = backend.remote
        guard quest ? (!serial.isEmpty && backend.validWorld(world)) : save != nil else { return }
        validateSource(model)
        let requestedKey = key(model)
        refreshError = nil
        model.work(english ? "Reading player data…" : "Spielerdaten werden gelesen …") {
            do {
            let data: Data
            let source: String
            if quest {
                let temp = FileManager.default.temporaryDirectory.appendingPathComponent("RealmCraft-player-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: temp) }
                let first = temp.appendingPathComponent("first"), second = temp.appendingPathComponent("second")
                let path = remote + "/" + world + "/player_data"
                _ = try backend.command(serial, ["pull", path, first.path], timeout: 30)
                _ = try backend.command(serial, ["pull", path, second.path], timeout: 30)
                data = try Data(contentsOf: first)
                guard try data == Data(contentsOf: second) else {
                    throw PlayerReadError(english ? "The game saved during reading. Please try again." : "Das Spiel hat während des Auslesens gespeichert. Bitte erneut versuchen.")
                }
                source = "Quest · \(world)"
            } else {
                guard let save else { throw PlayerReadError("No savegame / Kein Spielstand") }
                data = try backend.readPlayerData(save)
                source = "\(save.title) · \(save.world) · \(displayDate(save.date, language: english ? "en" : "de"))"
            }
            let result = try PlayerReader.parse(data)
            DispatchQueue.main.async {
                guard self.key(model) == requestedKey else { return }
                self.snapshot = result; self.source = source; self.readAt = Date(); self.sourceKey = requestedKey
            }
            return english ? "Player data ready. Saved state; savegame unchanged." : "Spielerdaten bereit. Gespeicherter Stand; Spielstand unverändert."
            } catch {
                DispatchQueue.main.async { self.refreshError = english ? "Refresh failed. Any displayed data is from the previous successful read." : "Aktualisierung fehlgeschlagen. Angezeigte Daten stammen aus der letzten erfolgreichen Abfrage." }
                throw error
            }
        }
    }
    func export(_ model: Model) {
        guard let snapshot, let readAt else { return }
        struct Export: Encodable { let source: String; let readAt: Date; let player: PlayerSnapshot }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "RealmCraft-Player.json"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
                try encoder.encode(Export(source: source, readAt: readAt, player: snapshot)).write(to: url, options: .atomic)
            } catch { model.error = error.localizedDescription }
        }
    }
}

struct PlayerView: View {
    @ObservedObject var model: Model
    @ObservedObject var player: PlayerController
    @ObservedObject var names: ChestController
    let language: String
    @Environment(\.companionTheme) private var theme
    @AppStorage("realmcraft.playerSkin.v1") private var skinJSON = ""
    @State private var showSkinEditor = false
    private var skinProfile: PlayerSkinProfile { PlayerSkinProfile.decode(skinJSON) }
    private var english: Bool { language == "en" }
    private var unavailable: Bool { model.busy || model.scanning || (player.quest ? (model.serial.isEmpty || model.world.isEmpty || model.setup.package.isEmpty) : model.selected == nil) }
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Player" : "Spieler") {
                Button(player.snapshot == nil ? (english ? "Read player" : "Spieler auslesen") : (english ? "Refresh" : "Aktualisieren")) { player.read(model, quest: player.quest, english: english) }
                    .buttonStyle(CompanionButtonStyle(prominent: true)).disabled(unavailable).keyboardShortcut("r", modifiers: .command)
                Button(english ? "Skin…" : "Skin …") { showSkinEditor = true }
                Menu {
                    Button(english ? "Export JSON" : "JSON exportieren") { player.export(model) }.disabled(player.snapshot == nil)
                    Button(english ? "Quest setup…" : "Quest einrichten …") { model.showSetup = true }
                    Button(english ? "Check connection" : "Verbindung prüfen") { model.connect() }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).fixedSize().disabled(model.busy)
                    .accessibilityLabel(english ? "Player actions" : "Spieler-Aktionen")
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Picker(english ? "Source" : "Quelle", selection: $player.quest) {
                        Text("Quest").tag(true); Text(english ? "Backup" : "Sicherung").tag(false)
                    }.pickerStyle(.segmented).frame(width: 220)
                    if player.quest {
                        Picker(english ? "World" : "Welt", selection: $model.world) { ForEach(model.worlds, id: \.self) { Text($0).tag($0) } }.frame(maxWidth: 340)
                    } else {
                        Picker(english ? "Savegame" : "Spielstand", selection: $model.selection) {
                            ForEach(model.saves) { save in Text(save.title + " · " + displayDate(save.date, language: language)).tag(Optional(save.id)) }
                        }.frame(maxWidth: 480)
                    }
                }.disabled(model.busy || model.scanning)
                Text(english ? "Reads the last saved state, not live gameplay. Save in RealmCraft before refreshing. No game files are changed." : "Liest den zuletzt gespeicherten Stand, keine Live-Spielwerte. Vor dem Aktualisieren in RealmCraft speichern. Spieldateien werden nicht verändert.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if model.busy { ProgressView().controlSize(.small); Text(tr(model.status)) }
                    else if let error = player.refreshError { Text(error).foregroundStyle(.orange) }
                    Spacer()
                }.font(.caption).frame(height: 20, alignment: .leading)
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            if let snapshot = player.snapshot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(snapshot.level.map { "Level \($0)" } ?? (english ? "Level unavailable" : "Level nicht lesbar")).font(.largeTitle.bold())
                                Text(player.source).font(.callout).textSelection(.enabled)
                                if let date = player.readAt { Text((english ? "Read: " : "Ausgelesen: ") + displayDate(date, language: language)).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Text(english ? "\(snapshot.inventory.count) / 36 inventory slots" : "\(snapshot.inventory.count) / 36 Inventarplätze").monospacedDigit().foregroundStyle(.secondary)
                        }
                        HStack(alignment: .center, spacing: 30) {
                            VStack(spacing: 10) {
                                if skinProfile.configured {
                                    PlayerSkinScene(profile: skinProfile, armor: snapshot.armor).frame(width: 235, height: 300)
                                    Text(english ? "Your manually selected skin" : "Dein manuell ausgewählter Skin").font(.caption).foregroundStyle(.secondary)
                                    Text(english ? "Armor colors approximated" : "Rüstungsfarben angenähert").font(.caption2).foregroundStyle(.secondary)
                                } else {
                                    PlayerAvatar(armor: snapshot.armor, names: names, english: english)
                                }
                                Button(english ? "Choose skin…" : "Skin auswählen …") { showSkinEditor = true }
                            }
                            VStack(alignment: .leading, spacing: 12) {
                            Label(english ? "Equipped armor" : "Angelegte Rüstung", systemImage: "shield.fill").font(.title2.bold())
                            ForEach([4,3,2,1], id: \.self) { slot in
                                HStack {
                                    Text(armorSlot(slot)).frame(width: 110, alignment: .leading).foregroundStyle(.secondary)
                                    if let item = snapshot.armor.first(where: { $0.slot == slot }) {
                                        ItemIcon(itemID: item.itemID)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(names.name(item.itemID, english: english)).bold()
                                            enchantmentText(item)
                                            durabilityText(item)
                                        }
                                    }
                                    else { Text(english ? "Empty" : "Leer").foregroundStyle(.secondary) }
                                    Spacer()
                                }
                            }
                        }
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(theme.surface).clipShape(RoundedRectangle(cornerRadius: theme.radius))
                        HStack {
                            Text(english ? "Inventory & weapons" : "Inventar & Waffen").font(.title2.bold())
                            Spacer()
                            TextField(english ? "Search items or ID" : "Gegenstand oder ID suchen", text: $player.query).textFieldStyle(.roundedBorder).frame(width: 260)
                        }
                        let items = snapshot.inventory.filter { player.query.isEmpty || "\(names.name($0.itemID, english: true)) \(names.name($0.itemID, english: false)) \($0.itemID) \(EnchantmentNames.summary($0, english: true)) \(EnchantmentNames.summary($0, english: false))".localizedStandardContains(player.query) }
                        if items.isEmpty { Text(english ? "No items to display." : "Keine Gegenstände anzuzeigen.").foregroundStyle(.secondary) }
                        ForEach(items) { item in
                            HStack(spacing: 16) {
                                Text("\(item.slot)").monospacedDigit().frame(width: 28).foregroundStyle(.secondary)
                                ItemIcon(itemID: item.itemID)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(names.name(item.itemID, english: english)).font(.headline)
                                    Text(verbatim: "ID \(item.itemID)").font(.caption).foregroundStyle(.secondary)
                                    enchantmentText(item)
                                    durabilityText(item)
                                }
                                Spacer(); Text("× \(item.quantity)").font(.headline).monospacedDigit()
                            }
                            Divider()
                        }
                        Text(english ? "Durability shows the saved remaining value. Health and hunger are not yet reliably decoded. Unknown enchantments are shown by ID." : "Die Resthaltbarkeit zeigt den gespeicherten Restwert. Leben und Hunger werden noch nicht zuverlässig ausgewertet. Unbekannte Verzauberungen erscheinen als ID.").font(.caption).foregroundStyle(.secondary)
                    }.padding(CompanionLayout.pageInset)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.rectangle").font(.system(size: 46)).foregroundStyle(theme.accent)
                    Text(english ? "Your player at a glance" : "Dein Spieler auf einen Blick").font(.title.bold())
                    Text(english ? "Choose Quest or a backup, then read your level, inventory and equipped armor." : "Wähle Quest oder eine Sicherung und lies Level, Inventar und angelegte Rüstung aus.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: player.quest) { _, _ in player.validateSource(model) }
        .onChange(of: model.selection) { _, _ in if !player.quest { player.validateSource(model) } }
        .onChange(of: model.world) { _, _ in if player.quest { player.validateSource(model) } }
        .onChange(of: model.serial) { _, _ in if player.quest { player.validateSource(model) } }
        .onAppear { player.validateSource(model) }
        .sheet(isPresented: $showSkinEditor) {
            PlayerSkinEditor(saved: $skinJSON, armor: player.snapshot?.armor ?? [], english: english)
        }
    }
    @ViewBuilder private func enchantmentText(_ item: PlayerItem) -> some View {
        if !item.enchantments.isEmpty {
            Text(EnchantmentNames.summary(item, english: english))
                .font(.caption).foregroundStyle(theme.block ? Color(red: 0.80, green: 0.70, blue: 1) : Color.purple)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    @ViewBuilder private func durabilityText(_ item: PlayerItem) -> some View {
        if let remaining = item.durability {
            VStack(alignment: .leading, spacing: 3) {
                if let fraction = item.durabilityFraction, let maximum = item.durabilityMaximum {
                    let warning = item.durabilityWarning
                    let color: Color = warning == .critical ? .red : warning == .caution ? .orange : theme.accent
                    HStack(spacing: 6) {
                        Text(english ? "Durability: \(remaining) / \(maximum) · \(remaining * 100 / maximum)%" : "Haltbarkeit: \(remaining) / \(maximum) · \(remaining * 100 / maximum)%")
                        if warning == .critical {
                            Label(english ? "Critical · <20%" : "Kritisch · <20 %", systemImage: "exclamationmark.octagon.fill")
                                .foregroundStyle(.red).fontWeight(.bold)
                        } else if warning == .caution {
                            Label(english ? "Worn · <50%" : "Abgenutzt · <50 %", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange).fontWeight(.bold)
                        }
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.20))
                        Capsule().fill(color).frame(width: 180 * fraction)
                    }.frame(width: 180, height: 7)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(english ? "Remaining durability" : "Verbleibende Haltbarkeit")
                        .accessibilityValue("\(remaining) / \(maximum)")
                    repairText(item)
                } else {
                    Text(english ? "Durability: \(remaining) remaining · maximum unknown or incompatible · repair forecast unavailable" : "Haltbarkeit: \(remaining) verbleibend · Maximum unbekannt oder abweichend · Reparaturprognose nicht möglich")
                }
            }
            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .help(english ? "Saved remaining value; maximum from the supported game definitions. Orange below 50%, red below 20%. Enchantments affect wear, not this ratio." : "Gespeicherter Restwert; Maximum aus den unterstützten Spieldefinitionen. Orange unter 50 %, rot unter 20 %. Verzauberungen beeinflussen den Verschleiß, nicht dieses Verhältnis.")
        }
    }
    @ViewBuilder private func repairText(_ item: PlayerItem) -> some View {
        if let forecast = RepairForecast.forItem(item) {
            VStack(alignment: .leading, spacing: 2) {
                if let material = english ? forecast.materialEN : forecast.materialDE {
                    Text(english ? "Repair estimate to 100%: \(forecast.count) × \(material)" : "Reparaturprognose bis 100 %: \(forecast.count) × \(material)")
                    Text(english ? "Anvil + XP levels · verify suggested material and level cost in the anvil." : "Amboss + Erfahrungsstufen · Materialvorschlag und Stufenkosten im Amboss prüfen.")
                } else if let minimum = forecast.donorMinimum {
                    Text(english ? "Repair estimate to 100%: 1 × same item with at least \(minimum) durability" : "Reparaturprognose bis 100 %: 1 × gleicher Gegenstand mit mindestens \(minimum) Haltbarkeit")
                    Text(english ? "Anvil + XP levels · the second item is consumed; check the level cost." : "Amboss + Erfahrungsstufen · der zweite Gegenstand wird verbraucht; Stufenkosten prüfen.")
                }
            }.fixedSize(horizontal: false, vertical: true)
        } else if item.durabilityFraction == 1 {
            Text(english ? "Fully intact · no repair needed" : "Vollständig intakt · keine Reparatur nötig")
        }
    }
    private func armorSlot(_ slot: Int) -> String {
        switch slot { case 4: return english ? "Helmet" : "Helm"; case 3: return english ? "Chestplate" : "Brustpanzer"; case 2: return english ? "Leggings" : "Beinschutz"; default: return english ? "Boots" : "Stiefel" }
    }
}
