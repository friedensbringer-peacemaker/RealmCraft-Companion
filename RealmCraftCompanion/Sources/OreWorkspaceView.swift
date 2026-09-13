import SwiftUI
import Charts
import AppKit

/// A fixed north-up analytical detail of the existing Atlas rectangle. No second map selection protocol.
struct OreWorkspaceView: View {
    let scan: OreScan
    @Binding var y: Int
    @Binding var materials: Set<String>
    let english: Bool
    var measuredAt: Date? = nil
    let planHere: (Int, Int, Int) -> Void
    let inspectArea: (OreArea) -> Void
    var showOnMap: ((Int, Int, Int, Int) -> Void)? = nil
    @Environment(\.companionTheme) private var theme
    @State private var relevantOnly = false
    @State private var minimum = 1
    @State private var hovered: CGPoint?
    @State private var pinned: CGPoint?
    @State private var areaSize = 64
    @State private var clusterCount = 0
    @State private var viewMode = "2d"
    private static let registry: [String:String] = {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("MapEngine/realmcraft_map/blocks.json"), let data = try? Data(contentsOf:url) else { return [:] }
        return (try? JSONDecoder().decode([String:String].self,from:data)) ?? [:]
    }()
    private var b: [Int] { scan.bounds }
    private var active: [OreMaterial] { OreMaterial.all.filter { materials.contains($0.id) } }
    private var row: OreLevel? { scan.levels.first { $0.y == y && $0.blocks > 0 } }
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    private var availableLayers: [Int] {
        scan.levels.filter { level in
            level.blocks > 0 && (!relevantOnly || materials.reduce(0) { $0 + level.material($1) } >= minimum)
        }.map(\.y)
    }
    private func step(_ direction: Int) {
        if let next = OreLayerStepper.next(current: y, available: availableLayers, direction: direction) { y = next }
    }
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            Section {
            materialPicker
            HStack {
                Toggle(t("Nur interessante Schichten", "Only interesting layers"), isOn: $relevantOnly)
                Stepper(t("Ab \(minimum) gewählten Blöcken", "At least \(minimum) selected blocks"), value: $minimum, in: 1...10000).fixedSize()
                Spacer()
            }.font(.caption)
            if relevantOnly && (row.map { r in materials.reduce(0) { $0 + r.material($1) } } ?? 0) < minimum {
                Text(t("Diese Schicht erfüllt den Filter nicht. Die Pfeile springen zu Treffern; der Regler bleibt frei.", "This layer does not match. Arrows jump to matches; the slider stays unrestricted.")).font(.caption).foregroundStyle(.orange)
            }
            Picker(t("Schichtansicht", "Layer view"),selection:$viewMode) {
                Text(t("2D · Draufsicht", "2D · Top view")).tag("2d")
                Text(t("3D · Schnitt", "3D · Cutaway")).tag("3d")
            }.pickerStyle(.segmented).labelsHidden().fixedSize().frame(maxWidth:360,alignment:.leading)
            if viewMode == "3d" {
                OreLayer3DView(scan:scan,y:$y,materials:materials,english:english,initialCenter:pinned,planHere:planHere,showOnMap:showOnMap,measuredAt:measuredAt,availableLayers:availableLayers,stepLayer:step)
                ledger
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 20) { layerMap.frame(minWidth: 440); ledger.frame(width: 290) }
                    VStack(alignment: .leading, spacing: 18) { layerMap; ledger }
                }
            }
            if let areas = scan.areas, !areas.isEmpty { areaComparison(areas) }
            } header: {
                OreLayerControls(y: $y, bounds: b[2]...b[3], available: availableLayers, english: english, step: step)
            }
        }
        .padding(20).companionPanel()
        .onChange(of: y) { _, value in y = min(b[3], max(b[2],value)); hovered = nil; pinned = nil }
    }
    private var materialPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(t("Materialfilter", "Material filters")).font(.subheadline.bold())
                Spacer()
                Button(t("Erze", "Ores")) { materials = Set(OreMaterial.all.prefix(11).map(\.id)) }
                Button(t("Strukturen", "Structures")) { materials = ["chest","rail","spawner","planks","amethyst"] }
                Button(t("Alle", "All")) { materials = Set(OreMaterial.all.map(\.id)) }
                Button(t("Keine", "None")) { materials = [] }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128))], alignment: .leading, spacing: 8) {
                ForEach(OreMaterial.all) { m in
                    Button {
                        if materials.contains(m.id) { materials.remove(m.id) } else { materials.insert(m.id) }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: materials.contains(m.id) ? "checkmark.square.fill" : "square").foregroundStyle(m.color)
                            Text(m.name(english)).font(.caption).lineLimit(1).help(m.name(english))
                            Spacer(minLength: 0)
                        }.padding(8).background(m.color.opacity(materials.contains(m.id) ? 0.13 : 0.025), in: RoundedRectangle(cornerRadius: 6))
                    }.buttonStyle(.plain).accessibilityValue(materials.contains(m.id) ? t("Ausgewählt", "Selected") : t("Nicht ausgewählt", "Not selected"))
                }
            }
        }
    }
    private var layerMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("X \(b[0])"); Spacer(); Text(t("Angezeigt: Y \(y) · N ↑", "Displayed: Y \(y) · N ↑")).bold(); Spacer(); Text("X \(b[1])") }.font(.caption.monospaced()).foregroundStyle(.secondary)
            if let spatial = scan.spatial {
                GeometryReader { geo in
                    let w = b[1]-b[0]+1, h = b[5]-b[4]+1
                    let scale = min(geo.size.width/Double(w), geo.size.height/Double(h))
                    let origin = CGPoint(x: (geo.size.width-Double(w)*scale)/2, y: (geo.size.height-Double(h)*scale)/2)
                    Canvas { ctx, size in
                        for z in 0..<h { for x in 0..<w {
                            let value = spatial.cell(x:x+b[0],y:y,z:z+b[4],bounds:b)
                            let rect = CGRect(x:origin.x+Double(x)*scale,y:origin.y+Double(z)*scale,width:scale+0.1,height:scale+0.1)
                            ctx.fill(Path(rect), with: .color(blockColor(value)))
                        }}
                        var grid = Path()
                        for x in 0...w where (x+b[0]) % 16 == 0 { grid.move(to:CGPoint(x:origin.x+Double(x)*scale,y:origin.y)); grid.addLine(to:CGPoint(x:origin.x+Double(x)*scale,y:origin.y+Double(h)*scale)) }
                        for z in 0...h where (z+b[4]) % 16 == 0 { grid.move(to:CGPoint(x:origin.x,y:origin.y+Double(z)*scale)); grid.addLine(to:CGPoint(x:origin.x+Double(w)*scale,y:origin.y+Double(z)*scale)) }
                        ctx.stroke(grid,with:.color(.white.opacity(0.22)),lineWidth:0.6)
                        if let p = pinned ?? hovered {
                            let r = CGRect(x:origin.x+(p.x-Double(b[0]))*scale,y:origin.y+(p.y-Double(b[4]))*scale,width:scale,height:scale)
                            ctx.stroke(Path(r.insetBy(dx:-1,dy:-1)),with:.color(.white),lineWidth:2)
                        }
                    }
                    .onContinuousHover { phase in
                        if case .active(let p) = phase { hovered = position(p, origin:origin, scale:scale, w:w, h:h) } else { hovered = nil }
                    }
                    .onTapGesture { p in
                        pinned = position(p, origin:origin, scale:scale, w:w, h:h)
                        clusterCount = 0
                        if let p = pinned, let id = spatial.cell(x:Int(p.x),y:y,z:Int(p.y),bounds:b), let m = OreMaterial.byBlock[id] {
                            clusterCount = spatial.connectedCount(x:Int(p.x),y:y,z:Int(p.y),bounds:b,blockIDs:Set(m.blocks))
                        }
                    }
                    .focusable().focusEffectDisabled()
                    .onKeyPress(.upArrow) { step(1); return .handled }
                    .onKeyPress(.downArrow) { step(-1); return .handled }
                    .background(OreLayerWheel { step($0) })
                    .accessibilityLabel(t("Schichtkarte Y \(y). Pfeiltasten wechseln die Höhe. Norden oben; Osten rechts.", "Layer map Y \(y). Arrow keys change height. North up; east right."))
                }.frame(height: 365).background(Color(red:0.055,green:0.073,blue:0.087)).clipShape(RoundedRectangle(cornerRadius:8))
            } else {
                ContentUnavailableView(t("Draufsicht neu einlesen", "Read layer view"),systemImage:"square.3.layers.3d",description:Text(t("Für die Draufsicht einen Bereich bis 128 × 128 × 256 Blöcke erneut messen. Größere Gebiete bleiben im Teilflächenvergleich verfügbar; Zufallsstichproben haben keine zusammenhängende Karte.", "Measure up to 128 × 128 × 256 blocks again for a layer view. Larger areas remain available in area comparison; random samples have no contiguous map."))).frame(height:365)
            }
            HStack { Text("Z \(b[4]) → \(b[5])"); Spacer(); Text(t("Raster: Chunkgrenzen 16 × 16", "Grid: chunk boundaries 16 × 16")) }.font(.caption.monospaced()).foregroundStyle(.secondary)
            Text(t("Dunkel: Luft · Grau: übrige Blöcke · Violett: unbekannt/fehlend. Markierte Materialien verwenden die Filterfarben.", "Dark: air · gray: other blocks · purple: unknown/missing. Highlighted materials use the filter colors.")).font(.caption).foregroundStyle(.secondary)
            if pinned != nil && clusterCount > 0 {
                Text(t("\(clusterCount) seitlich verbundene Blöcke dieses Materials auf Y \(y) · 4er-Nachbarschaft, nur innerhalb der Auswahl.", "\(clusterCount) face-adjacent blocks of this material at Y \(y) · 4-neighbor connectivity, bounded to this selection.")).font(.caption).foregroundStyle(.secondary)
            }
            if let p = pinned ?? hovered, let spatial = scan.spatial {
                let value = spatial.cell(x:Int(p.x),y:y,z:Int(p.y),bounds:b)
                HStack {
                    Text("X \(Int(p.x)) · Y \(y) · Z \(Int(p.y)) · " + blockName(value)).font(.caption.monospaced()).textSelection(.enabled)
                    Spacer()
                    Button { NSPasteboard.general.clearContents(); NSPasteboard.general.setString("\(scan.dimension) · X \(Int(p.x)) Y \(y) Z \(Int(p.y))",forType:.string) } label: { Image(systemName:"doc.on.doc") }
                    Button(t("Stollen planen", "Plan tunnel")) { planHere(Int(p.x),y,Int(p.y)) }
                    if let showOnMap, let value, value != 65535 {
                        Button(t("Auf Karte zeigen", "Show on map")) { showOnMap(Int(p.x), y, Int(p.y), Int(value)) }
                    }
                }
            } else { Text(t("Über einen Block zeigen; klicken zum Fixieren. ↑ / ↓ nach Kartenfokus oder ⌥ + Scrollen wechseln Schichten.", "Hover a block; click to pin. Focus and use ↑ / ↓, or ⌥ + scroll to change layers.")).font(.caption).foregroundStyle(.secondary) }
        }
    }
    private func position(_ p: CGPoint, origin: CGPoint, scale: Double, w: Int, h: Int) -> CGPoint? {
        let x = Int(floor((p.x-origin.x)/scale)), z = Int(floor((p.y-origin.y)/scale))
        guard x >= 0, x < w, z >= 0, z < h else { return nil }
        return CGPoint(x:x+b[0], y:z+b[4])
    }
    private func blockColor(_ id: Int?) -> Color {
        guard let id else { return Color(red:0.35,green:0.20,blue:0.40) }
        if let m = OreMaterial.byBlock[id], materials.contains(m.id) { return m.color }
        if [0,639].contains(id) { return Color(red:0.055,green:0.073,blue:0.087) }
        if !Self.registry.isEmpty && Self.registry[String(id)] == nil { return .purple }
        if id == 26 { return Color(red:0.12,green:0.30,blue:0.40) }
        if id == 27 { return Color(red:0.64,green:0.29,blue:0.12) }
        return Color(white: 0.19 + Double(id % 5)*0.018)
    }
    private func blockName(_ id: Int?) -> String {
        guard let id else { return t("Daten fehlen", "Missing data") }
        if let m = OreMaterial.byBlock[id] { return m.name(english) + " · ID \(id)" }
        return (Self.registry[String(id)]?.replacingOccurrences(of:"_",with:" ") ?? t("Unbekannt", "Unknown")) + " · ID \(id)"
    }
    private var ledger: some View {
        VStack(alignment:.leading,spacing:12) {
            Text(t("Vorkommen", "Deposits")).font(.headline)
            Text(t("Schicht / ausgewähltes Volumen", "Layer / selected volume")).font(.caption).foregroundStyle(.secondary)
            ForEach(active) { m in
                let available = scan.levels.contains { $0.materials?[m.id] != nil || $0.ores[m.id] != nil }
                let total = scan.levels.reduce(0) { $0 + $1.material(m.id) }
                let count = available ? row?.material(m.id) : nil
                VStack(alignment:.leading,spacing:5) {
                    HStack {
                        Circle().fill(m.color).frame(width:7,height:7)
                        Text(m.name(english)).font(.caption)
                        Spacer()
                        Text((count.map { $0.formatted() } ?? "—") + " / " + (available ? total.formatted() : "—")).font(.caption.monospacedDigit()).bold()
                    }
                    GeometryReader { g in
                        Capsule().fill(m.color.opacity(0.1))
                        if let count, total > 0 { Capsule().fill(m.color).frame(width:g.size.width*Double(count)/Double(total)) }
                    }.frame(height:4)
                }
            }
            if active.isEmpty { Text(t("Materialfilter auswählen", "Select material filters")).foregroundStyle(.secondary) }
            Divider()
            Text(t("Balken = Anteil dieser Schicht am gesamten Vorkommen desselben Materials. Fehlende Schichten erscheinen als —.", "Bar = this layer's share of the same material's total deposits. Missing layers appear as —.")).font(.caption).foregroundStyle(.secondary)
            Text(t("Unbekannte Block-IDs: ","Unknown block IDs: ") + (row.map { String($0.unknown) } ?? "—")).font(.caption)
        }
    }
    private func areaTiles(_ rows: [OreArea]) -> some View {
        GeometryReader { geo in
            let w = Double(b[1]-b[0]+1), h = Double(b[5]-b[4]+1)
            let scale = min(geo.size.width/w,geo.size.height/h)
            let maximum = max(1,rows.map { $0.count(materials) }.max() ?? 1)
            ZStack(alignment:.topLeading) {
                Rectangle().fill(Color.purple.opacity(0.15))
                ForEach(scan.areas ?? []) { part in
                    if let group = rows.first(where: { part.x0 >= $0.x0 && part.x0 <= $0.x1 && part.z0 >= $0.z0 && part.z0 <= $0.z1 }) {
                        Rectangle().fill(theme.accent.opacity(0.1+0.8*Double(group.count(materials))/Double(maximum)))
                            .frame(width:Double(part.x1-part.x0+1)*scale,height:Double(part.z1-part.z0+1)*scale)
                            .offset(x:Double(part.x0-b[0])*scale,y:Double(part.z0-b[4])*scale)
                    }
                }
                ForEach(rows) { a in
                    areaTileButton(a, scale:scale)
                }
            }.frame(width:w*scale,height:h*scale)
        }.frame(height:200)
    }
    private func areaTileButton(_ area: OreArea, scale: Double) -> some View {
        let width = area.x1-area.x0+1
        let depth = area.z1-area.z0+1
        let height = b[3]-b[2]+1
        let expected = max(1,width*depth*height)
        let coverage = min(1,Double(area.blocks)/Double(expected))
        let coverageText = coverage.formatted(.percent.precision(.fractionLength(0)))
        let help = "X \(area.x0)…\(area.x1) · Z \(area.z0)…\(area.z1) · " + t("Abdeckung ", "Coverage ") + coverageText + " · " + t("Klicken zum Untersuchen", "Click to inspect")
        return Button { inspectArea(area) } label: {
            areaTileLabel(area, coverage:coverage, scale:scale)
        }.buttonStyle(.plain)
            .frame(width:Double(width)*scale,height:Double(depth)*scale)
            .offset(x:Double(area.x0-b[0])*scale,y:Double(area.z0-b[4])*scale)
            .help(help)
    }
    private func areaTileLabel(_ area: OreArea, coverage: Double, scale: Double) -> some View {
        let incomplete = coverage < 0.999
        let border = StrokeStyle(lineWidth:incomplete ? 1.5 : 1,dash:incomplete ? [4,3] : [])
        return Rectangle().fill(.clear).contentShape(Rectangle())
            .overlay(Rectangle().stroke(Color.white.opacity(incomplete ? 0.65 : 0.22),style:border))
            .overlay {
                if Double(area.x1-area.x0+1)*scale > 56 {
                    VStack(spacing:1) {
                        Text(area.count(materials).formatted()).bold()
                        if incomplete { Text(coverage.formatted(.percent.precision(.fractionLength(0)))) }
                    }.font(.caption2).foregroundStyle(.white).shadow(radius:2)
                }
            }
    }
    private func areaComparison(_ areas: [OreArea]) -> some View {
        let rows = OreArea.grouped(areas, size:areaSize, bounds:b).sorted { a,b in
            a.count(materials) == b.count(materials) ? a.id < b.id : a.count(materials) > b.count(materials)
        }
        return VStack(alignment:.leading,spacing:12) {
            Divider()
            HStack {
                Label(t("Ergiebige Teilflächen", "Productive areas"),systemImage:"square.grid.3x3").font(.headline)
                Spacer()
                Picker(t("Raster", "Grid"),selection:$areaSize) { Text("16 × 16").tag(16); Text("64 × 64").tag(64) }.labelsHidden().frame(width:130)
            }
            Text(t("Gleiches Y-Intervall, gleiche Materialfilter. Nach Blockzahl sortiert; der Anteil berücksichtigt unterschiedlich große und unvollständige Randflächen.", "Same Y interval and material filters. Ranked by block count; the fraction accounts for differently sized and incomplete edge areas.")).font(.caption).foregroundStyle(.secondary)
            areaTiles(rows)
            HStack {
                Text(t("Teilfläche", "Area")).frame(maxWidth:.infinity,alignment:.leading)
                Text(t("Funde", "Finds")).frame(width:80,alignment:.trailing)
                Text(t("Anteil", "Fraction")).frame(width:85,alignment:.trailing)
                Text(t("Abdeckung", "Coverage")).frame(width:85,alignment:.trailing)
            }.font(.caption.bold()).foregroundStyle(.secondary)
            ForEach(Array(rows.prefix(8))) { area in
                let expected = max(1,(area.x1-area.x0+1)*(area.z1-area.z0+1)*(b[3]-b[2]+1))
                let coverage = min(1,Double(area.blocks)/Double(expected))
                HStack {
                    Text("X \(area.x0)…\(area.x1) · Z \(area.z0)…\(area.z1)").font(.caption.monospaced()).frame(maxWidth:.infinity,alignment:.leading)
                    Text(area.count(materials).formatted()).bold().monospacedDigit().frame(width:80,alignment:.trailing)
                    Text(area.blocks > 0 ? (Double(area.count(materials))/Double(area.blocks)).formatted(.percent.precision(.fractionLength(2))) : "—").monospacedDigit().frame(width:85,alignment:.trailing)
                    Text(coverage.formatted(.percent.precision(.fractionLength(0)))).monospacedDigit().frame(width:85,alignment:.trailing).foregroundStyle(coverage < 0.999 ? .orange : .secondary)
                }
            }
            Text(t("Top 8 Teilflächen · Fehlende Chunks sind nicht als leer enthalten. Benachbarte Funde beweisen keine zusammenhängende dreidimensionale Lagerstätte.", "Top 8 areas · Missing chunks are not included as empty. Adjacent finds do not establish a connected three-dimensional deposit.")).font(.caption).foregroundStyle(.secondary)
        }
    }
}
