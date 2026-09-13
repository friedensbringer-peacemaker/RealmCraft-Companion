import SwiftUI
import AppKit

extension Color {
    init(metroHex: String) {
        let value = UInt64(metroHex.dropFirst(), radix: 16) ?? 0x91BFA6
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
    var metroHex: String {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return "#91BFA6" }
        return String(format: "#%02X%02X%02X", Int((color.redComponent * 255).rounded()), Int((color.greenComponent * 255).rounded()), Int((color.blueComponent * 255).rounded()))
    }
}

/// Rank-compressed world axes preserve direction; dimensions occupy separate panels.
/// Only actual graph edges are drawn. Diagram positions never enter route calculations.
struct MetroDiagram: View {
    let network: MetroNetworkStore.Document
    var selected: String? = nil
    var lineID: String? = nil
    var routeIDs: Set<String> = []
    var english = true
    var choose: (MetroStation) -> Void = { _ in }
    @Environment(\.companionTheme) private var theme

    private var shown: [MetroStation] {
        guard let lineID else { return network.stations }
        let ids = Set(network.edges.filter { $0.lineID == lineID }.flatMap { [$0.from, $0.to] })
        return network.stations.filter { ids.contains($0.id) }
    }
    private func panels(_ size: CGSize) -> [(String, CGRect)] {
        let dimensions = ["n", "o"].filter { dim in shown.contains { $0.dimension == dim } }
        var offset: CGFloat = 0
        return dimensions.enumerated().map { section, dim in
            if size.width < 600 && dimensions.count > 1 {
                let fraction = CGFloat(shown.filter { $0.dimension == dim }.count + 2) / CGFloat(shown.count + 4)
                let rect = CGRect(x: 0, y: offset, width: size.width, height: size.height * fraction)
                offset += rect.height; return (dim, rect)
            }
            let width = size.width / CGFloat(max(1, dimensions.count))
            return (dim, CGRect(x: CGFloat(section) * width, y: 0, width: width, height: size.height))
        }
    }
    private func positions(_ size: CGSize) -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        for (dim, panel) in panels(size) {
            let stations = shown.filter { $0.dimension == dim }.sorted { $0.id < $1.id }
            let xs = Array(Set(stations.map(\.x))).sorted(), zs = Array(Set(stations.map(\.z))).sorted()
            for (index, station) in stations.enumerated() {
                let xr = CGFloat(xs.firstIndex(of: station.x) ?? 0), zr = CGFloat(zs.firstIndex(of: station.z) ?? 0)
                let x = panel.minX + 80 + (xs.count < 2 ? (panel.width - 160) / 2 : xr / CGFloat(xs.count - 1) * (panel.width - 160))
                let z = panel.minY + 75 + (zs.count < 2 ? (panel.height - 145) / 2 : zr / CGFloat(zs.count - 1) * (panel.height - 145))
                let overlaps = stations.prefix(index).filter { $0.x == station.x && $0.z == station.z }.count
                result[station.id] = CGPoint(x: x + CGFloat(overlaps % 3) * 28, y: z + CGFloat(overlaps / 3) * 42)
            }
        }
        return result
    }
    var body: some View {
        GeometryReader { geometry in
            let stacked = geometry.size.width < 600 && Set(shown.map(\.dimension)).count > 1
            let size = CGSize(width: max(350, geometry.size.width), height: max(stacked ? 600 : 420, CGFloat(shown.count) * 34, geometry.size.height))
            let points = positions(size)
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    Canvas { context, canvas in
                        for x in stride(from: 0.0, through: canvas.width, by: 24) {
                            for y in stride(from: 0.0, through: canvas.height, by: 24) {
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(theme.border.opacity(0.4)))
                            }
                        }
                        for edge in network.edges {
                            guard let a = points[edge.from], let b = points[edge.to], lineID == nil || edge.lineID == lineID else { continue }
                            let color = network.lines.first { $0.id == edge.lineID }.map { Color(metroHex: $0.color) } ?? .purple
                            let highlighted = routeIDs.isEmpty || routeIDs.contains(edge.id)
                            let elbow = CGPoint(x: b.x, y: a.y)
                            let path = Path { p in p.move(to: a); if edge.mode != .portal { p.addLine(to: elbow) }; p.addLine(to: b) }
                            context.stroke(path, with: .color(theme.background), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                            let dash: [CGFloat] = edge.mode == .portal ? [3, 7] : edge.status == .confirmed ? [] : edge.status == .built ? [12, 4] : [5, 6]
                            context.stroke(path, with: .color(color.opacity(highlighted ? 0.95 : 0.16)), style: StrokeStyle(lineWidth: highlighted ? 5 : 3, lineCap: .round, lineJoin: .round, dash: dash))
                        }
                    }
                    ForEach(panels(size), id: \.0) { dim, panel in
                        Label(dim == "n" ? "NETHER" : english ? "OVERWORLD" : "OBERWELT", systemImage: dim == "n" ? "flame" : "globe.europe.africa")
                            .foregroundStyle(dim == "n" ? Color.orange : theme.accent).font(.caption.weight(.bold)).tracking(2)
                            .frame(width: panel.width - 48, alignment: .leading).position(x: panel.midX, y: panel.minY + 30)
                    }
                    ForEach(shown) { station in
                        if let point = points[station.id] {
                            Button { choose(station) } label: {
                                VStack(spacing: 7) {
                                    ZStack {
                                        Circle().fill(theme.background).frame(width: 22, height: 22)
                                        Circle().stroke(selected == station.id ? theme.accent : Color.primary, lineWidth: network.servingLines(station.id).count > 1 ? 5 : 2).frame(width: 16, height: 16)
                                        if station.id == network.originID { Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(theme.accent) }
                                        else if station.portalCandidate == true { Image(systemName: "door.left.hand.open").font(.system(size: 8)).foregroundStyle(.orange) }
                                    }
                                    Text(station.name).font(.system(size: 11, weight: .semibold)).lineLimit(2).multilineTextAlignment(.center)
                                        .padding(.horizontal, 6).padding(.vertical, 3).background(theme.background.opacity(0.92), in: Capsule())
                                }.frame(width: 128)
                            }.buttonStyle(.plain).position(x: point.x, y: point.y + 15)
                                .help("\(station.name) · X \(station.x) / Y \(station.y) / Z \(station.z)")
                        }
                    }
                    Text("N −Z  ↑     E +X →").font(.caption.monospaced()).foregroundStyle(.secondary).position(x: size.width / 2, y: size.height - 24)
                }.frame(width: size.width, height: size.height)
            }
        }.background(theme.background)
    }
}
