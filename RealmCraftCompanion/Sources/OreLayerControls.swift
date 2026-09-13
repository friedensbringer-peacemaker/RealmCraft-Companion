import SwiftUI
import AppKit

enum OreLayerStepper {
    static func next(current: Int, available: [Int], direction: Int) -> Int? {
        direction > 0 ? available.filter { $0 > current }.min() : available.filter { $0 < current }.max()
    }
}

/// Small precise deltas accumulate; inertial tails never advance the layer.
struct OreLayerScrollAccumulator {
    var accumulated = 0.0
    var lastStep = -Double.infinity
    var lastEvent = -Double.infinity
    mutating func consume(delta: Double, horizontal: Double, precise: Bool, momentum: Bool, began: Bool, time: Double) -> Int? {
        guard !momentum, delta.isFinite, abs(delta) > abs(horizontal) else { return nil }
        if began || time - lastEvent > 0.3 || accumulated * delta < 0 { accumulated = 0 }
        lastEvent = time
        if precise && time - lastStep < 0.16 { return nil }
        accumulated += delta
        guard abs(accumulated) >= (precise ? 30 : 1) else { return nil }
        let direction = accumulated > 0 ? 1 : -1
        accumulated = 0; lastStep = time
        return direction
    }
}

struct OreLayerWheel: NSViewRepresentable {
    var requiresOption = true
    let step: (Int) -> Void
    final class WheelView: NSView {
        var step: (Int) -> Void = { _ in }
        var requiresOption = true
        var monitor: Any?
        var accumulator = OreLayerScrollAccumulator()
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        func install() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, let window = self.window, event.window === window, !self.isHiddenOrHasHiddenAncestor,
                      !self.requiresOption || event.modifierFlags.contains(.option),
                      self.visibleRect.contains(self.convert(event.locationInWindow, from: nil)),
                      abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) else { return event }
                // Normalize natural scrolling so a physical upward motion means higher Y.
                let delta = Double(event.scrollingDeltaY) * (event.isDirectionInvertedFromDevice ? -1 : 1)
                if let direction = self.accumulator.consume(delta: delta, horizontal: Double(event.scrollingDeltaX),
                    precise: event.hasPreciseScrollingDeltas, momentum: !event.momentumPhase.isEmpty,
                    began: event.phase.contains(.began), time: event.timestamp) { self.step(direction) }
                return nil
            }
        }
        deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    }
    func makeNSView(context: Context) -> WheelView {
        let view = WheelView(); view.step = step; view.requiresOption = requiresOption; view.install(); return view
    }
    func updateNSView(_ view: WheelView, context: Context) { view.step = step; view.requiresOption = requiresOption }
    static func dismantleNSView(_ view: WheelView, coordinator: ()) {
        if let monitor = view.monitor { NSEvent.removeMonitor(monitor); view.monitor = nil }
    }
}

struct OreLayerControls: View {
    @Binding var y: Int
    let bounds: ClosedRange<Int>
    let available: [Int]
    let english: Bool
    let step: (Int) -> Void
    @Environment(\.companionTheme) private var theme
    private func t(_ de: String, _ en: String) -> String { english ? en : de }
    private var height: Binding<Int> { Binding(get: { y }, set: { y = min(bounds.upperBound, max(bounds.lowerBound, $0)) }) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button { step(-1) } label: { Label(t("Tiefer", "Lower"), systemImage: "arrow.down").frame(width: 76, height: 28) }
                    .disabled(OreLayerStepper.next(current: y, available: available, direction: -1) == nil)
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    Text(t("Ebene Y", "Layer Y")).font(.headline)
                    TextField("Y", value: height, format: .number.grouping(.never))
                        .font(.system(size: 26, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(theme.accent).multilineTextAlignment(.center).textFieldStyle(.roundedBorder).frame(width: 78)
                        .accessibilityLabel(t("Gewählte Ebene Y", "Selected layer Y"))
                }
                Spacer(minLength: 0)
                Button { step(1) } label: { Label(t("Höher", "Higher"), systemImage: "arrow.up").frame(width: 76, height: 28) }
                    .disabled(OreLayerStepper.next(current: y, available: available, direction: 1) == nil)
            }
            .focusable().focusEffectDisabled()
            .onKeyPress(.upArrow) { step(1); return .handled }
            .onKeyPress(.downArrow) { step(-1); return .handled }
            .background(OreLayerWheel(requiresOption: false, step: step))
            HStack {
                Text("Y \(bounds.lowerBound)")
                Slider(value: Binding(get: { Double(y) }, set: { height.wrappedValue = Int($0.rounded()) }),
                       in: Double(bounds.lowerBound)...Double(max(bounds.lowerBound + 1, bounds.upperBound)), step: 1)
                    .disabled(bounds.lowerBound == bounds.upperBound)
                    .accessibilityLabel(t("Ebene wählen", "Choose layer"))
                Text("Y \(bounds.upperBound)")
            }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Text(t("Über der Ebenenzeile: Mausrad oder mit zwei Fingern scrollen · ↑ / ↓ bei Fokus", "Over the layer row: mouse wheel or two-finger scroll · ↑ / ↓ when focused"))
                .font(.caption).foregroundStyle(.secondary)
        }.padding(12).background(theme.surface)
    }
}
