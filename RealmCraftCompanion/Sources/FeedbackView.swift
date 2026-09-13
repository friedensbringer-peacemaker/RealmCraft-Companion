import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class FeedbackMail: NSObject, ObservableObject, NSSharingServiceDelegate {
    @Published var status = ""
    private var service: NSSharingService?
    private var staging: URL?
    var english = false

    func compose(report: FeedbackReport, images: [FeedbackAttachment], recipient: String) throws {
        guard let mail = NSSharingService(named: .composeEmail) else { throw CocoaError(.featureUnsupported) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RealmCraft-Report-\(UUID().uuidString)")
        let files = try report.writePackage(to: directory, images: images)
        let items: [Any] = [try report.document()] + files.map { $0 as Any }
        guard mail.canPerform(withItems: items) else {
            try? FileManager.default.removeItem(at: directory)
            throw CocoaError(.featureUnsupported)
        }
        staging = directory
        service = mail
        mail.delegate = self
        mail.subject = "RealmCraft Companion · \(report.summary)"
        let address = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        mail.recipients = address.isEmpty ? [] : [address]
        mail.perform(withItems: items)
        status = english ? "Mail draft requested. Review recipients and attachments in Mail before sending." : "Mail-Entwurf angefordert. Empfänger und Anhänge vor dem Senden in Mail prüfen."
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        status = error.localizedDescription
        cleanup()
    }
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        status = english ? "Handed to your mail app." : "An dein Mailprogramm übergeben."
        cleanup()
    }
    private func cleanup() {
        if let staging { try? FileManager.default.removeItem(at: staging) }
        staging = nil
        service = nil
    }
}

