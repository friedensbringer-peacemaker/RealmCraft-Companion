import SwiftUI

struct BuildCoachView: View {
    let guide: BuildGuide
    let blocks: [String: BuildBlock]
    let english: Bool
    @Binding var step: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = VideoTipSpeech()
    @State private var autoRead = false
    @State private var referenceOpen = true
    @State private var selected = ""
    @State private var copied = false
    @State private var show3D = true
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(english ? "Build coach" : "Bau-Coach", systemImage: "headphones").font(.title2.bold())
                Spacer()
                Button(english ? "Close" : "Schließen") { dismiss() }
            }
            Text(guide.title.value(english)).font(.headline)
            HStack {
                Text(english ? "Step \(step + 1) of \(guide.steps.count)" : "Schritt \(step + 1) von \(guide.steps.count)").monospacedDigit()
                ProgressView(value: Double(step + 1), total: Double(guide.steps.count))
                Text(english ? "Untested · AI-generated" : "Ungetestet · KI-generiert").font(.caption).foregroundStyle(.orange)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    DisclosureGroup(english ? "Agree on the building reference" : "Baubezug vereinbaren", isExpanded: $referenceOpen) {
                        Text(BuildCoach.reference(english: english)).font(.callout)
                        Button(english ? "Read orientation" : "Orientierung vorlesen") { speech.read(BuildCoach.reference(english: english), english: english) }
                    }
                    Text(guide.steps[step].value(english)).font(.title2).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                    HStack {
                        Button { readStep() } label: { Label(english ? "Read / repeat" : "Vorlesen / wiederholen", systemImage: "speaker.wave.2") }
                        Button(english ? "Stop audio" : "Ansage stoppen") { speech.stop() }
                        Toggle(english ? "Read after Next" : "Nach Weiter vorlesen", isOn: $autoRead).toggleStyle(.checkbox)
                    }
                    if !speech.notice.isEmpty { Text(speech.notice).font(.caption).foregroundStyle(.orange) }
                    Picker(english ? "Preview" : "Vorschau", selection: $show3D) {
                        Text(english ? "3D model" : "3D-Modell").tag(true)
                        Text(english ? "2D grids" : "2D-Raster").tag(false)
                    }.pickerStyle(.segmented).frame(width: 240)
                    if show3D {
                        BuildGuide3DView(guide: guide, blocks: blocks, step: step, english: english) { key, coordinate in
                            selected = coordinate + " · " + (blocks[key]?.name.value(english) ?? key)
                        }
                    } else {
                        let stage = guide.instructionStages[step]
                        ForEach([stage.top, stage.side]) { plane in
                            Text(plane.title.value(english)).font(.headline)
                            ScrollView(.horizontal) {
                                BuildPaperGrid(plane: plane, blocks: blocks, english: english, cellSize: 40) { key, coordinate in
                                    selected = coordinate + " · " + (blocks[key]?.name.value(english) ?? key)
                                }
                            }
                        }
                    }
                    if !selected.isEmpty { Text(selected).font(.callout) }
                    DisclosureGroup(english ? "Materials for this build" : "Materialien für diesen Aufbau") {
                        ForEach(guide.materials.indices, id: \.self) { i in
                            Text("\(guide.materials[i].count.value(english)) × \(guide.materials[i].name.value(english))")
                        }
                    }
                    Text(english ? "Sound plays on this Mac. For hands-free use with Quest, copy the agent guide into your chosen voice app. No microphone is active here; spoken commands and progress are not synchronized." : "Der Ton kommt von diesem Mac. Für freihändiges Bauen mit der Quest den Agent-Auftrag in deine Sprach-App kopieren. Hier ist kein Mikrofon aktiv; Sprachbefehle und Fortschritt werden nicht synchronisiert.").font(.caption).foregroundStyle(.secondary)
                }.padding(.trailing, 8)
            }
            HStack {
                Button(english ? "Back" : "Zurück") { step -= 1 }.disabled(step == 0)
                Button(english ? "Next" : "Weiter") { step += 1 }.disabled(step + 1 == guide.steps.count)
                    .buttonStyle(CompanionButtonStyle(prominent: true))
                Spacer()
                Menu(english ? "For the voice agent" : "Für den Sprachagenten") {
                    Button(english ? "Copy complete guide + checkpoint" : "Gesamten Auftrag + Zwischenstand kopieren") {
                        copy(guide.audioAgentPrompt(blocks: blocks, english: english) + "\n\n" + BuildCoach.checkpoint(guide: guide, step: step, english: english))
                    }
                    Button(english ? "Copy checkpoint only" : "Nur Zwischenstand kopieren") { copy(BuildCoach.checkpoint(guide: guide, step: step, english: english)) }
                }
                if copied { Text(english ? "Copied" : "Kopiert").font(.caption) }
            }.controlSize(.large)
        }.padding(22).frame(minWidth: 620, idealWidth: 860, maxWidth: .infinity, minHeight: 480, idealHeight: 650, maxHeight: .infinity)
            .onChange(of: step) { _, _ in
                speech.stop(); selected = ""; copied = false
                BuildCoach.save(guide: guide, step: step)
                if autoRead { readStep() }
            }
            .onChange(of: english) { _, _ in speech.stop() }
            .onDisappear { speech.stop() }
    }
    private func readStep() {
        speech.read((english ? "Step \(step + 1). " : "Schritt \(step + 1). ") + guide.steps[step].value(english) + (english ? " Pause here. Continue only when ready." : " Hier pausieren. Erst weitermachen, wenn du bereit bist."), english: english)
    }
    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(text, forType: .string)
    }
}

