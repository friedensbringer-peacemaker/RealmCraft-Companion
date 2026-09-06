import Foundation

@main struct BuildGuideTests {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let catalog = try JSONDecoder().decode(BuildCatalog.self, from: data)
        try catalog.validate()
        precondition(catalog.guides.count == 53)
        precondition(Set(catalog.guides.filter { $0.matches("Trichter") }.map(\.id)) == Set(["furnace", "compost", "collector", "feedline", "waterline", "egg_station", "furnace_pair"]))
        precondition(catalog.guides.filter { $0.matches("sugar cane") }.count == 2)
        let flush = catalog.guides.first { $0.id == "flush" }!
        let physical = flush.planes.filter { $0.id != "section" }
        let solids = physical.flatMap { $0.cells.flatMap { $0 } }.filter { $0 == "#" }.count
        precondition(String(solids) == flush.materials[0].count.de)
        let top = flush.planes.first { $0.id == "crop" }!
        let soil = flush.planes.first { $0.id == "soil" }!
        let section = flush.planes.first { $0.id == "section" }!
        precondition(section.cells[0] == top.cells.map { $0[2] == "S" ? "s" : $0[2] })
        precondition(section.cells[1] == soil.cells.map { $0[2] })
        let furnace = catalog.guides.first { $0.id == "furnace" }!.planes[0]
        precondition(furnace.cells[1][1] == "F" && furnace.cells[2][1] == "t")
        precondition(furnace.cells[2][0] == "O")
        let cobble = catalog.guides.first { $0.id == "cobble" }!
        let count = cobble.planes.filter { $0.id != "side" }.flatMap { $0.cells.flatMap { $0 } }.filter { $0 == "#" }.count
        precondition(String(count) == cobble.materials[0].count.de)
        let base = cobble.planes.first { $0.id == "base" }!
        precondition(base.cells[1][2] == ".") // water recess, one level below contact
        let lavaTop = cobble.planes.first { $0.id == "top" }!
        precondition(lavaTop.cells[1][1] == "W" && lavaTop.cells[1][3] == "contact" && lavaTop.cells[1][4] == "lava")
        let slider = catalog.guides.first { $0.id == "slider" }!
        precondition(slider.planes[0].cells[0][1] == "moving")
        precondition(slider.planes[1].cells[0][2] == "moving" && slider.planes[1].cells[0][1] == "head")
        let cactus = catalog.guides.first { $0.id == "cactus" }!
        let side = cactus.planes[0]
        let cactusSolids = side.cells.dropLast().flatMap { $0 }.filter { $0 == "#" }.count + cactus.planes[1].cells.flatMap { $0 }.filter { $0 == "#" }.count
        precondition(String(cactusSolids) == cactus.materials[0].count.de)
        precondition(side.cells[0][1] == "#" && side.cells[1][1] == ".") // obstacle beside upper growth only
        let flowers = catalog.guides.first { $0.id == "flowers" }!
        precondition(flowers.planes[1].cells[1][1] == "grass" && flowers.planes[1].cells[2][1] == "up")
        let water = catalog.guides.first { $0.id == "waterline" }!
        let channel = water.planes.first { $0.id == "water" }!
        let waterFloor = water.planes.first { $0.id == "floor" }!
        precondition(channel.cells[1][1] == "W" && waterFloor.cells[1][4] == "T")
        precondition(water.planes.first { $0.id == "section" }!.cells[2][4] == "E")
        precondition([channel, waterFloor].flatMap { $0.cells.flatMap { $0 } }.filter { $0 == "#" }.count == 31)
        let indicator = catalog.guides.first { $0.id == "storageindicator" }!
        precondition(indicator.planes[0].cells[0] == ["store", "cmp", "rep", "L"])
        let auto = catalog.guides.first { $0.id == "autocane" }!
        let autoSection = auto.planes.first { $0.id == "section" }!
        for (row, id) in ["sensor", "piston", "plant", "base"].enumerated() {
            precondition(autoSection.cells[row] == auto.planes.first { $0.id == id }!.cells[1])
        }
        precondition(autoSection.cells[0][0] == "R" && autoSection.cells[1][0] == "#")
        precondition(autoSection.cells[0][1] == "sense" && autoSection.cells[1][1] == "autoP")
        precondition(auto.planes.filter { $0.id != "section" }.flatMap { $0.cells.flatMap { $0 } }.filter { $0 == "#" }.count + 15 == 30)
        let transport = catalog.guides.filter { $0.category == "transport" }
        precondition(transport.count == 12)
        for (id, block, expected) in [("transport_path", "path", 33), ("transport_stairs", "#", 11), ("transport_stairs", "stairs", 3), ("transport_rail", "#", 12), ("transport_rail", "rail", 8), ("transport_ladder", "#", 7), ("transport_ladder", "ladder", 4)] {
            let guide = transport.first { $0.id == id }!
            precondition(guide.planes.flatMap { $0.cells.flatMap { $0 } }.filter { $0 == block }.count == expected)
        }
        // Every instruction has both views; ordering and staged geometry match the written steps.
        for guide in catalog.guides {
            precondition(guide.instructionStages.count == guide.steps.count)
            precondition(guide.materialFirstSteps.count == guide.materials.count)
            for stage in guide.instructionStages {
                precondition(stage.top.rowAxis == "z" || stage.top.rowAxis == "x")
                precondition(stage.side.rowAxis == "y")
            }
        }
        let lampStages = catalog.guides.first { $0.id == "lamp" }!.instructionStages
        precondition(lampStages[0].side.cells[0].allSatisfy { $0 == "." })
        precondition(lampStages[1].side.cells[0] == ["H", "R", "R", "."])
        precondition(lampStages[2].sideNew == ["0:3"])
        let pathStages = transport.first { $0.id == "transport_path" }!.instructionStages
        precondition(pathStages[1].top.cells.flatMap { $0 }.filter { $0 == "path" }.count == 21)
        precondition(pathStages[2].top.cells.flatMap { $0 }.filter { $0 == "path" }.count == 33)
        precondition(flush.instructionStages[4].top.cells.flatMap { $0 }.allSatisfy { $0 != "Q" })
        precondition(catalog.guides.first { $0.id == "furnace" }!.instructionStages[0].side.cells == [["I"], ["T"], ["E"]])
        for id in ["door_plates", "door_buttons", "gate_plates", "gate_buttons"] {
            let guide = catalog.guides.first { $0.id == id }!
            let final = guide.instructionStages.last!
            let button = id.hasSuffix("buttons")
            precondition(final.top.cells[1][button ? 0 : 1] == (button ? "entry_button" : "entry_plate"))
            precondition(final.top.cells[3][button ? 0 : 1] == (button ? "entry_button" : "entry_plate"))
            precondition(final.top.cells[2][0] == "#" && final.top.cells[2][2] == "#")
            precondition(guide.materials[1].count.de == "1")
            if button {
                let alternative = guide.planes.first { $0.id == "lever" }!
                precondition(alternative.cells[1][0] == "entry_lever" && alternative.cells[3][0] == ".")
            }
        }
        // Reject malformed resources before they reach the native grid renderer.
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var guides = object["guides"] as! [[String: Any]]
        var planes = guides[0]["planes"] as! [[String: Any]]
        planes[0]["cells"] = [["not-a-block"]]
        guides[0]["planes"] = planes; object["guides"] = guides
        let broken = try JSONDecoder().decode(BuildCatalog.self, from: JSONSerialization.data(withJSONObject: object))
        do { try broken.validate(); fatalError("Invalid grid accepted") } catch BuildCatalog.CatalogError.invalid {}
        print("PASS: 53 guides, bilingual search, material counts, matching sections, hopper layout, invalid grid rejection")
    }
}
