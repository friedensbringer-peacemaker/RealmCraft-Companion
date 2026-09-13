import SwiftUI

/// Original schematic drawings remain available offline, including when no optional artwork is installed.
struct CraftingSketchIcon: View {
    let id: String
    let index: CraftingIndex
    var size: CGFloat = 52
    @ObservedObject private var icons = ItemIconStore.shared
    @AppStorage("companionItemIcons") private var useIcons = false
    @AppStorage("companionIconPack") private var pack = "kenney"
    var body: some View {
        Group {
            if useIcons, let number = index.items[id]?.itemID,
               let image = icons.image(for: number, pack: IconPack(rawValue: pack) ?? .kenney) {
                Image(nsImage: image).resizable().interpolation(.none).scaledToFit()
            } else { CraftingSketch(id: id) }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

private struct CraftingSketch: View {
    let id: String
    private var material: Color {
        if id.contains("diamond") { return .cyan }
        if id.contains("gold") { return .yellow }
        if id.contains("iron") { return Color(white: 0.75) }
        if id.contains("netherite") || id.contains("obsidian") { return .purple.opacity(0.75) }
        if id.contains("stone") { return .gray }
        if id.contains("wood") || id.contains("planks") || id.contains("log") || id == "crafting_table" { return .brown }
        if id.contains("leaf") || id.contains("leaves") || id.contains("sapling") { return .green }
        if id.contains("red") || id.contains("lava") { return .orange }
        return .mint
    }
    var body: some View {
        Canvas { context, size in
            func polygon(_ points: [(Double, Double)], color: Color) {
                var path = Path()
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.0 * size.width, y: first.1 * size.height))
                for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0 * size.width, y: point.1 * size.height)) }
                path.closeSubpath(); context.fill(path, with: .color(color))
            }
            func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
                context.fill(Path(CGRect(x: x * size.width, y: y * size.height, width: w * size.width, height: h * size.height)), with: .color(color))
            }
            if id.hasSuffix("pickaxe") {
                polygon([(0.28,0.91),(0.4,0.97),(0.69,0.32),(0.58,0.26)], color: .brown)
                polygon([(0.18,0.36),(0.29,0.16),(0.62,0.12),(0.87,0.3),(0.91,0.62),(0.74,0.4),(0.54,0.3),(0.34,0.3)], color: material)
            } else if id.hasSuffix("axe") || id.hasSuffix("shovel") || id.hasSuffix("hoe") || id.hasSuffix("sword") {
                rect(0.44,0.38,0.13,0.56,.brown)
                if id.hasSuffix("sword") {
                    polygon([(0.5,0.03),(0.62,0.22),(0.58,0.68),(0.42,0.68),(0.38,0.22)], color: material)
                    rect(0.27,0.66,0.46,0.09,.brown)
                } else if id.hasSuffix("axe") { polygon([(0.23,0.18),(0.69,0.08),(0.86,0.23),(0.82,0.51),(0.43,0.53),(0.44,0.35),(0.22,0.37)], color: material) }
                else if id.hasSuffix("hoe") { rect(0.23,0.19,0.62,0.12,material); rect(0.74,0.29,0.11,0.25,material) }
                else { polygon([(0.29,0.13),(0.71,0.13),(0.72,0.42),(0.5,0.57),(0.28,0.42)], color: material) }
            } else if id == "stick" { polygon([(0.2,0.87),(0.32,0.95),(0.82,0.14),(0.71,0.06)], color: .brown) }
            else if id.contains("bucket") {
                polygon([(0.18,0.3),(0.82,0.3),(0.71,0.89),(0.29,0.89)], color: .gray)
                let filled = id != "bucket"
                polygon([(0.25,0.39),(0.75,0.39),(0.67,0.8),(0.33,0.8)], color: filled ? (id.contains("lava") ? .orange : id.contains("milk") ? .white : .blue) : Color(white: 0.25))
                var handle = Path(); handle.addArc(center: CGPoint(x:size.width * 0.5,y:size.height * 0.32), radius:size.width * 0.29,startAngle:.degrees(185),endAngle:.degrees(355),clockwise:false)
                context.stroke(handle,with:.color(.gray),lineWidth:size.width * 0.07)
                if id.contains("fish") || id.contains("cod") || id.contains("salmon") { polygon([(0.36,0.59),(0.55,0.48),(0.66,0.59),(0.55,0.68)],color:.orange) }
            } else if id == "diamond" || id == "emerald" { polygon([(0.23,0.18),(0.77,0.18),(0.94,0.43),(0.5,0.92),(0.06,0.43)],color:id == "diamond" ? .cyan : .green) }
            else if id.hasSuffix("ingot") { polygon([(0.1,0.68),(0.23,0.38),(0.7,0.23),(0.92,0.49),(0.79,0.75),(0.29,0.88)],color:material) }
            else {
                polygon([(0.5,0.08),(0.9,0.31),(0.5,0.54),(0.1,0.31)],color:material.opacity(0.95))
                polygon([(0.1,0.31),(0.5,0.54),(0.5,0.94),(0.1,0.7)],color:material.opacity(0.6))
                polygon([(0.5,0.54),(0.9,0.31),(0.9,0.7),(0.5,0.94)],color:material.opacity(0.8))
                if id == "crafting_table" {
                    for i in 0..<3 { rect(0.27 + Double(i) * 0.15,0.27,0.08,0.08,Color(white:0.15)) }
                } else if ["furnace","blast_furnace","smoker"].contains(id) { rect(0.58,0.53,0.22,0.18,.orange) }
            }
        }
    }
}

