import SwiftUI

/// Equipment preview, deliberately independent of unverified player-skin data.
struct PlayerAvatar: View {
    let armor: [PlayerItem]
    let names: ChestController
    let english: Bool
    private func color(_ slot: Int) -> Color {
        guard let item = armor.first(where: { $0.slot == slot }) else { return Color(red: 0.39, green: 0.43, blue: 0.48) }
        let name = names.name(item.itemID, english: true).lowercased()
        if name.contains("diamond") { return Color(red: 0.20, green: 0.80, blue: 0.86) }
        if name.contains("gold") { return Color(red: 0.91, green: 0.69, blue: 0.22) }
        if name.contains("iron") { return Color(red: 0.75, green: 0.80, blue: 0.85) }
        if name.contains("leather") { return Color(red: 0.59, green: 0.36, blue: 0.22) }
        if name.contains("chain") { return Color(red: 0.46, green: 0.55, blue: 0.63) }
        return Color(red: 0.64, green: 0.52, blue: 0.78)
    }
    var body: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                let scale = min(size.width/260, size.height/300)
                context.translateBy(x: (size.width-260*scale)/2, y: (size.height-300*scale)/2)
                context.scaleBy(x: scale, y: scale)
                context.fill(Path(ellipseIn: CGRect(x: 59, y: 271, width: 150, height: 16)), with: .color(.black.opacity(0.15)))
                func block(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
                    let front = CGRect(x: x, y: y, width: w, height: h)
                    var top = Path(); top.move(to: CGPoint(x:x,y:y)); top.addLine(to: CGPoint(x:x+9,y:y-7)); top.addLine(to: CGPoint(x:x+w+9,y:y-7)); top.addLine(to: CGPoint(x:x+w,y:y)); top.closeSubpath()
                    var side = Path(); side.move(to: CGPoint(x:x+w,y:y)); side.addLine(to: CGPoint(x:x+w+9,y:y-7)); side.addLine(to: CGPoint(x:x+w+9,y:y+h-7)); side.addLine(to: CGPoint(x:x+w,y:y+h)); side.closeSubpath()
                    context.fill(top, with:.color(c)); context.fill(top, with:.color(.white.opacity(0.18)))
                    context.fill(side, with:.color(c)); context.fill(side, with:.color(.black.opacity(0.23)))
                    context.fill(Path(front), with:.color(c))
                    context.stroke(Path(front.insetBy(dx:1,dy:1)), with:.color(.black.opacity(0.16)), lineWidth:2)
                    context.fill(Path(CGRect(x:x+4,y:y+4,width:w-8,height:3)), with:.color(.white.opacity(0.22)))
                }
                let neutral = Color(red:0.39,green:0.43,blue:0.48)
                // Arms and torso reflect the chest slot; uncovered hands stay neutral.
                block(57,99,28,99,color(3)); block(172,99,28,99,color(3))
                block(57,177,28,21,neutral); block(172,177,28,21,neutral)
                block(89,99,79,91,color(3))
                block(89,194,36,63,color(2)); block(132,194,36,63,color(2))
                block(87,247,38,27,color(1)); block(132,247,38,27,color(1))
                block(95,29,67,63,color(4))
                // Face is an abstract visor, not a reconstruction of the user's skin.
                context.fill(Path(CGRect(x:104,y:57,width:49,height:24)), with:.color(neutral.opacity(0.94)))
                context.fill(Path(CGRect(x:113,y:65,width:7,height:5)), with:.color(.white.opacity(0.7)))
                context.fill(Path(CGRect(x:137,y:65,width:7,height:5)), with:.color(.white.opacity(0.7)))
            }.frame(width: 220, height: 270)
                .accessibilityLabel(english ? "Schematic character preview with equipped armor. Personal skin is unknown." : "Schematische Charaktervorschau mit angelegter Rüstung. Persönlicher Skin unbekannt.")
            Text(english ? "Equipment preview" : "Ausrüstungsvorschau").font(.headline)
            Text(english ? "Schematic · personal skin unavailable" : "Schematisch · persönlicher Skin nicht verfügbar").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(width:230)
        }
    }
}
