import SwiftUI

struct MetroCarryForwardView: View {
    @ObservedObject var model: Model
    let target: Savegame
    let english: Bool
    let completed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var sourceID = ""
    @State private var review: MetroCarryForward.Review?
    @State private var error: String?
    private var candidates: [Savegame] {
        model.saves.filter { $0.world == target.world && $0.id != target.id && $0.date < target.date }.sorted { $0.date > $1.date }
    }
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    private func snapshot(_ save: Savegame) -> MetroCarryForward.Snapshot {
        .init(id: save.id, world: save.world, date: save.date, worldFolder: model.library.worldFolder(save),
              networkURL: model.library.root.appendingPathComponent(".metro-networks").appendingPathComponent(save.id + ".json"))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(t("Metronetz übernehmen", "Carry forward Metro network")).font(.title2)
            Text(t("Ziel: ", "Target: ") + target.title)
            Picker(t("Ältere Sicherung", "Older backup"), selection: $sourceID) {
                Text("—").tag("")
                ForEach(candidates) { Text($0.title + " · " + $0.date.formatted()).tag($0.id) }
            }
            Text(t("Bitte denselben Spielverlauf wählen. Eine gleiche Welt-ID allein belegt das nicht. Das Zielnetz muss leer sein.", "Choose the same playthrough. Matching world IDs alone do not prove this. The target network must be empty.")).font(.callout)
            Button(t("Vorschau prüfen", "Review preview")) {
                guard let source = candidates.first(where: { $0.id == sourceID }) else { return }
                do { review = try MetroCarryForward.prepare(source: snapshot(source), target: snapshot(target)); error = nil }
                catch { self.error = error.localizedDescription; review = nil }
            }.disabled(sourceID.isEmpty || model.busy)
            if let review {
                Text("\(review.proposal.stations.count) " + t("Stationen", "stations") + " · \(review.proposal.lines.count) " + t("Linien", "lines") + " · \(review.proposal.edges.count) " + t("Verbindungen", "connections"))
                Text(t("Alle Einträge werden als geplant übernommen. Namen, Geometrie und frühere Messzeiten bleiben erhalten; Reisen müssen erneut bestätigt werden.", "All records are copied as planned. Names, geometry and previous measured times are retained; journeys require fresh confirmation."))
                Text(t("Geänderte oder fehlende Portalbelege: ", "Changed or missing portal evidence: ") + "\(review.portalChanges.count)")
                ScrollView { Text(review.portalChanges.joined(separator: "\n")).frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: 110)
            }
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button(t("Abbrechen", "Cancel")) { dismiss() }
                Spacer()
                Button(t("Als geplantes Netz übernehmen", "Copy as planned network")) {
                    guard let review, model.selected?.id == target.id else { return }
                    do { try model.library.withExclusiveOperation { try MetroCarryForward.apply(review) }; completed(); dismiss() }
                    catch { self.error = error.localizedDescription }
                }.disabled(review == nil || model.busy || model.selected?.id != target.id)
            }
        }.padding(24).frame(width: 580)
        .onChange(of: sourceID) { _, _ in review = nil; error = nil }
    }
}