struct CraftingWalkthroughView: View {
    let item: CraftingItem
    let index: CraftingIndex
    let english: Bool
    var recipe: CraftingRecipe? = nil
    var guide: CraftingAcquisition? = nil
    var desired = 1
    var initialStep = 0
    var openItem: (String) -> Void = { _ in }
    @State private var current = 0
    private var steps: [CraftingWalkthroughStep] {
        if let recipe { return CraftingWalkthrough.recipe(recipe,index:index,desired:desired,english:english) }
        return guide.map { CraftingWalkthrough.obtaining($0,english:english) } ?? []
    }
    var body: some View {
        if !steps.isEmpty {
            let position = min(current,steps.count - 1), step = steps[position]
            GroupBox {
                VStack(alignment: .leading,spacing:16) {
                    HStack(spacing:8) {
                        ForEach(Array(steps.enumerated()),id:\.element.id) { offset,value in
                            Button { current = offset } label: {
                                Text("\(offset + 1)").font(.headline).frame(width:30,height:30)
                                    .background(offset == position ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1),in:Circle())
                            }.buttonStyle(.plain).help(value.title)
                                .accessibilityLabel("\(offset + 1). " + value.title)
                                .accessibilityAddTraits(offset == position ? .isSelected : [])
                        }
                        Spacer(minLength:0)
                        Text(english ? "Step \(position + 1) of \(steps.count)" : "Schritt \(position + 1) von \(steps.count)").font(.caption)
                    }
                    Text(step.title).font(.headline)
                    illustration(step).frame(maxWidth:.infinity,alignment:.leading)
                    Text(step.text).fixedSize(horizontal:false,vertical:true).textSelection(.enabled)
                    HStack {
                        Button(english ? "Previous step" : "Vorheriger Schritt") { current = max(0,position - 1) }.disabled(position == 0)
                        Spacer()
                        Button(english ? "Next step" : "Nächster Schritt") { current = min(steps.count - 1,position + 1) }.disabled(position == steps.count - 1)
                    }
                    Text(english ? "Illustrative sketches and optional item artwork; not game screenshots. Names, quantities and source notes are authoritative." : "Erklärende Skizzen und optionale Gegenstandsgrafiken; keine Spielscreenshots. Maßgeblich sind Namen, Mengen und Quellenhinweise.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(10)
            } label: { Label(english ? "Illustrated walkthrough" : "Bebilderte Schritt-für-Schritt-Anleitung",systemImage:"square.stack.3d.up") }
            .onAppear { current = min(max(0, initialStep), steps.count - 1) }
            .onChange(of: recipe?.id) { _,_ in current = 0 }
            .onChange(of: item.id) { _,_ in current = 0 }
        }
    }
    @ViewBuilder private func illustration(_ step: CraftingWalkthroughStep) -> some View {
        if let recipe {
            switch step.visual {
            case .ingredients:
                ForEach(Array(recipe.ingredients.enumerated()),id:\.offset) { _,ingredient in
                    if let first = ingredient.options.first {
                        HStack(spacing:12) {
                            CraftingSketchIcon(id:first,index:index)
                            VStack(alignment:.leading,spacing:5) {
                                Text("\(ingredient.count * recipe.batches(for:desired)) × " + index.ingredientName(ingredient,english:english)).font(.callout.weight(.semibold))
                                if ingredient.options.count > 1 { Text(english ? "The picture shows one alternative." : "Das Bild zeigt eine Alternative.").font(.caption).foregroundStyle(.secondary) }
                                if index.recipes[first] != nil || index.acquisitions[first] != nil {
                                    Button(english ? "Look up this ingredient" : "Diese Zutat nachschlagen") { openItem(first) }.font(.caption)
                                }
                            }
                        }
                    }
                }
            case .station,.action:
                HStack(spacing:18) {
                    if let station = CraftingWalkthrough.stationItem(recipe.station) {
                        CraftingSketchIcon(id:station,index:index,size:72)
                        VStack(alignment:.leading) {
                            Text(recipe.station.title(english)).font(.headline)
                            if index.recipes[station] != nil { Button(english ? "Station recipe" : "Rezept der Station") { openItem(station) } }
                        }
                    } else { Image(systemName:"square.grid.2x2").font(.system(size:48)); Text(recipe.station.title(english)) }
                    if step.visual == .action { Image(systemName:"arrow.right"); CraftingSketchIcon(id:item.id,index:index,size:64) }
                }
            case .arrangement:
                if recipe.shaped { CraftingRecipeGrid(recipe:recipe,index:index,english:english) }
                else { HStack { Image(systemName:"shuffle").font(.largeTitle); Text(english ? "All ingredients · no fixed grid" : "Alle Zutaten · ohne festes Raster") } }
            case .result:
                HStack(spacing:18) { CraftingSketchIcon(id:item.id,index:index,size:88); Text("\(recipe.produced(for:desired)) × " + item.title.value(english)).font(.title3.bold()) }
            case .obtaining: EmptyView()
            }
        } else if let guide {
            HStack(spacing:18) {
                if let input = guide.relatedItems.first { CraftingSketchIcon(id:input,index:index,size:60) }
                Image(systemName:obtainingSymbol(guide.id)).font(.system(size:36)).foregroundStyle(guide.id.contains("lava") ? Color.orange : Color.accentColor)
                Image(systemName:"arrow.right")
                VStack { CraftingSketchIcon(id:item.id,index:index,size:72); Text(item.title.value(english)).font(.caption) }
            }
        }
    }
    private func obtainingSymbol(_ id: String) -> String {
        if id.contains("bucket") || id.hasSuffix("placed") { return id == "milk-bucket" ? "pawprint.fill" : "drop.fill" }
        if id == "leaves" || id == "saplings" { return "leaf.fill" }
        if id == "logs" || id == "stripped-wood" { return "tree.fill" }
        if id.hasPrefix("drop-") { return "pawprint.fill" }
        if id == "spawn-eggs" { return "square.grid.2x2" }
        return "hand.point.up.left.fill"
    }
}
