import SwiftUI

private struct EditorSlot: Identifiable {
    let slot: Int
    let itemID: Int
    let quantity: Int
    let extra: Bool
    var id: Int { slot }
}

private struct EditorSlotGrid: View {
    let items: [EditorSlot]
    let capacity: Int
    let selected: Int?
    let choosingTarget: Bool
    let preview: EditorSlot?
    let english: Bool
    let name: (Int) -> String
    let choose: (Int) -> Void
    @ObservedObject private var icons = ItemIconStore.shared
    private let columns = Array(repeating: GridItem(.flexible(minimum: 38), spacing: 6), count: 9)
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...capacity, id: \.self) { slot in
                cell(slot)
            }
        }
    }
    private func cell(_ slot: Int) -> some View {
        let item = items.first { $0.slot == slot }
        let active = selected == slot
        let shown = item ?? (active && choosingTarget ? preview : nil)
        let available = choosingTarget ? item == nil : item != nil
        let description = "Slot \(slot): " + (item.map { "\(name($0.itemID)) × \($0.quantity)" } ?? (english ? "Empty" : "Leer"))
        return Button { choose(slot) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 7).fill(active ? Color.accentColor.opacity(0.20) : Color.primary.opacity(item == nil ? 0.035 : 0.075))
                if let shown {
                    VStack(spacing: 1) {
                        if let image = (icons.image(for: shown.itemID, pack: icons.activePack) ?? icons.image(for: shown.itemID, pack: icons.activePack == .kenney ? .pixel : .kenney)) {
                            Image(nsImage: image).resizable().interpolation(.none).scaledToFit().frame(width: 30, height: 30)
                        } else {
                            Text(String(name(shown.itemID).prefix(2)).uppercased()).font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        Text("\(shown.quantity)").font(.system(size: 10, weight: .semibold)).monospacedDigit()
                    }.padding(.top, 6)
                } else if choosingTarget {
                    Image(systemName: "plus").font(.caption).foregroundStyle(.tertiary)
                }
                VStack {
                    HStack {
                        Text("\(slot)").font(.system(size: 8)).foregroundStyle(.secondary)
                        Spacer()
                        if shown?.extra == true { Image(systemName: "sparkles").font(.system(size: 8)).foregroundStyle(.orange) }
                    }
                    Spacer()
                }.padding(4)
                RoundedRectangle(cornerRadius: 7).stroke(active ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: active ? 2 : 1)
            }.frame(height: 58).opacity(choosingTarget && item != nil ? 0.35 : 1)
        }.buttonStyle(.plain).disabled(!available).help(description)
            .accessibilityLabel(description).accessibilityValue(active ? (english ? "Selected" : "Ausgewählt") : "")
    }
}

