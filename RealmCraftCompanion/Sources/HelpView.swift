import SwiftUI
import AppKit
import UniformTypeIdentifiers

private func releaseDocument(_ name: String) -> String {
    guard let url = Bundle.main.url(forResource: name, withExtension: "md"),
          let content = try? String(contentsOf: url, encoding: .utf8) else { return "This document is unavailable in this build." }
    return content
}

struct HelpView: View {
    @Environment(\.companionLookup) private var lookup
    private func applyLookup() {
        guard let lookup, lookup.kind == .guide, allArticles.contains(where: { $0.id == lookup.item }) else { return }
        search = ""; selected = lookup.item; history = []
    }
    @Environment(\.companionTheme) private var theme
    let embedded: Bool
    private let result: Result<[HelpArticle], Error>
    @AppStorage("appLanguage") private var language = "en"
    @AppStorage("lastHelpTopic") private var selected = "start"
    @State private var search = ""
    @State private var history: [String] = []
    @State private var sourceError: String?
    @State private var copiedInstructions = false

    init(embedded: Bool = false, resources: URL? = Bundle.main.resourceURL) {
        self.embedded = embedded
        result = Result {
            guard let resources else { throw HelpCatalog.LoadError.invalid }
            return try HelpCatalog.load(resources: resources)
        }
    }
    private var english: Bool { language == "en" }
    private var allArticles: [HelpArticle] { (try? result.get()) ?? [] }
    private var articles: [HelpArticle] { HelpCatalog.filtered(allArticles, query: search) }
    private var article: HelpArticle? {
        let visible = articles
        guard let id = HelpCatalog.visibleID(selected: selected, in: visible) else { return nil }
        return visible.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Help" : "Hilfe") {
                if !history.isEmpty {
                    Button {
                        guard let id = history.popLast() else { return }
                        search = ""; selected = id
                    } label: { Label(english ? "Previous topic" : "Vorheriges Thema", systemImage: "chevron.left") }
                }
                if !embedded {
                    Picker("Language / Sprache", selection: $language) { Text("Deutsch").tag("de"); Text("English").tag("en") }
                        .labelsHidden().frame(width: 110)
                }
                TextField(english ? "Search all help · DE / EN" : "Gesamte Hilfe suchen · DE / EN", text: $search)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: CompanionLayout.searchWidth)
                    .accessibilityIdentifier("help.search")
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle") }
                        .accessibilityLabel(english ? "Clear search" : "Suche zurücksetzen")
                }
            }
            switch result {
            case .failure(let error):
                ContentUnavailableView(english ? "Help unavailable" : "Hilfe nicht verfügbar",
                    systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
            case .success:
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(english ? "\(articles.count) topics" : "\(articles.count) Themen")
                            .font(.caption).foregroundStyle(.secondary).padding(12)
                        List(selection: $selected) {
                            ForEach(HelpCategory.allCases) { category in
                                let topics = articles.filter { $0.category == category }
                                if !topics.isEmpty {
                                    Section(category.title(english: english)) {
                                        ForEach(topics) { topic in
                                            Label(topic.title(english), systemImage: topic.icon)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.vertical, 5).tag(topic.id)
                                        }
                                    }
                                }
                            }
                        }.listStyle(.sidebar).scrollContentBackground(.hidden)
                    }.frame(width: CompanionLayout.illustratedSidebarWidth).background(theme.surface)
                    Divider()
                    if let article {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 22) {
                                Label(article.title(english), systemImage: article.icon).font(CompanionLayout.detailTitle)
                                HelpParagraphs(content: article.content(english)).lineSpacing(3)
                                if article.id == "development" {
                                    Button(action: exportSource) {
                                        Label(english ? "Export complete source ZIP…" : "Vollständigen Quellcode als ZIP exportieren…", systemImage: "square.and.arrow.up")
                                    }.buttonStyle(CompanionButtonStyle(prominent: true))
                                }
                                if article.id == "agent" { agentActions }
                                if !article.related.isEmpty {
                                    Divider()
                                    Text(english ? "Related topics" : "Weiterführende Themen").font(.headline)
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(article.related, id: \.self) { id in
                                            if let target = allArticles.first(where: { $0.id == id }) {
                                                Button {
                                                    history.append(article.id)
                                                    if history.count > 30 { history.removeFirst() }
                                                    search = ""; selected = id
                                                } label: { Label(target.title(english), systemImage: target.icon) }
                                                .accessibilityIdentifier("help.related." + id)
                                            }
                                        }
                                    }
                                }
                                if ["setup", "manualTransfer", "trouble"].contains(article.id) { setupLinks }
                            }.padding(CompanionLayout.pageInset).frame(maxWidth: 880, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
                        }.id(article.id + language).accessibilityIdentifier("help.article." + article.id)
                    } else {
                        ContentUnavailableView {
                            Label(english ? "No matching topics" : "Keine passenden Themen", systemImage: "magnifyingglass")
                        } description: {
                            Text(english ? "Try a shorter term, a menu name or the other language." : "Versuche einen kürzeren Begriff, einen Menünamen oder die andere Sprache.")
                        } actions: {
                            Button(english ? "Show all topics" : "Alle Themen anzeigen") { search = "" }
                        }
                    }
                }
            }
        }.frame(minWidth: embedded ? 0 : 900, minHeight: embedded ? 0 : 600)
        .environment(\.locale, Locale(identifier: language))
        .onAppear(perform: applyLookup)
        .onChange(of: lookup) { _, _ in applyLookup() }
        .onChange(of: search) { _, _ in
            if let id = HelpCatalog.visibleID(selected: selected, in: articles) { selected = id }
        }
        .onChange(of: selected) { _, _ in copiedInstructions = false }
        .onChange(of: language) { _, _ in copiedInstructions = false }
        .alert(english ? "Export failed" : "Export fehlgeschlagen", isPresented: Binding(get: { sourceError != nil }, set: { if !$0 { sourceError = nil } })) {
            Button("OK") { sourceError = nil }
        } message: { Text(sourceError ?? "") }
    }
    private var agentActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(english ? "Save agent instructions as MD…" : "Agent-Anleitung als MD speichern …") {
                exportResource("AGENT-SETUP-" + language, extension: "md")
            }.buttonStyle(CompanionButtonStyle(prominent: true))
            Button(english ? "Copy agent instructions" : "Agent-Instruktionen kopieren") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(releaseDocument("AGENT-SETUP-" + language), forType: .string)
                copiedInstructions = true
            }
            if copiedInstructions { Text(english ? "Copied. Paste into your preferred AI chat." : "Kopiert. Im gewünschten KI-Chat einfügen.").font(.caption).foregroundStyle(.secondary) }
        }
    }
    private var setupLinks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text(english ? "Official setup references" : "Offizielle Einrichtungsquellen").font(.headline)
            Link("Google · Android Platform Tools", destination: URL(string: "https://developer.android.com/tools/releases/platform-tools")!)
            Link(english ? "Meta · Set up your device" : "Meta · Gerät einrichten", destination: URL(string: "https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/")!)
            Link(english ? "Meta · Create a developer team" : "Meta · Entwicklerteam erstellen", destination: URL(string: "https://developers.meta.com/horizon/manage/organizations/create/")!)
            Link(english ? "Meta · Verify your account" : "Meta · Konto verifizieren", destination: URL(string: "https://developers.meta.com/horizon/manage/verify/")!)
            Link(english ? "Apple · Open apps safely" : "Apple · Apps sicher öffnen", destination: URL(string: english ? "https://support.apple.com/en-gb/102445" : "https://support.apple.com/de-de/102445")!)
        }.buttonStyle(.plain).foregroundStyle(theme.accent).font(.callout)
    }
    private func exportSource() { exportResource("CommunitySource", extension: "zip") }
    private func exportResource(_ name: String, extension fileExtension: String) {
        guard let source = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            sourceError = english ? "The requested document is missing from this app build." : "Das angeforderte Dokument fehlt in dieser App-Version."
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: fileExtension) ?? .plainText]
        panel.nameFieldStringValue = name == "CommunitySource" ? "RealmCraft-Savegame-Library-Source.zip" : "RealmCraft-" + name + "." + fileExtension
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        do {
            try Data(contentsOf: source).write(to: destination, options: .atomic)
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch { sourceError = error.localizedDescription }
    }
}

struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("appLanguage") private var language = "en"
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(language == "en" ? "RealmCraft Companion Help" : "RealmCraft Companion Hilfe") { openWindow(id: "help") }.keyboardShortcut("?", modifiers: .command)
        }
    }
}

struct HelpParagraphs: View {
    @Environment(\.companionTheme) private var theme
    let content: String

    var body: some View {
        let blocks = HelpBlock.parse(content)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks.indices, id: \.self) { index in
                switch blocks[index] {
                case .heading(let text):
                    Text(text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.block ? theme.accent : Color.primary)
                        .padding(.top, index == 0 ? 0 : 12)
                        .padding(.bottom, 10)
                        .accessibilityAddTraits(.isHeader)
                case .paragraph(let text):
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 18)
                case .item(let marker, let text):
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(marker)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.block ? theme.accent : Color.primary)
                            .frame(minWidth: 26, alignment: .trailing)
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 14)
                }
            }
        }
        .font(.system(size: 14))
        .lineSpacing(5)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
}
