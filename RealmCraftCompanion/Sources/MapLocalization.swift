import Foundation

enum MapLocalization {
    static func english(_ directory: URL) throws {
        guard let resource = Bundle.main.url(forResource: "MapEnglish", withExtension: "json") else { return }
        let pairs = try JSONDecoder().decode([String:String].self, from: Data(contentsOf: resource))
        for name in ["index.html", "app.js", "layers.js"] {
            let file = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: file.path) else { continue }
            var text = try String(contentsOf: file, encoding: .utf8)
            for key in pairs.keys.sorted(by: { $0.count > $1.count }) { text = text.replacingOccurrences(of: key, with: pairs[key]!) }
            if name == "app.js" {
                if let start = text.range(of: "  const names={"), let end = text.range(of: ";\n", range: start.upperBound..<text.endIndex) { text.replaceSubrange(start.lowerBound..<end.upperBound, with: "  const names={};\n") }
                text = text.replacingOccurrences(of: "d.label", with: "(dimension==='o'?'Overworld':dimension==='n'?'Nether':d.label)")
                text = text.replacingOccurrences(of: "data.dimensions[dimension].label", with: "(dimension==='o'?'Overworld':dimension==='n'?'Nether':data.dimensions[dimension].label)")
            }
            try text.write(to: file, atomically: true, encoding: .utf8)
        }
    }
}
