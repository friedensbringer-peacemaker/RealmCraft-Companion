import SwiftUI
import Charts

struct OreDistributionView: View {
    let levels: [OreLevel]
    @Binding var materials: Set<String>
    @Binding var y: Int
    let nonAirOnly: Bool
    let english: Bool
    @State var mode = "lines"
    @State private var pickedY: Int?
    private var selected: [OreMaterial] { OreMaterial.all.filter { materials.contains($0.id) } }
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    private struct Point: Identifiable {
        let material: OreMaterial, y: Int, value: Double, segment: Int
        var id: String { "\(material.id):\(y)" }
        var series: String { "\(material.id):\(segment)" }
    }
    private var points: [Point] {
        selected.flatMap { m -> [Point] in
            var segment = 0, last: Int?
            return levels.sorted { $0.y < $1.y }.compactMap { r in
                let denominator = nonAirOnly ? r.nonAir : r.blocks
                guard denominator > 0, r.materials?[m.id] != nil || r.ores[m.id] != nil else { segment += 1; return nil }
                if let last, r.y != last+1 { segment += 1 }
                last = r.y
                return Point(material:m,y:r.y,value:Double(r.material(m.id))/Double(denominator)*100,segment:segment)
            }
        }
    }
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text(t("Wo liegt welches Material?", "Where does each material occur?")).font(.title2.bold())
                    Text(t("Gemessener Anteil je Höhenschicht", "Measured fraction by height")).foregroundStyle(.secondary)
                }
                Spacer()
                Text("Y \(y)").font(.title.bold()).monospacedDigit()
            }
            HStack {
                Picker(t("Darstellung", "View"),selection:$mode) {
                    Text(t("Linien", "Lines")).tag("lines")
                    Text("Heatmap").tag("heatmap")
                    Text(t("Schichtvergleich", "Layer comparison")).tag("bars")
                }.pickerStyle(.segmented).labelsHidden().fixedSize().frame(maxWidth:470,alignment:.leading)
                Spacer()
                Button(t("Alle Erze", "All ores")) { materials = Set(OreMaterial.all.prefix(11).map(\.id)) }
                Button(t("Keine", "None")) { materials = [] }
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:130))],alignment:.leading,spacing:8) {
                ForEach(OreMaterial.all) { m in
                    Toggle(isOn:Binding(get:{materials.contains(m.id)},set:{ if $0 {materials.insert(m.id)} else {materials.remove(m.id)} })) {
                        HStack(spacing:5) { Circle().fill(m.color).frame(width:7,height:7);Text(m.name(english)).font(.caption) }
                    }.toggleStyle(.checkbox)
                }
            }
            if selected.isEmpty {
                ContentUnavailableView(t("Materialien auswählen", "Choose materials"),systemImage:"checklist",description:Text(t("Die Auswahl wird mit der Schichtkarte geteilt.", "Selection is shared with the layer map."))).frame(height:310)
            } else if mode == "heatmap" { heatmap }
            else if mode == "bars" { layerBars }
            else { lineChart }
            if let low=levels.map(\.y).min(), let high=levels.map(\.y).max(), low < high {
                HStack {
                    Text("Y \(low)").font(.caption)
                    Slider(value:Binding(get:{Double(y)},set:{y=Int($0.rounded())}),in:Double(low)...Double(high),step:1)
                    Text("Y \(high)").font(.caption)
                    Text("Y \(y)").monospacedDigit().frame(minWidth:55,alignment:.trailing)
                }
            }
            Text(nonAirOnly ? t("Bezugsmenge: Nicht-Luft-Blöcke inklusive Wasser, Lava und Bauten. Fehlende Daten erzeugen Lücken.", "Denominator: non-air blocks including water, lava and builds. Missing data creates gaps.") : t("Bezugsmenge: alle gelesenen Blockpositionen. Keine Glättung, keine hochgerechneten Werte. Fehlende Daten erzeugen Lücken.", "Denominator: all read block positions. No smoothing or extrapolation. Missing data creates gaps.")).font(.caption).foregroundStyle(.secondary)
        }.padding(20).companionPanel()
        .onChange(of:pickedY) { _,value in if let value, levels.contains(where:{$0.y==value}) {y=value} }
    }
    private var heightDomain: ClosedRange<Double> {
        Double(levels.map(\.y).min() ?? 0)-0.5 ... Double(levels.map(\.y).max() ?? 255)+0.5
    }
    private var heatMaximum: Double { max(points.map(\.value).max() ?? 0, 1) }
    private var heatmap: some View {
                Chart(points) { p in
                    RectangleMark(xStart:.value("Y",Double(p.y)-0.5),xEnd:.value("Y",Double(p.y)+0.5),y:.value(t("Material", "Material"),p.material.name(english)),height:.ratio(0.8))
                        .foregroundStyle(by:.value("%",p.value))
                }
                .chartForegroundStyleScale(domain:0...heatMaximum,range:Gradient(colors:[Color(red:0.12,green:0.16,blue:0.20),.cyan,.yellow]))
                .chartXScale(domain:heightDomain)
                .chartYAxisLabel(t("Material · Anteil %", "Material · fraction %"))
                .chartXAxisLabel(t("Höhe Y · antippen zum Auswählen", "Height Y · click to select"))
                .chartXSelection(value:$pickedY).frame(height:max(220,Double(selected.count)*28))
    }
    private var layerBars: some View {
                Chart(points.filter { $0.y == y }) { p in
                    BarMark(x:.value("%",p.value),y:.value(t("Material", "Material"),p.material.name(english)))
                        .foregroundStyle(p.material.color)
                        .annotation(position:.trailing) { Text(p.value.formatted(.number.precision(.fractionLength(0...3)))+" %").font(.caption2).monospacedDigit() }
                }.chartXAxisLabel("%").frame(height:max(240,Double(selected.count)*30))
    }
    private var lineChart: some View {
                Chart {
                    ForEach(points) { p in
                        LineMark(x:.value("Y",p.y),y:.value("%",p.value),series:.value("series",p.series))
                            .foregroundStyle(p.material.color).interpolationMethod(.linear).lineStyle(StrokeStyle(lineWidth:1.8))
                        PointMark(x:.value("Y",p.y),y:.value("%",p.value)).foregroundStyle(p.material.color).symbolSize(5)
                    }
                    RuleMark(x:.value("Y",y)).foregroundStyle(.secondary).lineStyle(StrokeStyle(lineWidth:1,dash:[4,4]))
                }.chartXAxisLabel(t("RealmCraft-Höhe Y", "RealmCraft height Y")).chartYAxisLabel("%")
                    .chartXScale(domain:heightDomain).chartYScale(domain: .automatic(includesZero:true)).chartXSelection(value:$pickedY).frame(height:310)
    }

}
