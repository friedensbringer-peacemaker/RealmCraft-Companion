import Foundation
@main struct GroupingTests {
    static func chest(_ dimension: String, _ x: Int, _ y: Int, _ z: Int) -> ChestRecord {
        ChestRecord(id: "\(dimension):\(x),\(y),\(z)", dimension: dimension, x: x, y: y, z: z, file: "fixture", items: [], readable: true, error: "")
    }
    static func main() throws {
        let items = [chest("o",0,64,0),chest("o",5,64,0),chest("o",10,64,0),chest("o",0,71,0),chest("n",0,64,0),chest("o",-6,64,0)]
        let groups = ChestGroup.make(items)
        precondition(groups.count == 3)
        precondition(groups.map { $0.members.count }.sorted() == [1,1,4])
        precondition(ChestGroup.make([]).isEmpty)
        precondition(groups.map(\.id) == ChestGroup.make(items.reversed()).map(\.id))
        print("PASS: six-block grouping, transitive links, height, negative coordinates, dimensions, stable IDs")
        if CommandLine.arguments.count == 2 {
            let index = try JSONDecoder().decode(ChestIndex.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
            let actual = ChestGroup.make(index.chests)
            precondition(actual.reduce(0) { $0 + $1.members.count } == index.chests.count)
            print("Actual backup: \(index.chests.count) chests grouped into \(actual.count) storage locations")
        }
    }
}
