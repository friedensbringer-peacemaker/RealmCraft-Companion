import SwiftUI
@main struct BuildGuideCellShapeTests {
    static func main() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        func contains(_ id: Int, _ symbol: String, _ side: Bool, _ x: CGFloat, _ y: CGFloat) -> Bool {
            BuildGuideCellShape(itemID: id, symbol: symbol, elevation: side).path(in: rect).contains(CGPoint(x: x, y: y))
        }
        precondition(!contains(466,"HS",true,25,25) && contains(466,"HS",true,25,75))
        precondition(contains(466,"HS",false,25,25))
        for id in [152,261] {
            precondition(!contains(id,"T→",true,25,25) && contains(id,"T→",true,75,25))
            precondition(contains(id,"T←",true,25,25) && !contains(id,"T←",true,75,25))
            precondition(contains(id,"T→",true,25,75) && contains(id,"T→",false,25,25))
        }
        precondition(!contains(95,"BF",true,25,25) && contains(95,"BF",true,25,75))
        print("PASS slab, bed and directional stair elevations; full top footprints retained")
    }
}
