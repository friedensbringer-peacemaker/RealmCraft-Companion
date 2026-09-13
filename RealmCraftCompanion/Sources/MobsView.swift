import SwiftUI

struct MobsView: View {
    let language: String
    let report: (FeedbackContext) -> Void
    @State private var catalog: MobCatalog?
    @State private var error: String?
    @State private var query = ""
    @State private var kind = "all"
    @State private var status = "all"
    @State private var selection: String?
    @AppStorage("companionMobImages") private var showImages = false
    private var english: Bool { language == "en" }
    private var entries: [MobEntry] {
        (catalog?.entries ?? []).filter {
            (kind == "all" || $0.kind == kind) && (status == "all" || $0.status == status) && $0.matches(query)
        }.sorted { $0.name.value(english).localizedStandardCompare($1.name.value(english)) == .orderedAscending }
    }
    private var current: MobEntry? { entries.first(where: { $0.id == selection }) ?? entries.first }

    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: english ? "Mobs & Animals" : "Tiere & Kreaturen") {
                EmptyView()
            } menu: {
                Toggle(english ? "Show mob images" : "Mob-Bilder einblenden", isOn: $showImages)
                Button(english ? "Report data / bug" : "Daten / Bug melden") { report(context(for: current)) }
            }
            VStack(alignment: .leading, spacing: 10) {
                Label(MobCatalog.disclaimer(english), systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.medium)).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                Text(english ? "Selected references · not a world scan · check your Quest version."
                     : "Ausgewählte Referenzen · kein Welt-Scan · Quest-Version prüfen.")
                    .font(.caption).foregroundStyle(.secondary)
                CompanionDetails(english ? "Research scope & platform limits" : "Rechercheumfang & Plattformgrenzen") {
                Text(english ? "Research snapshot: \(catalog?.reviewedAt ?? "—") · Selected known entries; not a complete mob census or a scan of your world. Baby forms without a separate VR source are unconfirmed. VR evidence may refer to Steam; check your Quest version."
                     : "Recherche-Stand: \(catalog?.reviewedAt ?? "—") · Auswahl bekannter Einträge; keine vollständige Artenliste oder Auslesung deiner Welt. Babyformen ohne eigenen VR-Beleg sind unbestätigt. VR-Belege können Steam betreffen; Quest-Version prüfen.")
                    .font(.caption).foregroundStyle(.secondary)
                }.font(.caption)
                HStack {
                    TextField(english ? "Search name, dimension, biome or update…" : "Name, Dimension, Biom oder Update suchen …", text: $query).textFieldStyle(.roundedBorder)
                    Picker(english ? "Category" : "Kategorie", selection: $kind) {
                        Text(english ? "All types" : "Alle Arten").tag("all")
                        Text(english ? "Animals" : "Tiere").tag("animal")
                        Text(english ? "Other mobs" : "Weitere Mobs").tag("mob")
                    }.frame(width: 220)
                }
                HStack {
                    Picker(english ? "Evidence" : "Nachweis", selection: $status) {
                        Text(english ? "VR released" : "VR veröffentlicht").tag("released")
                        Text(english ? "In progress" : "In Arbeit").tag("planned")
                        Text(english ? "Unconfirmed" : "Unbestätigt").tag("unverified")
                        Text(english ? "All" : "Alle").tag("all")
                    }.pickerStyle(.segmented)
                    Text("\(entries.count)").font(.headline).monospacedDigit().frame(width: 30)
                }
            }.padding(.horizontal, CompanionLayout.pageInset).padding(.bottom, 18)
            Divider()
            if let error {
                ContentUnavailableView(english ? "Catalog unavailable" : "Katalog nicht verfügbar", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if entries.isEmpty {
                ContentUnavailableView.search(text: query)
                Button(english ? "Reset filters" : "Filter zurücksetzen") { query = ""; kind = "all"; status = "all" }.padding()
            } else {
                HStack(spacing: 0) {
                    List(selection: $selection) {
                        ForEach(entries) { entry in
                            HStack(alignment: .center, spacing: 10) {
                                if showImages { MobThumbnail(entry: entry, english: english).frame(width: 66, height: 66) }
                                VStack(alignment: .leading, spacing: 5) {
                                Text(entry.name.value(english)).font(.headline)
                                Text(entry.statusTitle(english)).font(.caption2).foregroundStyle(entry.status == "released" ? Color.secondary : Color.orange)
                                }
                            }.padding(.vertical, 7).tag(entry.id)
                        }
                    }.listStyle(.sidebar).scrollContentBackground(.hidden).frame(width: CompanionLayout.illustratedSidebarWidth)
                    Divider()
                    if let entry = current {
                        ScrollView {
                            MobDetail(entry: entry, english: english) { report(context(for: entry)) }
                                .padding(CompanionLayout.pageInset).frame(maxWidth: .infinity, alignment: .leading)
                        }.id(entry.id)
                    }
                }
            }
        }.onAppear {
            if catalog == nil {
                do { catalog = try MobCatalog.load() } catch { self.error = error.localizedDescription }
            }
        }
    }

    private func context(for entry: MobEntry?) -> FeedbackContext {
        FeedbackContext(area: "mobs", entryID: entry?.id, entryName: entry?.name.value(english),
                        catalogDate: catalog?.reviewedAt, evidenceStatus: entry?.status,
                        sources: entry.map { [$0.evidenceURL.absoluteString, $0.minecraftURL.absoluteString] + ($0.realmWikiURL.map { [$0.absoluteString] } ?? []) + ($0.habitat.map { [$0.sourceURL.absoluteString] } ?? []) } ?? [])
    }
}