/// Small catalog overview drawn from the same local voxel data as the large preview.
struct BuildGuideThumbnail: View {
    let guideID: String
    let blocks: [String: BuildBlock]
    var body: some View {
        Canvas { context, size in
            guard let model = BuildVoxelCatalog.guides[guideID], let frame = model.stages.last, !frame.isEmpty else { return }
            let cells = frame.filter { blocks[$0.block]?.color != "air" }
            func point(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { CGPoint(x: x-z, y: (x+z)*0.5-y) }
            let corners = cells.flatMap { v in [point(Double(v.x)-0.5,Double(v.y)+0.5,Double(v.z)-0.5),point(Double(v.x)+0.5,Double(v.y)-0.5,Double(v.z)+0.5),point(Double(v.x)+0.5,Double(v.y)+0.5,Double(v.z)-0.5),point(Double(v.x)-0.5,Double(v.y)+0.5,Double(v.z)+0.5)] }
            guard let minX = corners.map(\.x).min(), let maxX = corners.map(\.x).max(), let minY = corners.map(\.y).min(), let maxY = corners.map(\.y).max() else { return }
            let scale = min((size.width-8)/max(1,maxX-minX),(size.height-8)/max(1,maxY-minY))
            func projected(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
                let p = point(x,y,z)
                return CGPoint(x: (p.x-(minX+maxX)/2)*scale+size.width/2,y:(p.y-(minY+maxY)/2)*scale+size.height/2)
            }
            for v in cells.sorted(by: { ($0.x+$0.z, $0.y) < ($1.x+$1.z, $1.y) }) {
                let x=Double(v.x),y=Double(v.y),z=Double(v.z)
                let tone: Color
                switch blocks[v.block]?.color { case "wood": tone = .brown; case "plant": tone = .green; case "water": tone = .cyan; case "light": tone = .yellow; default: tone = .gray }
                let faces: [[CGPoint]] = [
                    [projected(x-0.5,y+0.5,z-0.5),projected(x+0.5,y+0.5,z-0.5),projected(x+0.5,y+0.5,z+0.5),projected(x-0.5,y+0.5,z+0.5)],
                    [projected(x+0.5,y+0.5,z-0.5),projected(x+0.5,y-0.5,z-0.5),projected(x+0.5,y-0.5,z+0.5),projected(x+0.5,y+0.5,z+0.5)],
                    [projected(x-0.5,y+0.5,z+0.5),projected(x+0.5,y+0.5,z+0.5),projected(x+0.5,y-0.5,z+0.5),projected(x-0.5,y-0.5,z+0.5)]]
                for (i, face) in faces.enumerated() {
                    var path = Path(); path.addLines(face); path.closeSubpath()
                    context.fill(path, with: .color(tone.opacity(i == 0 ? 1 : i == 1 ? 0.65 : 0.8)))
                }
            }
        }.background(Color.black.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel("Schematic build overview")
    }
}
