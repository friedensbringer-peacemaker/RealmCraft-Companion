import SwiftUI

struct ConversationMessage: Identifiable {
    let id = UUID()
    let question: Bool
    let text: String
    var sources: [BuildSource] = []
    var interpretedQuery: String?
}

struct ConversationView: View {
    @ObservedObject var model: Model
    @ObservedObject var maps: MapController
    @ObservedObject var chests: ChestController
    let language: String
    let openMaps: () -> Void
    var openAIExport: (() -> Void)? = nil
    @StateObject private var audio = ConversationAudio()
    @State private var knowledge = ConversationKnowledge(recipes: [], guides: [])
    @State private var recipeSearch = ""
    @State private var showCrafting = false
    @State private var messages: [ConversationMessage] = []
    @State private var draft = ""
    @State private var catalogNotice = ""
    @State private var intelligenceNotice = ""
    @AppStorage("conversation.provider") private var provider = "qwen"
    @AppStorage("conversation.spokenLanguage") private var spokenLanguage = "de"
    @State private var checkingLocal = false
    @State private var showLocalSetup = false
    @State private var showConversationSettings = false
    @State private var thinking = false
    @State private var answerTask: Task<Void, Never>?
    @State private var answerToken = UUID()
    @State private var places: [CompanionPlace] = []
    @State private var showLibrary = false
    @State private var showChests = false
    @State private var spawn: CompanionSpawnPoint?
    @State private var spawnNotice = ""
    @State private var spawnRequest = UUID()
    @State private var ownedIDs: Set<String> = []
    @State private var chestLabels: [String: String] = [:]
    @Environment(\.companionTheme) private var theme
    private var en: Bool { language == "en" }
    private var spokenEnglish: Bool { spokenLanguage == "en" }
    private var hints: [String] { places.map(\.name) + knowledge.recipes.map { $0.title.value(spokenEnglish) } }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: en ? "Conversation · Beta" : "Gespräch · Beta") {
                Button { showConversationSettings = true } label: {
                    Label(en ? "Conversation settings" : "Gesprächseinstellungen", systemImage: "slider.horizontal.3")
                }
            } menu: {
                Group {
                    Button(en ? "My chests" : "Eigene Kisten") { showChests = true }
                    Button(en ? "Places & recipes" : "Orte & Rezepte") { showLibrary.toggle() }
                    Button(en ? "Name places in Maps" : "Orte in Karten benennen", action: openMaps)
                    if let openAIExport { Button(en ? "AI export" : "KI-Export", action: openAIExport) }
                    Divider()
                    Button(en ? "New conversation" : "Neues Gespräch") { reset() }.disabled(messages.isEmpty)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                SourceContextBar(saves: model.saves, selection: $model.selection, language: language)
                    .frame(maxWidth: .infinity).disabled(model.busy)
                if model.selected == nil {
                    Text(en ? "Knowledge-only: ask about recipes or build guides. Choose a backup for questions about places and stored items." : "Nur Wissen: Frage nach Rezepten oder Bauanleitungen. Für Orte und gelagerte Gegenstände wähle eine Sicherung.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text((spokenEnglish ? "English" : "Deutsch") + " · " + (provider == "qwen" ? "Qwen3.5-4B" : provider == "apple" ? "Apple Intelligence" : (en ? "Basic lookup" : "Einfache Suche")) + " · " + (en ? "Saved data · answers may be incorrect" : "Gespeicherte Daten · Antworten können fehlerhaft sein"))
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 16)
            Divider()
            if showLibrary { libraryPanel; Divider() }
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        if messages.isEmpty { welcome }
                        ForEach(messages) { message in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(message.question ? (en ? "You" : "Du") : "Companion", systemImage: message.question ? "person.crop.circle" : "waveform")
                                    .font(.caption.bold()).foregroundStyle(.secondary)
                                if let interpreted = message.interpretedQuery { Text((en ? "Understood as: " : "Verstanden als: ") + interpreted).font(.caption).foregroundStyle(.secondary) }
                                Text(message.text).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                                if !message.sources.isEmpty {
                                    ForEach(message.sources.indices, id: \.self) { index in
                                        Link(message.sources[index].title, destination: message.sources[index].url).font(.caption)
                                    }
                                }
                            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                .background(message.question ? theme.accent.opacity(0.10) : theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: theme.radius)).id(message.id)
                        }
                    }.padding(CompanionLayout.pageInset)
                }.onChange(of: messages.count) { _, _ in if let id = messages.last?.id { scroll.scrollTo(id, anchor: .bottom) } }
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                if !intelligenceNotice.isEmpty { Text(intelligenceNotice).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                if thinking { HStack { ProgressView().controlSize(.small); Text(en ? "Understanding your question…" : "Frage verstehen …").font(.callout) } }
                if !catalogNotice.isEmpty { Text(catalogNotice).font(.caption).foregroundStyle(.orange) }
                if !audio.notice.isEmpty { Text(audio.notice).font(.callout).foregroundStyle(.orange).textSelection(.enabled) }
                HStack {
                    Image(systemName: audio.listening ? "mic.fill" : audio.speaking ? "speaker.wave.2.fill" : "mic")
                        .foregroundStyle(audio.listening ? Color.red : theme.accent)
                    Text(audio.preparing ? (en ? "Preparing microphone…" : "Mikrofon vorbereiten …") : audio.listening ? (en ? "Listening · a short pause sends your question" : "Höre zu · eine kurze Pause sendet deine Frage") : audio.speaking ? (en ? "Speaking · microphone is off" : "Spreche · Mikrofon ist aus") : (en ? "Ready · type or start the microphone" : "Bereit · tippe oder starte das Mikrofon"))
                        .font(.callout)
                    Spacer()
                    if thinking || audio.listening || audio.preparing || audio.speaking || audio.continuous {
                        Button(en ? "Stop" : "Stopp") { stopAll() }.keyboardShortcut(.escape, modifiers: [])
                    }
                }
                if audio.listening {
                    HStack {
                        Text(audio.inputDeviceName.isEmpty ? (en ? "Microphone level" : "Mikrofonpegel") : audio.inputDeviceName).font(.caption)
                        ProgressView(value: audio.inputLevel).frame(width: 130)
                        Text((en ? "Recognition: " : "Erkennung: ") + (spokenEnglish ? "English" : "Deutsch")).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(en ? "No level? Select your microphone in System Settings → Sound → Input. Virtual Desktop Mic needs an active headset connection."
                         : "Kein Ausschlag? Wähle dein Mikrofon unter Systemeinstellungen → Ton → Eingabe. Virtual Desktop Mic benötigt eine aktive Headset-Verbindung.").font(.caption).foregroundStyle(.secondary)
                }
                if audio.listening && !audio.transcript.isEmpty { Text(audio.transcript).font(.callout).foregroundStyle(.secondary).lineLimit(3) }
                HStack(spacing: 12) {
                    TextField(en ? "Ask about a place or recipe…" : "Frage zu einem Ort oder Rezept …", text: $draft)
                        .textFieldStyle(.roundedBorder).onSubmit { submitDraft() }
                        .accessibilityLabel(en ? "Your question" : "Deine Frage")
                    Button(en ? "Send" : "Senden") { submitDraft() }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button {
                        if audio.listening { audio.finishQuestion() }
                        else { audio.start(language: spokenLanguage, hints: hints) }
                    } label: {
                        Label(audio.listening ? (en ? "Answer now" : "Jetzt antworten") : (en ? "Microphone" : "Mikrofon"), systemImage: audio.listening ? "checkmark" : "mic.fill")
                    }.buttonStyle(CompanionButtonStyle(prominent: true)).disabled(audio.preparing || thinking)
                        .keyboardShortcut("m", modifiers: [.command, .shift])
                }
            }.padding(CompanionLayout.pageInset)
        }
        .onAppear { load(); audio.onQuestion = { ask($0) }; audio.onDraft = { draft = $0 }; refreshPlaces(); maps.check(model); readSpawn() }
        .sheet(isPresented: $showConversationSettings) { conversationSettingsPanel.companionAppearance() }
        .onChange(of: spokenLanguage) { _, _ in reset(); readSpawn() }
        .onChange(of: provider) { _, _ in reset(); updateIntelligenceStatus() }
        .sheet(isPresented: $showChests) { ownedChestsPanel.companionAppearance() }
        .onDisappear { stopAll(); audio.onQuestion = nil; audio.onDraft = nil }
        .onChange(of: model.selection) { _, _ in reset(); refreshPlaces(); readSpawn() }
        .onChange(of: model.library.root) { _, _ in reset(); refreshPlaces(); readSpawn() }
        .onChange(of: language) { _, _ in reset(); audio.onQuestion = { ask($0) }; load(); readSpawn() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in refreshPlaces() }
    }
    private var conversationSettingsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(en ? "Conversation settings" : "Gesprächseinstellungen").font(.title2.bold())
                Spacer()
                Button(en ? "Done" : "Fertig") { showConversationSettings = false }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(en ? "Speech & microphone" : "Sprache & Mikrofon").font(.headline)
                HStack(spacing: 20) {
                    Toggle(en ? "Read answers aloud" : "Antworten vorlesen", isOn: $audio.readAnswers)
                        .onChange(of: audio.readAnswers) { _, enabled in if !enabled { audio.cancel() } }
                    Toggle(en ? "Conversation mode" : "Gesprächsmodus", isOn: $audio.continuous)

                }.toggleStyle(.checkbox)
                Toggle(en ? "Review recognized text before sending" : "Erkannten Text vor dem Senden prüfen", isOn: $audio.reviewBeforeSend).toggleStyle(.checkbox)
                Toggle(en ? "Send automatically after a pause" : "Nach einer Sprechpause automatisch senden", isOn: $audio.autoSend).toggleStyle(.checkbox)
                Text(en ? "Turn off for longer questions; finish with Answer now. A pause of 2.5 seconds sends automatically when enabled." : "Für längere Fragen ausschalten und mit Jetzt antworten abschließen. Bei aktivierter Automatik sendet eine Pause von 2,5 Sekunden.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Picker(en ? "Speech & answer language" : "Sprache für Erkennung & Antworten", selection: $spokenLanguage) {
                        Text("Deutsch").tag("de")
                        Text("English").tag("en")
                    }.frame(maxWidth: 360)
                    Button(en ? "Mac microphone settings…" : "Mac-Mikrofon einstellen …") { openMicrophoneSettings() }
                }
                Text(en ? "Choose the language you speak here, independently of the interface. Mac Sound settings select the microphone, not the recognition language."
                     : "Wähle hier deine gesprochene Sprache, unabhängig von der Oberfläche. Unter Ton am Mac wählst du das Mikrofon, nicht die Erkennungssprache.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Text(en ? "Uses the Mac's selected microphone and audio output. The Quest microphone is not connected automatically. Conversation mode listens again after each answer; Stop ends it."
                     : "Verwendet das gewählte Mac-Mikrofon und die Mac-Tonausgabe. Das Quest-Mikrofon ist nicht automatisch verbunden. Der Gesprächsmodus hört nach jeder Antwort erneut zu; Stopp beendet ihn.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

                    Divider()
                    Text(en ? "Local AI" : "Lokale KI").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker(en ? "Question understanding" : "Fragen verstehen", selection: $provider) {
                        Text("Qwen3.5-4B · LM Studio").tag("qwen")
                        Text("Apple Intelligence").tag("apple")
                        Text(en ? "Basic lookup" : "Einfache Suche").tag("basic")
                    }.frame(maxWidth: 390).disabled(thinking)
                    if provider == "qwen" {
                        Button(en ? "Check connection" : "Verbindung prüfen") { checkLocal() }.disabled(checkingLocal)
                        Button(en ? "Setup" : "Einrichten") { showLocalSetup.toggle() }
                    }
                    Spacer()
                }
                Text(intelligenceNotice).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            }

                    if showLocalSetup { localSetupPanel }
                    Divider()
                    Text(en ? "Beta: recognition and answers may be incorrect. Locations and inventories come from saved data, not live gameplay."
                         : "Beta: Erkennung und Antworten können fehlerhaft sein. Orte und Bestände stammen aus gespeicherten Daten, nicht aus dem laufenden Spiel.").font(.caption).foregroundStyle(.secondary)
                }.padding(.trailing, 8)
            }
        }.padding(24).frame(width: 700, height: 550)
    }
    private func openMicrophoneSettings() {
        stopAll()
        // Sound's input anchor is a macOS deep link; retain an explicit manual path
        // because the destination can vary between macOS releases.
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound?input")!
        if !NSWorkspace.shared.open(url) {
            audio.notice = en ? "Open System Settings → Sound → Input." : "Öffne Systemeinstellungen → Ton → Eingabe."
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
    private func updateIntelligenceStatus() {
        if provider == "apple" { intelligenceNotice = ConversationIntelligence.status(english: en) }
        else if provider == "qwen" { intelligenceNotice = en ? "Qwen3.5-4B · localhost:1234 · check connection before use" : "Qwen3.5-4B · localhost:1234 · vor Verwendung Verbindung prüfen" }
        else { intelligenceNotice = en ? "Basic lookup · no language model" : "Einfache Suche · kein Sprachmodell" }
    }
    private func checkLocal() {
        checkingLocal = true
        Task { @MainActor in
            do {
                let id = try await ConversationLocalModel.modelID()
                if provider == "qwen" { intelligenceNotice = (en ? "Local server ready · " : "Lokaler Server bereit · ") + id }
            } catch {
                if provider == "qwen" { intelligenceNotice = (en ? "Start LM Studio and its local server. " : "Starte LM Studio und seinen lokalen Server. ") + error.localizedDescription }
            }
            checkingLocal = false
        }
    }
    private var localSetupPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Qwen3.5-4B · LM Studio").font(.title2.bold())
            Text(en ? "1. Install LM Studio on your Apple Silicon Mac.\n2. Search for lmstudio-community/Qwen3.5-4B-MLX-4bit and download the 4-bit MLX version (about 3.1 GB).\n3. Load the model. Use a short context, e.g. 4096 tokens.\n4. In Developer, start the server on port 1234. Keep network access off; this Companion connects only to 127.0.0.1.\n5. Close this guide and click Check connection. Then ask what you need for a bed."
                 : "1. Installiere LM Studio auf deinem Mac mit Apple Silicon.\n2. Suche lmstudio-community/Qwen3.5-4B-MLX-4bit und lade die MLX-Version mit 4 Bit (ca. 3,1 GB).\n3. Lade das Modell. Verwende einen kurzen Kontext, z. B. 4096 Tokens.\n4. Starte unter Developer den Server auf Port 1234. Netzwerkzugriff ausgeschaltet lassen; der Companion verbindet sich nur mit 127.0.0.1.\n5. Schließe diese Anleitung und klicke Verbindung prüfen. Frage anschließend, was du für ein Bett brauchst.")
                .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            HStack {
                Link("LM Studio", destination: URL(string: "https://lmstudio.ai/download")!)
                Link(en ? "Recommended model" : "Empfohlenes Modell", destination: URL(string: "https://huggingface.co/lmstudio-community/Qwen3.5-4B-MLX-4bit")!)
            }
            Text(en ? "Plan for 5–8 GB free disk space; 16 GB RAM recommended. No cloud subscription or API key. The model interprets questions; counts, coordinates and recipe evidence come from the Companion's local records."
                 : "Plane 5–8 GB freien Speicherplatz ein; 16 GB RAM empfohlen. Kein Cloud-Abo oder API-Schlüssel. Das Modell versteht Fragen; Zahlen, Koordinaten und Rezeptbelege kommen aus den lokalen Daten des Companions.").font(.caption).foregroundStyle(.secondary)
            HStack { Spacer(); Button(en ? "Close setup guide" : "Anleitung schließen") { showLocalSetup = false } }
        }.padding(24).frame(width: 620)
    }
    private var ownedChestsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(en ? "My chests" : "Eigene Kisten").font(.title2.bold())
                Spacer()
                Button(en ? "Done" : "Fertig") { showChests = false }
            }
            Text(en ? "Only select chests you own. NPC containers are excluded by leaving them unchecked. Ownership is saved per world and coordinate, not detected automatically. Recheck your selection after replacing a chest."
                 : "Markiere nur Kisten, die dir gehören. NPC-Kisten bleiben unmarkiert. Der Besitz wird pro Welt und Koordinate gespeichert, nicht automatisch erkannt. Prüfe die Auswahl, wenn eine Kiste ersetzt wurde.")
                .font(.callout)
            if let save = model.selected { Text(save.title + " · " + displayDate(save.date, language: language)).font(.caption).foregroundStyle(.secondary) }
            HStack {
                Button(en ? "Read selected savegame's chests" : "Kisten des gewählten Spielstands einlesen") { chests.scan(model, maps: maps, english: en) }
                    .disabled(model.busy || !maps.ready || model.selected == nil || maps.checking)
                if model.busy { ProgressView().controlSize(.small); Text(tr(model.status)).font(.caption) }
                Spacer()
            }
            if !maps.ready { MapToolsSetup(model: model, maps: maps, english: en) }
            if chests.saveID == model.selection, let index = chests.index {
                Text(en ? "\(ownedIDs.count) marked · \(index.chests.count) indexed · \(index.errors.count) scan issue(s)" : "\(ownedIDs.count) markiert · \(index.chests.count) eingelesen · \(index.errors.count) Probleme beim Einlesen").font(.caption)
                List(index.chests) { chest in
                    VStack(alignment: .leading) {
                    Toggle(isOn: Binding(get: { ownedIDs.contains(chest.id) }, set: { own in
                        if own { ownedIDs.insert(chest.id) } else { ownedIDs.remove(chest.id) }
                        if let world = model.selected?.annotationScope { UserDefaults.standard.set(Array(ownedIDs).sorted(), forKey: "conversation.ownedChests." + world) }
                    })) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chest.coordinates + " · " + (chest.dimension == "o" ? (en ? "Overworld" : "Oberwelt") : "Nether")).font(.headline)
                            if chest.readable {
                                Text(chest.items.prefix(6).map { "\($0.quantity) × " + chests.name($0.itemID, english: en) }.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                            } else { Text(en ? "Unreadable; counting will report an incomplete result." : "Nicht lesbar; die Auskunft meldet ein unvollständiges Ergebnis.").font(.caption).foregroundStyle(.orange) }
                        }
                    }.toggleStyle(.checkbox).padding(.vertical, 4)
                    if ownedIDs.contains(chest.id) {
                        TextField(en ? "Chest name, e.g. Tool storage" : "Kistenname, z. B. Werkzeuglager", text: Binding(get: { chest.displayName(manual: chestLabels[chest.id]) ?? "" }, set: { value in
                            chestLabels[chest.id] = String(value.prefix(80))
                            if let world = model.selected?.annotationScope { UserDefaults.standard.set(chestLabels, forKey: "conversation.chestLabels." + world) }
                        })).textFieldStyle(.roundedBorder)
                    }
                    }
                }
            } else { Text(en ? "Read this savegame first to choose its chests." : "Lies diesen Spielstand zuerst ein, um seine Kisten auszuwählen.").foregroundStyle(.secondary).frame(maxHeight: .infinity) }
        }.padding(24).frame(width: 730, height: 570)
    }
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "bubble.left.and.waveform.bubble.right").font(.system(size: 34)).foregroundStyle(theme.accent)
            Text(en ? "Talk to your Companion" : "Sprich mit deinem Companion").font(.title2.bold())
            Text(en ? "Start with one of these questions. You can follow up with “What do I need for that?” or “Repeat”."
                 : "Starte mit einer dieser Fragen. Danach kannst du mit „Was brauche ich dafür?“ oder „Nochmal“ nachfragen.")
            ForEach(en ? ["Where is my house?", "What are my spawn coordinates?", "Can I craft a bed?", "How many diamonds do I have?"] : ["Wo ist mein Haus?", "Wo ist mein Spawnpunkt?", "Kann ich ein Bett craften?", "Wie viele Diamanten habe ich?"], id: \.self) { prompt in
                Button(prompt) { ask(prompt) }.buttonStyle(.link)
            }
            Text(en ? "Recipe references are labeled with their source and VR verification status. The selected local model helps interpret questions when available; facts come from local records."
                 : "Rezeptreferenzen nennen ihre Quelle und den VR-Prüfstatus. Das gewählte lokale Modell hilft beim Verstehen der Fragen, sofern verfügbar; Fakten kommen aus lokalen Datensätzen.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 20)
    }
    private var libraryPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(en ? "Named places in this world" : "Benannte Orte dieser Welt").font(.headline)
                if places.isEmpty { Text(en ? "No named places yet. Name a marker in Maps first." : "Noch keine benannten Orte. Benenne zuerst eine Markierung unter Karten.").foregroundStyle(.secondary) }
                ForEach(places) { place in
                    Button(place.description(en)) { ask((en ? "Where is " : "Wo ist ") + place.name + "?") }.buttonStyle(.link)
                }
                Text(en ? "Recipe references · not verified in VR" : "Rezeptreferenzen · nicht in VR geprüft").font(.headline)
                TextField(en ? "Quick recipe search · name or ID" : "Schnelle Rezeptsuche · Name oder ID", text: $recipeSearch).textFieldStyle(.roundedBorder)
                if let index = knowledge.crafting?.index, !recipeSearch.isEmpty {
                    let matches = index.filtered(query: recipeSearch, english: en)
                    Text(en ? "\(matches.count) matches; showing up to 12" : "\(matches.count) Treffer; maximal 12 angezeigt").font(.caption)
                    ForEach(Array(matches.prefix(12))) { item in
                        Button { ask((en ? "How do I craft " : "Wie crafte ich ") + item.title.value(en) + "?") } label: {
                            CraftingItemLabel(id: item.id, index: index, english: en)
                        }.buttonStyle(.link)
                    }
                }
                Button(en ? "Open recipes & material plan" : "Rezepte & Materialplan öffnen") { showCrafting = true }
                ForEach(knowledge.recipes) { recipe in
                    Button(recipe.title.value(en)) { ask((en ? "How do I craft " : "Wie crafte ich ") + recipe.title.value(en) + "?") }.buttonStyle(.link)
                }
                Text(en ? "Build guides" : "Bauanleitungen").font(.headline)
                ForEach(knowledge.guides) { guide in
                    Button(guide.title.value(en)) { ask(guide.title.value(en)) }.buttonStyle(.link)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }.frame(height: 210)
        .sheet(isPresented: $showCrafting) { CraftingView(language: language).frame(minWidth: 1000, minHeight: 720) }
    }
    private func load() {
        var issues: [String] = []
        let recipes: [ConversationRecipe]
        let guides: [BuildGuide]
        do { recipes = try ConversationRecipe.load() } catch { recipes = []; issues.append(en ? "Recipe catalog could not be loaded." : "Rezeptkatalog konnte nicht geladen werden.") }
        do { guides = try BuildCatalog.load().guides } catch { guides = []; issues.append(en ? "Build guides could not be loaded." : "Bauanleitungen konnten nicht geladen werden.") }
        let crafting: CraftingIndex?
        do { crafting = try CraftingCatalog.load().index() }
        catch { crafting = nil; issues.append(en ? "Extended recipe catalog unavailable." : "Erweiterter Rezeptkatalog nicht verfügbar.") }
        knowledge = ConversationKnowledge(recipes: recipes, guides: guides, craftingIndex: crafting)
        catalogNotice = issues.joined(separator: " ")
        updateIntelligenceStatus()
    }
    private func refreshPlaces() {
        let names = model.selected.flatMap { UserDefaults.standard.dictionary(forKey: "atlasPOI." + $0.annotationScope) as? [String: String] } ?? [:]
        let updated = CompanionPlace.named(names)
        if updated != places { places = updated }
        let ids = model.selected.map { UserDefaults.standard.stringArray(forKey: "conversation.ownedChests." + $0.annotationScope) ?? [] } ?? []
        let updatedIDs = Set(ids)
        if updatedIDs != ownedIDs { ownedIDs = updatedIDs }
        let labels = model.selected.flatMap { UserDefaults.standard.dictionary(forKey: "conversation.chestLabels." + $0.annotationScope) as? [String: String] } ?? [:]
        if labels != chestLabels { chestLabels = labels }
    }
    private func readSpawn() {
        spawn = nil
        let token = UUID(); spawnRequest = token
        guard let save = model.selected else { spawnNotice = ""; return }
        let en = spokenEnglish, backend = model.library, root = model.library.root
        spawnNotice = en ? "Reading saved respawn point… Please ask again in a moment." : "Gespeicherter Respawnpunkt wird gelesen … Bitte frage gleich noch einmal."
        model.queue.async {
            let result = Result { () throws -> CompanionSpawnPoint? in
                let data = try backend.readPlayerData(save)
                _ = try PlayerReader.parse(data)
                return CompanionSpawnPoint.parse(data)
            }
            DispatchQueue.main.async {
                guard spawnRequest == token, model.selection == save.id, model.library.root == root else { return }
                switch result {
                case .success(let point): spawn = point; spawnNotice = ""
                case .failure(let error): spawn = nil; spawnNotice = (en ? "Could not verify or read the saved respawn point: " : "Gespeicherter Respawnpunkt konnte nicht geprüft oder gelesen werden: ") + error.localizedDescription
                }
            }
        }
    }
    private func stopAll() { answerToken = UUID(); answerTask?.cancel(); answerTask = nil; thinking = false; audio.cancel() }
    private func reset() { stopAll(); knowledge.reset(); messages = []; draft = "" }
    private func submitDraft() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        audio.cancel(); draft = ""; ask(question)
    }
    private func ask(_ question: String) {
        if ["stopp", "stop", "ruhe", "gesprach beenden", "end conversation"].contains(ConversationKnowledge.normalized(question)) { stopAll(); return }
        answerTask?.cancel()
        let token = UUID(); answerToken = token
        refreshPlaces()
        updateIntelligenceStatus()
        let recent = messages.suffix(4).map { ($0.question ? "User: " : "Companion: ") + String($0.text.prefix(500)) }.joined(separator: "\n")
        messages.append(ConversationMessage(question: true, text: question))
        thinking = true
        answerTask = Task { @MainActor in
            let storage = model.selected.map { save in
                CompanionStorageContext(savedAt: save.gameDate, backupAt: save.date, index: chests.saveID == save.id ? chests.index : nil, ownedIDs: ownedIDs, itemNames: chests.names, chestLabels: chestLabels)
            }
            var directKnowledge = knowledge
            let direct: CompanionAnswer
            if ["materialplan", "mein materialplan", "lies meinen materialplan", "material plan", "my material plan", "read my material plan"].contains(ConversationKnowledge.normalized(question)), let index = knowledge.crafting?.index {
                do {
                    let plan = try CraftingPlanStorage(url: CraftingPlanStorage.defaultURL, empty: CraftingPlan(catalog: CraftingPlan.fingerprint(index))).load()
                    let reply = CraftingConversation.planAnswer(plan, index: index, english: spokenEnglish)
                    direct = CompanionAnswer(text: reply.text, spokenText: reply.spoken)
                } catch { direct = CompanionAnswer(text: error.localizedDescription) }
                directKnowledge.remember(direct, world: model.selected?.world, english: spokenEnglish)
            } else {
                direct = directKnowledge.answer(question, world: model.selected?.world, places: places, english: spokenEnglish, storage: storage, spawn: spawn, spawnNotice: spawnNotice)
            }
            var query = question
            if direct.handled { intelligenceNotice = en ? "Answered from local records" : "Aus lokalen Daten beantwortet" }
            if !direct.handled && (provider == "qwen" || provider == "apple") {
                do {
                    if provider == "qwen" {
                        query = try await ConversationLocalModel.canonicalQuestion(question, recipes: knowledge.recipes, guides: knowledge.guides, places: places, recent: recent)
                        guard answerToken == token, !Task.isCancelled else { return }
                        intelligenceNotice = en ? "Qwen3.5-4B · question processed locally" : "Qwen3.5-4B · Frage lokal verarbeitet"
                    } else {
                        query = try await ConversationIntelligence.canonicalQuestion(question, recipes: knowledge.recipes, guides: knowledge.guides, places: places, recent: recent)
                    }
                }
                catch {
                    guard answerToken == token else { return }
                    intelligenceNotice = (en ? "AI unavailable; basic lookup used. " : "KI nicht erreichbar; einfache Suche verwendet. ") + error.localizedDescription
                }
            }
            guard answerToken == token, !Task.isCancelled else { return }
            let answer: CompanionAnswer
            if query == question { knowledge = directKnowledge; answer = direct }
            else { answer = knowledge.answer(String(query.prefix(1000)), world: model.selected?.world, places: places, english: spokenEnglish, storage: storage, spawn: spawn, spawnNotice: spawnNotice) }
            messages.append(ConversationMessage(question: false, text: answer.text, sources: answer.sources, interpretedQuery: query == question ? nil : query))
            if messages.count > 100 { messages.removeFirst(messages.count - 100) }
            thinking = false; answerTask = nil
            audio.speak(answer.spokenText ?? answer.text, language: spokenLanguage)
        }
    }
}