struct FeedbackView: View {
    let context: FeedbackContext
    let english: Bool
    var sourceWindow: NSWindow? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.draftTransitions) private var sharedDrafts
    @State private var localDrafts = DraftTransitions()
    @State private var draftID = UUID()
    @State private var savedToken: String?
    @AppStorage("companionSkin") private var skin = "block"
    @StateObject private var mail = FeedbackMail()
    @State private var kind = "data"
    @State private var summary = ""
    @State private var details = ""
    @State private var steps = ""
    @State private var expected = ""
    @State private var actual = ""
    @State private var recipient = ""
    @State private var images: [FeedbackAttachment] = []
    @State private var created = ISO8601DateFormatter().string(from: Date())
    @State private var message = ""
    @State private var preview = false

    private var report: FeedbackReport {
        FeedbackReport(schemaVersion: 1, createdAt: created, type: kind, summary: summary,
                       description: details, stepsToReproduce: steps, expectedResult: expected, actualResult: actual,
                       application: ["name": "RealmCraft Companion", "version": AppInfo.version,
                                     "os": ProcessInfo.processInfo.operatingSystemVersionString,
                                     "language": english ? "en" : "de", "appearance": skin],
                       context: context, attachments: FeedbackReport.attachmentNames(images),
                       catalogNotice: context.area == "mobs" ? MobCatalog.disclaimer(english) : nil)
    }
    private var ready: Bool { !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var draftToken: String {
        DraftTransitions.fingerprint([kind, summary, details, steps, expected, actual, recipient] + images.map { $0.id.uuidString })
    }
    private var dirty: Bool {
        if let savedToken { return savedToken != draftToken }
        return kind != "data" || ![summary, details, steps, expected, actual, recipient].allSatisfy(\.isEmpty) || !images.isEmpty
    }
    private var drafts: DraftTransitions { sharedDrafts ?? localDrafts }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(english ? "Report data / bug" : "Daten / Bug melden", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                    .font(.title2.bold())
                Spacer()
                Button(english ? "Close" : "Schließen") { drafts.perform { dismiss() } }.keyboardShortcut(.cancelAction)
            }
            Text(english ? "Area: \(context.area)\(context.entryName.map { " · " + $0 } ?? "")" : "Bereich: \(context.area)\(context.entryName.map { " · " + $0 } ?? "")")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker(english ? "Report type" : "Art der Meldung", selection: $kind) {
                        Text(english ? "Incorrect data" : "Falsche Daten").tag("data")
                        Text(english ? "Application bug" : "Anwendungsfehler").tag("bug")
                        Text(english ? "Feature request" : "Funktionswunsch").tag("suggestion")
                    }.pickerStyle(.segmented)
                    TextField(english ? "Summary (required)" : "Kurztitel (Pflichtfeld)", text: $summary)
                    Text(english ? "Description / correction (required)" : "Beschreibung / Korrektur (Pflichtfeld)").font(.headline)
                    FeedbackTextArea(text: $details,
                                     label: english ? "Description / correction" : "Beschreibung / Korrektur",
                                     placeholder: english ? "What went wrong? Describe the problem or the correct information…" : "Was ist passiert? Beschreibe den Fehler oder die richtige Angabe …")
                    TextField(english ? "Steps to reproduce" : "Schritte zum Nachstellen", text: $steps, axis: .vertical).lineLimit(2...4)
                    TextField(english ? "Expected result" : "Erwartetes Ergebnis", text: $expected, axis: .vertical).lineLimit(1...3)
                    TextField(english ? "Actual result" : "Tatsächliches Ergebnis", text: $actual, axis: .vertical).lineLimit(1...3)
                    HStack {
                        Button(english ? "Add screenshots…" : "Screenshots hinzufügen …") { addImages() }
                        Button(english ? "Capture app window" : "App-Fenster aufnehmen") { captureWindow() }.disabled(sourceWindow == nil)
                        Text("\(images.count) / 5").foregroundStyle(.secondary)
                    }.disabled(images.count >= 5)
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            if let image = NSImage(data: item.data) { Image(nsImage: image).resizable().scaledToFit().frame(width: 90, height: 60) }
                            Text(FeedbackReport.attachmentNames(images)[index]).font(.caption)
                            Spacer()
                            Button(english ? "Remove" : "Entfernen") { images.removeAll { $0.id == item.id } }
                        }
                    }
                    Text(english ? "Includes area, app version, macOS, language and appearance; selected entry and source links where available. Images are added only by you. Review their contents before sharing. No savegames or device identifiers are collected."
                         : "Enthält Bereich, App-Version, macOS, Sprache und Optik sowie ggf. Eintrag und Quellenlinks. Bilder fügst du selbst hinzu; prüfe ihren Inhalt vor dem Teilen. Spielstände und Gerätekennungen werden nicht erfasst.")
                        .font(.caption).foregroundStyle(.secondary)
                    DisclosureGroup(english ? "Preview report · JSON / Hjson" : "Meldung prüfen · JSON / Hjson", isExpanded: $preview) {
                        Text((try? report.document()) ?? "").font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(10).companionPanel()
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(english ? "GitHub issues are public. Review your text for personal information. Only your form entries, app version, operating system and language are copied; images and entry context are not included."
                                 : "GitHub-Issues sind öffentlich. Prüfe deinen Text auf persönliche Angaben. Kopiert werden nur deine Formularangaben, App-Version, Betriebssystem und Sprache; Bilder und Eintragskontext sind nicht enthalten.")
                                .font(.caption).foregroundStyle(.secondary)
                            DisclosureGroup(english ? "Preview GitHub text · Markdown" : "GitHub-Text prüfen · Markdown") {
                                Text(report.githubMarkdown(english: english))
                                    .font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            ViewThatFits(in: .horizontal) {
                                HStack { githubActions }
                                VStack(alignment: .leading) { githubActions }
                            }.disabled(!ready)
                            Text(english ? "Open GitHub copies the text and opens a blank issue form. Sign in there, paste the text, add a title and publish it yourself. For screenshots, review and attach them manually on GitHub. Copy also works offline."
                                 : "GitHub öffnen kopiert den Text und öffnet ein leeres Issue-Formular. Melde dich dort an, füge den Text ein, ergänze den Titel und veröffentliche selbst. Screenshots prüfst du separat und hängst sie auf GitHub an. Kopieren funktioniert auch offline.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    } label: { Text(english ? "Bugs & feature requests on GitHub" : "Bugs & Funktionswünsche auf GitHub") }
                    TextField(english ? "Mail recipient (optional; can be filled in Mail)" : "Mail-Empfänger (optional; in Mail ergänzbar)", text: $recipient)
                    Text(english ? "Mail opens a draft with the report and images. You choose the recipient and send it yourself. ZIP export works without a mail app."
                         : "Mail öffnet einen Entwurf mit Meldung und Bildern. Du wählst den Empfänger und sendest selbst. Der ZIP-Export funktioniert ohne Mailprogramm.")
                        .font(.caption).foregroundStyle(.secondary)
                }.textFieldStyle(.roundedBorder)
            }
            if !message.isEmpty { Text(message).font(.caption).textSelection(.enabled) }
            if !mail.status.isEmpty { Text(mail.status).font(.caption).textSelection(.enabled) }
            HStack {
                Button(english ? "Copy text" : "Text kopieren") {
                    perform { let text = try report.document(); NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string); message = english ? "Report copied; images are included only in ZIP or Mail." : "Meldung kopiert; Bilder sind nur in ZIP oder Mail enthalten." }
                }
                Button(english ? "Export ZIP…" : "ZIP exportieren …") { export() }
                Spacer()
                Button(english ? "Open mail draft…" : "Mail-Entwurf öffnen …") {
                    perform { mail.english = english; try mail.compose(report: report, images: images, recipient: recipient) }
                }.buttonStyle(CompanionButtonStyle(prominent: true))
            }.disabled(!ready)
        }.padding(24).frame(minWidth: 620, idealWidth: 760, maxWidth: .infinity, minHeight: 480, idealHeight: 640, maxHeight: .infinity)
        .trackDraft(drafts, id: draftID, token: draftToken, dirty: { dirty },
                    title: english ? "Feedback · Save exports a ZIP of the report and images, not the mail recipient." : "Meldung · Speichern exportiert Meldung und Bilder als ZIP, nicht den Mail-Empfänger.",
                    save: { export() }, discard: {
                        kind = "data"; summary = ""; details = ""; steps = ""; expected = ""; actual = ""; recipient = ""; images = []; savedToken = nil
                    })
        .interactiveDismissDisabled(dirty)
    }

    @ViewBuilder private var githubActions: some View {
        Button(english ? "Copy title" : "Titel kopieren") {
            if copyGitHubText(summary) {
                message = english ? "Issue title copied." : "Issue-Titel kopiert."
            }
        }
        Button(english ? "Copy GitHub text" : "GitHub-Text kopieren") {
            if copyGitHubText(report.githubMarkdown(english: english)) {
                message = english ? "Markdown copied. Paste it into the issue description." : "Markdown kopiert. Füge ihn in die Issue-Beschreibung ein."
            }
        }
        Button(english ? "Copy & open GitHub…" : "Kopieren & GitHub öffnen …") {
            guard copyGitHubText(report.githubMarkdown(english: english)) else { return }
            if NSWorkspace.shared.open(FeedbackReport.githubIssueURL) {
                message = english ? "GitHub opened; paste the copied description, add a title and review before submitting. Nothing has been published by Companion." : "GitHub geöffnet; kopierte Beschreibung einfügen, Titel ergänzen und vor dem Absenden prüfen. Der Companion hat nichts veröffentlicht."
            } else {
                message = english ? "The browser could not open. Your Markdown is on the clipboard; open the project's GitHub Issues page manually." : "Der Browser konnte nicht geöffnet werden. Dein Markdown liegt in der Zwischenablage; öffne die GitHub-Issues des Projekts manuell."
            }
        }
    }

    private func copyGitHubText(_ text: String) -> Bool {
        NSPasteboard.general.clearContents()
        guard NSPasteboard.general.setString(text, forType: .string) else {
            message = english ? "Could not copy the text. Select it in the preview and copy manually." : "Der Text konnte nicht kopiert werden. Markiere ihn in der Vorschau und kopiere ihn manuell."
            return false
        }
        return true
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() } catch { message = error.localizedDescription }
    }
    private func addImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        perform {
            guard panel.urls.count + images.count <= 5 else { throw imageError() }
            let additions = try panel.urls.map { url -> FeedbackAttachment in
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 10 * 1024 * 1024 else { throw imageError() }
                let data = try Data(contentsOf: url)
                guard NSImage(data: data) != nil else { throw imageError() }
                return FeedbackAttachment(data: data, fileExtension: url.pathExtension.lowercased())
            }
            images.append(contentsOf: additions)
        }
    }
    private func captureWindow() {
        perform {
            guard let view = sourceWindow?.contentView,
                  let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw imageError() }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            guard let png = bitmap.representation(using: .png, properties: [:]), png.count <= 10 * 1024 * 1024 else { throw imageError() }
            images.append(FeedbackAttachment(data: png, fileExtension: "png"))
        }
    }
    private func imageError() -> NSError {
        NSError(domain: "Feedback", code: 1, userInfo: [NSLocalizedDescriptionKey: english ? "Use up to five PNG, JPEG or HEIC images, at most 10 MB each. The app window must be available for capture." : "Bis zu fünf PNG-, JPEG- oder HEIC-Bilder mit je höchstens 10 MB. Für eine Aufnahme muss das App-Fenster verfügbar sein."])
    }
    @discardableResult private func export() -> Bool {
        guard ready else {
            message = english ? "Enter a summary and description before exporting, or explicitly discard the draft." : "Vor dem Export Kurztitel und Beschreibung ergänzen oder den Entwurf ausdrücklich verwerfen."
            return false
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "RealmCraft-Report.zip"
        guard panel.runModal() == .OK, let destination = panel.url else { return false }
        do {
            try report.writeArchive(to: destination, images: images)
            savedToken = draftToken
            message = english ? "ZIP exported with report.hjson and \(images.count) image(s)." : "ZIP mit report.hjson und \(images.count) Bild(ern) exportiert."
            return true
        } catch { message = error.localizedDescription; return false }
    }
}

// Keep the editor's size stable while typing; only its text scrolls for longer reports.
// The placeholder never intercepts clicks or appears in copied/exported text.
struct FeedbackTextArea: View {
    @Binding var text: String
    let label: String
    let placeholder: String
    @Environment(\.companionTheme) private var theme
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .foregroundStyle(.primary)
            .scrollContentBackground(.hidden)
            .focused($focused)
            .accessibilityLabel(label)
            .padding(8)
            .frame(height: 140)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body).foregroundStyle(.secondary)
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(focused ? theme.accent : Color.secondary.opacity(0.35), lineWidth: focused ? 2 : 1)
                    .allowsHitTesting(false)
            }
    }
}
