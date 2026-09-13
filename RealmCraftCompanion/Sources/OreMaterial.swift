import SwiftUI

struct OreMaterial: Identifiable {
    let id: String, de: String, en: String, hex: UInt32, blocks: [Int]
    var color: Color { Color(red: Double(hex >> 16 & 255)/255, green: Double(hex >> 8 & 255)/255, blue: Double(hex & 255)/255) }
    func name(_ english: Bool) -> String { english ? en : de }
    static let all: [Self] = [
        .init(id:"coal",de:"Kohle",en:"Coal",hex:0xA8B4C5,blocks:[35,36]),
        .init(id:"iron",de:"Eisen",en:"Iron",hex:0xE4B89A,blocks:[33,34]),
        .init(id:"copper",de:"Kupfer",en:"Copper",hex:0xEA8B57,blocks:[826,827]),
        .init(id:"gold",de:"Gold",en:"Gold",hex:0xF7CD59,blocks:[31,32]),
        .init(id:"lapis",de:"Lapislazuli",en:"Lapis lazuli",hex:0x658FFF,blocks:[73,74]),
        .init(id:"redstone",de:"Redstone",en:"Redstone",hex:0xF3707F,blocks:[187,188]),
        .init(id:"diamond",de:"Diamant",en:"Diamond",hex:0x59E4E8,blocks:[155,156]),
        .init(id:"emerald",de:"Smaragd",en:"Emerald",hex:0x70DBA0,blocks:[281,282]),
        .init(id:"quartz",de:"Netherquarz",en:"Nether quartz",hex:0xF1E5CE,blocks:[348]),
        .init(id:"nether_gold",de:"Nethergold",en:"Nether gold",hex:0xDEA336,blocks:[37]),
        .init(id:"debris",de:"Antiker Schrott",en:"Ancient debris",hex:0xB99BA7,blocks:[749]),
        .init(id:"amethyst",de:"Amethyst",en:"Amethyst",hex:0xC69BFF,blocks:[811,812,813,814,815,816]),
        .init(id:"chest",de:"Truhen",en:"Chests",hex:0xD6AA70,blocks:[153,283,342]),
        .init(id:"rail",de:"Schienen",en:"Rails",hex:0xB8C983,blocks:[97,98,170,354]),
        .init(id:"spawner",de:"Spawner",en:"Spawners",hex:0xF49ADD,blocks:[151]),
        .init(id:"planks",de:"Bretter",en:"Planks",hex:0xA89568,blocks:[13,14,15,16,17,18,718,719,900]),
        .init(id:"stone",de:"Grundgesteine",en:"Base rocks",hex:0x778B97,blocks:[1,871]),
        .init(id:"special_stone",de:"Besondere Steine",en:"Other rocks",hex:0xB6B4A5,blocks:[2,4,6,817,818])
    ]
    static let byBlock = Dictionary(uniqueKeysWithValues: all.flatMap { m in m.blocks.map { ($0, m) } })
}