struct MobDetail: View {
    let entry: MobEntry
    let english: Bool
    let report: () -> Void
    @AppStorage("companionMobImages") private var showImages = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: entry.kind == "animal" ? "pawprint.fill" : "sparkles")
                    .font(.system(size: 30)).foregroundStyle(.orange).frame(width: 60, height: 60).companionPanel()
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.name.value(english)).font(CompanionLayout.detailTitle)
                    Text(entry.name.value(!english)).foregroundStyle(.secondary)
                    Text(entry.kind == "animal" ? "Animal" : "Mob").font(.caption)
                }
            }
            if showImages { MobArtworkPanel(entry: entry, english: english) }
            Text(english ? "AI-generated · not verified in game" : "KI-generiert · nicht im Spiel geprüft")
                .font(.callout.weight(.semibold)).foregroundStyle(.orange)
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.statusTitle(english)).font(.headline)
                    Text(entry.note.value(english))
                    Text((english ? "Evidence: " : "Beleg: ") + entry.evidenceLabel).font(.caption).foregroundStyle(.secondary)
                    Link(english ? "Open release / evidence source ↗" : "Veröffentlichung / Beleg öffnen ↗", destination: entry.evidenceURL)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            if let habitat = entry.habitat {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(english ? "Where to find" : "Fundorte", systemImage: "map").font(.headline)
                        Text((english ? "Dimension: " : "Dimension: ") + habitat.dimensionTitle(english)).font(.callout.weight(.semibold))
                        Text(habitat.basisTitle(english)).font(.caption).foregroundStyle(.orange)
                        Text((english ? "VR biomes: " : "VR-Biome: ") + habitat.biomes.value(english))
                        Text(habitat.reference.value(english)).font(.callout)
                        Link(english ? "Location source ↗" : "Fundort-Quelle ↗", destination: habitat.sourceURL)
                        Text(english ? "Locations are not exclusive: transport, breeding and spawn eggs can place mobs elsewhere."
                             : "Fundorte sind nicht exklusiv: Transport, Zucht und Spawn-Eier können Kreaturen auch anderswo erscheinen lassen.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(english ? "Read more" : "Nachschlagen").font(.headline)
                if let wiki = entry.realmWikiURL {
                    Link("RealmCraft Game Wiki ↗", destination: wiki)
                } else {
                    Link(english ? "RealmCraft Wiki · mob overview ↗" : "RealmCraft Wiki · Mob-Übersicht ↗", destination: URL(string: "https://realmcraftgame.fandom.com/wiki/Mobs")!)
                }
                Text(english ? "Publisher-linked community wiki, mainly for mobile RealmCraft. No verified official VR wiki available."
                     : "Vom Hersteller verlinktes Community-Wiki, überwiegend für das mobile RealmCraft. Kein verifiziertes offizielles VR-Wiki verfügbar.")
                    .font(.caption).foregroundStyle(.secondary)
                Link("Minecraft Wiki · \(entry.name.en) ↗", destination: entry.minecraftURL)
                Text(english ? "Alternative reference for comparison only. Minecraft behavior, drops and recipes do not establish RealmCraft VR behavior."
                     : "Alternative zum Vergleichen. Minecraft-Verhalten, Beute und Rezepte sind kein Nachweis für RealmCraft VR.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button(action: report) { Label(english ? "Report this entry" : "Diesen Eintrag melden", systemImage: "flag") }
            Text(MobCatalog.disclaimer(english)).font(.caption).foregroundStyle(.secondary)
        }.textSelection(.enabled)
    }
}


