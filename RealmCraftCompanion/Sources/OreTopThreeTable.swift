import SwiftUI

struct OreTopThreeTable: View {
    let levels:[OreLevel],ores:[OreKind]
    let nonAirOnly:Bool,english:Bool
    var body:some View {
        VStack(alignment:.leading,spacing:10) {
            Text(english ? "Top 3 measured heights" : "Top 3 gemessene Höhen").font(.headline)
            Text(english ? "Ranked by the selected denominator. Counts include all regular/deepslate variants. A tie is marked ≈; lower Y is listed first. No finds means no ranked height." : "Sortiert nach dem gewählten Nenner. Normale und Tiefenschiefer-Varianten zählen zusammen. Gleichstand ist mit ≈ markiert; niedrigere Y stehen zuerst. Ohne Fund gibt es keine Ranghöhe.").font(.caption).foregroundStyle(.secondary)
            Grid(alignment:.leading,horizontalSpacing:22,verticalSpacing:10) {
                GridRow {Text(english ? "Ore" : "Erz").bold();Text("1").bold();Text("2").bold();Text("3").bold()}
                ForEach(ores) {ore in
                    let ranks=OreRanking.topThree(levels,ore:ore.id,nonAirOnly:nonAirOnly)
                    GridRow {
                        Text(ore.name(english)).fontWeight(.medium)
                        ForEach(0..<3,id:\.self) {i in
                            if i<ranks.count {
                                let rank=ranks[i]
                                VStack(alignment:.leading,spacing:2) {
                                    Text("Y \(rank.row.y)\(rank.tiedHeights.count>1 ? " ≈" : "")").bold()
                                    Text("\(rank.row.ores[ore.id] ?? 0) / \(nonAirOnly ? rank.row.nonAir : rank.row.blocks)").font(.caption).monospacedDigit()
                                }.help((english ? "Equal rate at Y: " : "Gleiche Fundrate auf Y: ")+rank.tiedHeights.map(String.init).joined(separator:", "))
                            } else {Text("—").foregroundStyle(.secondary)}
                        }
                    }
                }
            }.font(.callout)
            Text(english ? "Snapshot/sample peaks, not universal best mining levels. Especially small denominators and rare ores can produce unstable rankings." : "Spitzen dieser Sicherung/Stichprobe, keine universell besten Abbauhöhen. Besonders kleine Bezugsmengen und seltene Erze können instabile Rangfolgen ergeben.").font(.caption).foregroundStyle(.secondary)
        }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(.quaternary.opacity(0.3)).clipShape(RoundedRectangle(cornerRadius:10))
    }
}
