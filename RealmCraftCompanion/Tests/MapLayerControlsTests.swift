import SwiftUI
import AppKit

struct Savegame: Identifiable {
    let id = "synthetic-backup"
    let title = "Synthetic backup with a deliberately long title"
    let world = "synthetic-world"
    let date = Date(timeIntervalSince1970: 1767268800)
    var gameDate: Date { date }
}
func displayDate(_ date: Date, language: String) -> String { "2026-01-01 12:00" }
private struct Frames: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
private final class Measurement { var action = CGRect.zero }
private struct Fixture: View {
    let en: Bool
    let result: Measurement
    @State private var y = 16
    var body: some View {
        VStack(spacing: 0) {
            CompanionPageHeader(title: en ? "Maps" : "Karten") {
                Button(en ? "Generate map" : "Karte erzeugen") {}
                    .buttonStyle(CompanionButtonStyle(prominent: true))
            }
            MapSourceControls(saves: [Savegame()], selection: .constant("synthetic-backup"), radius: .constant("all"), english: en)
                .padding(.horizontal, CompanionLayout.pageInset)
            OreLayerControls(y: $y, bounds: 0...255, available: Array(0...255), english: en, step: { y = min(255, max(0, y + $0)) }).padding(28)
            Spacer()
        }.companionActionAlignmentScope().onPreferenceChange(CompanionHeaderActionBounds.self) { if !$0.isEmpty { result.action = $0 } }
            .environment(\.companionPageGuidance, CompanionPageGuidance(purpose: en ? "Explore a saved world." : "Eine gespeicherte Welt erkunden.", openHelp: {}))
    }
}
private func descendants(_ v: NSView) -> [NSView] { [v] + v.subviews.flatMap(descendants) }
@main struct MapLayerControlsTests {
    @MainActor static func main() throws {
        var wheel = OreLayerScrollAccumulator()
        assert(wheel.consume(delta: 1, horizontal: 0, precise: false, momentum: false, began: false, time: 1) == 1)
        assert(wheel.consume(delta: -1, horizontal: 0, precise: false, momentum: false, began: false, time: 1.01) == -1)
        assert(wheel.consume(delta: 20, horizontal: 0, precise: true, momentum: false, began: true, time: 2) == nil)
        assert(wheel.consume(delta: 15, horizontal: 0, precise: true, momentum: false, began: false, time: 2.01) == 1)
        assert(wheel.consume(delta: 60, horizontal: 0, precise: true, momentum: false, began: false, time: 2.02) == nil)
        assert(wheel.consume(delta: 60, horizontal: 0, precise: true, momentum: true, began: false, time: 3) == nil)
        assert(wheel.consume(delta: 2, horizontal: 5, precise: false, momentum: false, began: false, time: 4) == nil)
        assert(wheel.consume(delta: 15, horizontal: 0, precise: true, momentum: false, began: true, time: 5) == nil)
        assert(wheel.consume(delta: -20, horizontal: 0, precise: true, momentum: false, began: false, time: 5.1) == nil)
        assert(wheel.consume(delta: -15, horizontal: 0, precise: true, momentum: false, began: false, time: 5.2) == -1)
        assert(OreLayerStepper.next(current: 255, available: [0,255], direction: 1) == nil)
        assert(OreLayerStepper.next(current: 0, available: [0,255], direction: -1) == nil)
        assert(OreLayerStepper.next(current: 5, available: [2,8,12], direction: 1) == 8)
        assert(OreLayerStepper.next(current: 5, available: [], direction: 1) == nil)
        _ = NSApplication.shared
        let out = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for en in [true,false] { for block in [true,false] {
            let result = Measurement()
            let host = NSHostingView(rootView: Fixture(en: en, result: result).environment(\.companionTheme, CompanionTheme(block: block)))
            host.sizingOptions = []
            let window = NSWindow(contentRect: NSRect(x:0,y:0,width:1200,height:500),styleMask:[.borderless],backing:.buffered,defer:false)
            window.appearance = NSAppearance(named: block ? .darkAqua : .aqua)
            window.contentView = host
            for width in [1200.0,500,800,1200] {
                window.setContentSize(NSSize(width:width,height:500)); host.frame=NSRect(x:0,y:0,width:width,height:500)
                host.layoutSubtreeIfNeeded(); RunLoop.current.run(until: Date().addingTimeInterval(0.3))
                let popups = descendants(host).compactMap { $0 as? NSPopUpButton }.filter { !$0.isHiddenOrHasHiddenAncestor }
                let area = popups.first { $0.itemTitles.contains(en ? "All saved chunks" : "Alle gespeicherten Chunks") }!
                let backup = popups.first { $0.itemTitles.contains(where: { $0.hasPrefix("Synthetic") }) }!
                let a = area.convert(area.bounds, to: host), b = backup.convert(backup.bounds, to: host)
                assert(abs(a.width - 180) < 1 && abs(a.height - b.height) < 1)
                assert(abs(a.maxX - min(width-28,result.action.maxX)) < 1, "Area/action right edge: area=\(a), backup=\(b), action=\(result.action), width=\(width)")
                if width >= 800 { assert(abs(a.minY-b.minY)<1 && b.maxX<a.minX, "Single aligned control row") }
                let image=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
                host.cacheDisplay(in:host.bounds,to:image)
                try image.representation(using:.png,properties:[:])!.write(to:out.appendingPathComponent("controls-\(en)-\(block)-\(Int(width)).png"))
            }
            window.contentView=nil
        }}
        print("PASS: 14 navigation checks and 16 DE/EN theme/resize control renders")
    }
}