struct SaveEditorView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    @FocusState.Binding var keyboardFocus: CompanionKeyboardFocus?
    @State private var mode = "items"
    @State private var source = "inventory"
    @State private var sourceSlot: Int?
    @State private var target = "inventory"
    @State private var targetSlot: Int?
    @State private var action = ""
    @State private var amount = "1"
    @State private var query = ""
    @State private var player: PlayerSnapshot?
    @State private var playerSaveID = ""
    @State private var playerError: String?
    @State private var review = false
    @State private var accepted = false
    @State private var testPlan: EditorTestExportPlan?
    private var en: Bool { language == "en" }
    private var inventoryReady: Bool { player != nil && playerSaveID == model.selection }
    private var records: [ChestRecord] { chests.saveID == model.selection ? (chests.index?.chests.filter(\.readable) ?? []) : [] }
    private var filtered: [ChestRecord] { records.filter { query.isEmpty || $0.id.localizedCaseInsensitiveContains(query) || $0.items.contains { chests.matches($0, query: query) } } }
    private var transfer: Bool { action == "duplicate" || action == "move" }
    private var selectedItem: EditorSlot? { slots(source).first { $0.slot == sourceSlot } }
    private var warning: String { en ? "This beta editor can irreversibly damage your savegame and negatively affect your gameplay experience." : "Dieser Beta-Editor kann dein Savegame unwiderruflich beschädigen und deine Spielerfahrung negativ beeinträchtigen." }
    private func itemName(_ id: Int) -> String { chests.name(id, english: en) }
    private func slots(_ container: String) -> [EditorSlot] {
        if container == "inventory" {
            return inventoryReady ? (player?.inventory.map { EditorSlot(slot: $0.slot, itemID: $0.itemID, quantity: $0.quantity, extra: $0.additionalData) } ?? []) : []
        }
        return records.first { $0.id == container }?.items.map { EditorSlot(slot: $0.slot, itemID: $0.itemID, quantity: $0.quantity, extra: $0.extraData) } ?? []
    }
    private func ready(_ container: String) -> Bool { container == "inventory" ? inventoryReady : records.contains { $0.id == container } }
    private func title(_ container: String) -> String { container == "inventory" ? (en ? "Backpack / inventory" : "Rucksack / Inventar") : (en ? "Chest " : "Kiste ") + container }
    private func file(_ container: String) -> String { container == "inventory" ? "player_data" : records.first { $0.id == container }?.file ?? "" }
    private func label(_ value: String) -> String {
        switch value {
        case "duplicate": return en ? "Duplicate" : "Duplizieren"
        case "move": return en ? "Move" : "Verschieben"
        case "quantity": return en ? "Quantity" : "Menge"
        case "sort": return en ? "Sort by item" : "Nach Gegenstand sortieren"
        default: return en ? "Increase level" : "Level erhöhen"
        }
    }
    private var valid: Bool {
        guard model.selected != nil else { return false }
        if mode == "level" { return inventoryReady && player?.level != nil && (Int(amount) ?? 0) > (player?.level ?? 0) && (Int(amount) ?? 0) <= 1_000_000 }
        guard maps.ready, ready(source), !action.isEmpty else { return false }
        if action == "sort" { return !slots(source).isEmpty }
        guard selectedItem != nil else { return false }
        if transfer { return ready(target) && targetSlot != nil && !slots(target).contains { $0.slot == targetSlot } }
        return (Int(amount) ?? 0) > 0 && (Int(amount) ?? 0) <= Int(Int32.max) && Int(amount) != selectedItem?.quantity
    }
    private var summary: String {
        if mode == "level" { return "Level \(player?.level ?? 0) → \(amount)" }
        if action == "sort" { return title(source) + (en ? ": sort by item ID and compact slots" : ": nach Gegenstands-ID sortieren, Slots lückenlos belegen") }
        guard let item = selectedItem else { return "" }
        var result = "\(label(action)): \(itemName(item.itemID)) × \(item.quantity)\n\(title(source)) · Slot \(item.slot)"
        if transfer { result += "\n→ \(title(target)) · Slot \(targetSlot.map(String.init) ?? "—")" }
        if action == "quantity" { result += "\n\(item.quantity) → \(amount)" }
        return result
    }
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                Label(warning, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Picker("Savegame", selection: $model.selection) {
                        Text(en ? "Select savegame" : "Spielstand wählen").tag(nil as String?)
                        ForEach(model.saves) { Text($0.title).tag(Optional($0.id)) }
                    }
                    Button { loadPlayer() } label: { Image(systemName: "arrow.clockwise") }.help(en ? "Read inventory again" : "Inventar erneut einlesen").disabled(model.selected == nil)
                }
                Picker("Editor", selection: $mode) { Text(en ? "Items" : "Gegenstände").tag("items"); Text(en ? "Player level" : "Spielerlevel").tag("level") }.pickerStyle(.segmented).frame(width: 290)
                if mode == "items" { itemWorkspace } else { levelWorkspace }
                footer
            }.padding(CompanionLayout.pageInset)
        }.disabled(model.busy)
        .onAppear { maps.check(model); loadPlayer() }
        .onChange(of: model.selection) { _, _ in reset(); loadPlayer() }
        .onChange(of: model.busy) { _, busy in if !busy && !inventoryReady && playerError == nil && model.selected != nil { loadPlayer() } }
        .onChange(of: mode) { _, _ in action = ""; targetSlot = nil; amount = mode == "level" ? String((player?.level ?? 0)+1) : "1" }
        .sheet(isPresented: $review) { reviewSheet.companionAppearance() }
        .sheet(item: $testPlan) { plan in EditorTestExportView(model: model, plan: plan, english: en).companionAppearance() }
    }
    private var header: some View {
        CompanionPageHeader(title: "Editor · Beta") {
            EmptyView()
        } menu: {
                Group {
                Button(en ? "Prepare separate Quest test world…" : "Separate Quest-Testwelt vorbereiten …") { prepareTest() }.disabled(model.selected == nil || model.serial.isEmpty)
            }
        }
    }
    private var itemWorkspace: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(en ? "Storage" : "Aufbewahrung").font(.headline)
                HStack { Text(en ? "Chests" : "Kisten").font(.subheadline.bold()); Spacer(); Button(en ? "Read" : "Einlesen") { chests.scan(model, maps: maps, english: en) }.disabled(model.selected == nil || !maps.ready) }
                TextField(en ? "Item or coordinates" : "Gegenstand oder Koordinaten", text: $query).textFieldStyle(.roundedBorder)
                storageList
                Text(en ? "↑ ↓ Select storage · ← Navigation" : "↑ ↓ Behälter wählen · ← Navigation")
                    .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.frame(width: CompanionTheme.sidebarWidth)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text(title(source)).font(.headline); Spacer(); Button { action = "sort"; targetSlot = nil } label: { Image(systemName: "arrow.up.arrow.down") }.help(label("sort")).disabled(!ready(source) || slots(source).isEmpty) }
                    if ready(source) {
                        if !transfer {
                            Text(en ? "1. Select an item" : "1. Gegenstand anklicken").font(.caption).foregroundStyle(.secondary)
                            EditorSlotGrid(items: slots(source), capacity: source == "inventory" ? 36 : 27, selected: sourceSlot, choosingTarget: false, preview: nil, english: en, name: itemName) { slot in sourceSlot = slot; action = ""; targetSlot = nil }
                        }
                        if let item = selectedItem { itemActions(item) }
                        else if action != "sort" { Text(en ? "Click an occupied slot to duplicate, move or change its quantity." : "Klicke einen belegten Slot an, um den Gegenstand zu duplizieren, zu verschieben oder seine Menge zu ändern.").font(.callout).foregroundStyle(.secondary) }
                        if transfer { targetWorkspace }
                        if action == "sort" { Text(summary).font(.callout).foregroundStyle(.secondary) }
                    } else {
                        ContentUnavailableView(en ? "No inventory loaded" : "Noch kein Inventar geladen", systemImage: "backpack", description: Text(playerError ?? (en ? "Select a savegame and read its contents." : "Spielstand auswählen und Inhalte einlesen.")))
                    }
                    if !maps.ready { Text(en ? "Set up the map tools in Maps to edit item slots." : "Für Slot-Änderungen die Kartenwerkzeuge unter Karten einrichten.").font(.caption).foregroundStyle(.secondary) }
                }.padding(.trailing, 4)
            }
        }.frame(maxHeight: .infinity)
    }
    private var storageList: some View {
                ScrollViewReader { proxy in
                    List(selection: Binding<String?>(get: { source }, set: { value in
                        if let value, value != source { chooseSource(value) }
                    })) {
                        Label(en ? "Backpack" : "Rucksack", systemImage: "backpack")
                            .padding(.vertical, 7).tag("inventory").id("inventory")
                        ForEach(filtered) { chest in
                            VStack(alignment: .leading, spacing: 3) {
                                Label(chest.dimension == "o" ? "Overworld" : "Nether", systemImage: "shippingbox")
                                Text("\(chest.x), \(chest.y), \(chest.z) · \(chest.items.count)/27").font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical, 5).tag(chest.id).id(chest.id)
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                    .focused($keyboardFocus, equals: .editorStorage)
                    .simultaneousGesture(TapGesture().onEnded { keyboardFocus = .editorStorage })
                    .onKeyPress(.upArrow) { moveStorage(-1); return .handled }
                    .onKeyPress(.downArrow) { moveStorage(1); return .handled }
                    .onKeyPress(.leftArrow) { keyboardFocus = .sidebar; return .handled }
                    .onChange(of: source) { _, value in proxy.scrollTo(value) }
                    .onChange(of: keyboardFocus) { _, value in
                        if value == .editorStorage { proxy.scrollTo(source) }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(keyboardFocus == .editorStorage ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                }
    }
    private func itemActions(_ item: EditorSlot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(itemName(item.itemID)).font(.headline); Text("× \(item.quantity)").foregroundStyle(.secondary); Spacer(); Text("Slot \(item.slot)").font(.caption).foregroundStyle(.secondary) }
            HStack {
                ForEach(["duplicate", "move", "quantity"], id: \.self) { choice in
                    Button(label(choice)) { action = choice; target = source; targetSlot = nil; amount = String(item.quantity) }.tint(action == choice ? .accentColor : .secondary)
                }
            }.buttonStyle(.bordered)
            if action == "quantity" { HStack { Text(en ? "New quantity" : "Neue Menge"); TextField("", text: $amount).textFieldStyle(.roundedBorder).frame(width: 120) } }
            if item.extra { Text(en ? "Additional data, durability and enchantments are copied with the item." : "Zusatzdaten, Haltbarkeit und Verzauberungen werden mitkopiert.").font(.caption).foregroundStyle(.secondary) }
        }
    }
    private var targetWorkspace: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack {
                Text(en ? "2. Choose an empty target slot" : "2. Leeren Zielslot wählen").font(.subheadline.bold())
                Spacer()
                Button(en ? "Cancel" : "Abbrechen") { action = ""; targetSlot = nil }
            }
            Picker(en ? "Destination" : "Ziel", selection: $target) {
                Text(en ? "Backpack / inventory" : "Rucksack / Inventar").tag("inventory")
                ForEach(records) { Text(title($0.id)).tag($0.id) }
            }.onChange(of: target) { _, _ in targetSlot = nil }
            if ready(target) {
                EditorSlotGrid(items: slots(target), capacity: target == "inventory" ? 36 : 27, selected: targetSlot, choosingTarget: true, preview: selectedItem, english: en, name: itemName) { targetSlot = $0 }
                if slots(target).count == (target == "inventory" ? 36 : 27) { Text(en ? "This container is full. Choose another destination." : "Dieser Behälter ist voll. Wähle ein anderes Ziel.").font(.caption).foregroundStyle(.orange) }
            }
        }
    }
    private var levelWorkspace: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(en ? "Player level" : "Spielerlevel", systemImage: "person.crop.rectangle").font(.title2)
            if inventoryReady, let level = player?.level {
                Text(en ? "Current level: \(level)" : "Aktuelles Level: \(level)").foregroundStyle(.secondary)
                HStack { Text(en ? "New level" : "Neues Level"); TextField("", text: $amount).textFieldStyle(.roundedBorder).frame(width: 130) }
            } else { Text(playerError ?? (en ? "No supported level field found in this savegame." : "Kein unterstütztes Level-Feld in diesem Spielstand gefunden.")).foregroundStyle(.secondary) }
            Spacer()
        }.padding(.top, 16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(en ? "Changes are saved as a new copy." : "Änderungen werden als neue Kopie gespeichert.").font(.caption)
                    if model.busy { ProgressView().controlSize(.small) }
                }.foregroundStyle(.secondary)
                Spacer()
                Button(en ? "Review change…" : "Änderung prüfen …") { accepted = false; review = true }.buttonStyle(.borderedProminent).disabled(!valid)
            }
            Text(model.status).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
        }
    }
    private var reviewSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(en ? "Save this change?" : "Diese Änderung speichern?").font(.title2.bold())
            Text(model.selected?.title ?? "").font(.subheadline).foregroundStyle(.secondary)
            Text(summary).textSelection(.enabled)
            Label(warning, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(en ? "Creates a new library save. Use the Quest test menu for a separately confirmed transfer." : "Erstellt einen neuen Bibliotheks-Spielstand. Eine Übertragung wird separat über „Quest-Test“ bestätigt.").font(.callout).foregroundStyle(.secondary)
            Toggle(en ? "I understand the risks and want to create the beta copy." : "Ich verstehe die Risiken und möchte die Beta-Kopie erstellen.", isOn: $accepted)
            HStack { Button(en ? "Cancel" : "Abbrechen") { review = false }.keyboardShortcut(.cancelAction); Spacer(); Button(en ? "Save copy" : "Kopie speichern") { apply() }.buttonStyle(.borderedProminent).disabled(!accepted || !valid) }
        }.padding(28).frame(width: 570)
    }
    private func moveStorage(_ direction: Int) {
        let ids = ["inventory"] + filtered.map(\.id)
        guard let index = ids.firstIndex(of: source) else {
            if let first = ids.first { chooseSource(first) }
            return
        }
        let next = min(max(index + direction, 0), ids.count - 1)
        if next != index { chooseSource(ids[next]) }
    }
    private func chooseSource(_ value: String) { source = value; sourceSlot = nil; action = ""; targetSlot = nil }
    private func reset() { chooseSource("inventory"); player = nil; playerSaveID = ""; playerError = nil; review = false }
    private func loadPlayer() {
        guard !model.busy, let save = model.selected else { return }
        let backend = model.library
        playerError = nil
        model.work(en ? "Reading inventory…" : "Inventar wird eingelesen …") {
            do {
                let snapshot = try PlayerReader.parse(backend.readPlayerData(save))
                DispatchQueue.main.async { guard model.selection == save.id else { return }; player = snapshot; playerSaveID = save.id; if mode == "level" { amount = String((snapshot.level ?? 0)+1) } }
                return "\(save.title) · " + (self.en ? "Inventory ready" : "Inventar bereit")
            } catch {
                DispatchQueue.main.async { guard model.selection == save.id else { return }; player = nil; playerSaveID = ""; playerError = error.localizedDescription }
                throw error
            }
        }
    }
    private func prepareTest() {
        guard let save = model.selected, !model.serial.isEmpty else { return }
        let backend = model.library, serial = model.serial, package = model.library.package, root = model.library.root, english = en
        model.work(en ? "Preparing test world…" : "Testwelt wird vorbereitet …") {
            try backend.requireClosed(serial)
            let worlds = try backend.worlds(serial)
            let copy = try backend.editorTestCopy(save, occupied: worlds)
            DispatchQueue.main.async { testPlan = EditorTestExportPlan(save: copy, sourceTitle: save.title, serial: serial, package: package, root: root, worlds: worlds) }
            return english ? "Test copy prepared; confirm transfer in the dialog." : "Testkopie vorbereitet; Übertragung im Dialog bestätigen."
        }
    }
    private func apply() {
        guard accepted, valid, let save = model.selected, let engine = Bundle.main.resourceURL?.appendingPathComponent("MapEngine") else { return }
        let request = EditorRequest(action: mode == "level" ? "level" : action, sourceFile: file(source), sourceChest: source, sourceSlot: sourceSlot ?? 1, targetFile: file(target), targetChest: target, targetSlot: targetSlot ?? 1, quantity: Int(amount) ?? 1)
        let backend = model.library, python = maps.python, english = en
        review = false
        model.work(en ? "Creating editor copy…" : "Editor-Kopie wird erstellt …") {
            let result = try backend.editorCopy(save, request: request, python: python, engine: engine)
            DispatchQueue.main.async { model.selection = result.id }
            return english ? "Created: \(result.title)" : "Erstellt: \(result.title)"
        }
    }
}
