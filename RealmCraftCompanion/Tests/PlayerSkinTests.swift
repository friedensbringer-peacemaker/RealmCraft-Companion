import Foundation
@main struct Tests {
 static func main() {
 var p = PlayerSkinProfile(); p.configured = true; p.parts.shirt = 51; p.gender = "Girl"; p.parts.pants = 39; p.hand = 1
 assert(PlayerSkinProfile.decode(p.encoded) == p)
 p.gender = "Boy"; assert(p.parts.shirt == 51); p.gender = "Girl"; assert(p.parts.pants == 39)
 p.parts.body = -5; p.parts.shirt = 999; p.hand = 999
 let q = PlayerSkinProfile.decode(p.encoded); assert(q.parts.body == 0 && q.parts.shirt == 41 && q.hand == 1)
 assert(!PlayerSkinProfile.decode("corrupt").configured)
 p.version = 99; assert(!PlayerSkinProfile.decode(p.encoded).configured)
 print("Skin profile tests passed")
 }
}