private enum MobImageCache {
    static let images = NSCache<NSURL, NSImage>()
    static func image(for id: String) -> NSImage? {
        guard let url = MobArtwork.url(for: id) else { return nil }
        if let cached = images.object(forKey: url as NSURL) { return cached }
        guard let image = NSImage(contentsOf: url) else { return nil }
        images.setObject(image, forKey: url as NSURL)
        return image
    }
}

struct MobThumbnail: View {
    let entry: MobEntry
    let english: Bool
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = MobImageCache.image(for: entry.id) {
                Image(nsImage: image).resizable().scaledToFit()
                if entry.id.hasPrefix("baby_") {
                    Text(english ? "Adult" : "Erw.").font(.system(size: 9, weight: .medium))
                        .padding(2).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 3))
                }
            } else {
                Image(systemName: "photo.badge.exclamationmark").font(.title3).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.name.value(english) + (entry.id.hasPrefix("baby_") ? (english ? ": adult reference" : ": erwachsene Referenz") : (english ? ": model preview" : ": Modellvorschau")))
        .help(MobArtwork.url(for: entry.id) == nil ? (english ? "No original preview available" : "Keine Originalvorschau vorhanden") : (english ? "Original RealmCraft model; static preview" : "Original-RealmCraft-Modell; statische Vorschau"))
    }
}

struct MobArtworkPanel: View {
    let entry: MobEntry
    let english: Bool
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label(english ? "RealmCraft appearance" : "Aussehen in RealmCraft", systemImage: "photo").font(.headline)
                if let image = MobImageCache.image(for: entry.id) {
                    Image(nsImage: image).resizable().scaledToFit().frame(height: 230)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(entry.name.value(english))
                    if entry.id.hasPrefix("baby_") {
                        Label(english ? "Adult reference — no separate baby preview available." : "Erwachsene Referenz – keine eigene Babyvorschau vorhanden.", systemImage: "info.circle")
                            .font(.callout).foregroundStyle(.orange)
                    }
                    Text(english ? "Original model and textures from the local RealmCraft VR Quest installation. Static preview; pose, lighting and variants may differ in game. Image assignment was AI-assisted; the artwork is not AI-generated."
                         : "Originalmodell und Texturen aus der lokalen RealmCraft-VR-Quest-Installation. Statische Vorschau; Pose, Beleuchtung und Varianten können im Spiel abweichen. Die Zuordnung ist KI-gestützt; die Grafik ist nicht KI-generiert.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(english ? "No original preview available for this entry." : "Für diesen Eintrag ist keine Originalvorschau vorhanden.", systemImage: "photo.badge.exclamationmark")
                        .foregroundStyle(.secondary).padding(.vertical, 16)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
