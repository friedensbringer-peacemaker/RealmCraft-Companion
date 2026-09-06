import Foundation

@main struct StatisticsTests {
    static func fixture(name: String = "Synthetic 世界", hashLength: Int = 20, count: UInt64 = 209_538) -> Data {
        var b: [UInt8] = [9]
        func append(_ value: UInt64, _ size: Int) { for n in (0..<size).reversed() { b.append(UInt8(truncatingIfNeeded: value >> (8*n))) } }
        append(123, 4); append(456, 8)
        append(UInt64(name.utf8.count), 4); b += name.utf8
        append(9999, 8); append(639_243_994_711_589_080, 8)
        b += [0, 1, 0, 0] // world/game/network/always day
        append(12, 4); append(67, 4); append(8, 4); b += [0] // spawn
        append(UInt64(hashLength), 4); b += Array(repeating: 0xaa, count: hashLength)
        b += Array(repeating: 0, count: 15) // weather
        append(count, 8); b += Array(repeating: 0, count: 25) // remaining v9 metadata
        return Data(b)
    }
    static func main() throws {
        func reject(_ data: Data, world: String = "123") {
            do { _ = try StatisticsReader.parse(data, expectedWorld: world); fatalError("Expected failure") } catch {}
        }
        for name in ["A", "Synthetic 世界", String(repeating: "x", count: 4096)] {
            for hash in [0,20,32,128] {
                for count in [UInt64(0), 209_538, UInt64(Int32.max)+123, UInt64(Int64.max)] {
                    let r = try StatisticsReader.parse(fixture(name: name, hashLength: hash, count: count), expectedWorld: "123")
                    precondition(r.worldName == name && r.worldID == 123 && r.buildDigActions == Int64(count))
                }
            }
        }
        let valid = fixture()
        for end in 0..<valid.count { reject(valid.prefix(end)) }
        var version = valid; version[0] = 10; reject(version)
        reject(valid, world: "124")
        reject(fixture(count: UInt64.max)); reject(fixture(name: "")); reject(fixture(name: String(repeating: "x", count: 4097)))
        reject(fixture(name: "bad\0name")); reject(fixture(hashLength: 129))
        var invalidUTF8 = fixture(name: "a"); invalidUTF8[17] = 255; reject(invalidUTF8)
        var hugeLength = valid; hugeLength.replaceSubrange(13..<17, with: [255,255,255,255]); reject(hugeLength)
        reject(Data(repeating: 0, count: 1_000_001))
        // Optional private regression paths are never packaged into the test source.
        for path in CommandLine.arguments.dropFirst() {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let id = data[1..<5].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            let r = try StatisticsReader.parse(data, expectedWorld: String(id))
            print("Private regression: \(r.worldID) = \(r.buildDigActions)")
        }
        print("PASS: statistics parser, variable lengths, zero/64-bit counters, all truncations, version, identity and malformed input")
    }
}
