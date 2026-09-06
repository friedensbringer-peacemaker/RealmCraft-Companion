import Foundation

private enum BuildVoxelError: Error { case invalid }

struct BuildVoxel: Decodable, Hashable {
    let x: Int
    let y: Int
    let z: Int
    let block: String
    init(from decoder: Decoder) throws {
        var fields = try decoder.unkeyedContainer()
        x = try fields.decode(Int.self); y = try fields.decode(Int.self); z = try fields.decode(Int.self)
        block = try fields.decode(String.self)
        guard fields.isAtEnd else { throw BuildVoxelError.invalid }
    }
    var coordinate: String { "\(x),\(y),\(z)" }
}
struct BuildVoxelGuide: Decodable {
    let complete: Bool
    let stages: [[BuildVoxel]]
    func validate(guide: BuildGuide, blocks: [String: BuildBlock]) throws {
        guard stages.count == guide.steps.count else { throw BuildVoxelError.invalid }
        for stage in stages {
            guard stage.count <= 30_000, Set(stage.map(\.coordinate)).count == stage.count,
                  stage.allSatisfy({ (-128...128).contains($0.x) && (-128...128).contains($0.y) && (-128...128).contains($0.z) && blocks[$0.block] != nil }) else { throw BuildVoxelError.invalid }
        }
    }
}
enum BuildVoxelCatalog {
    static let guides: [String: BuildVoxelGuide] = {
        guard let url = Bundle.main.url(forResource: "BuildGuideVoxels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let models = try? JSONDecoder().decode([String: BuildVoxelGuide].self, from: data),
              let catalog = try? BuildCatalog.load() else { return [:] }
        return models.filter { id, model in
            guard let guide = catalog.guides.first(where: { $0.id == id }) else { return false }
            return (try? model.validate(guide: guide, blocks: catalog.blocks)) != nil
        }
    }()
}
