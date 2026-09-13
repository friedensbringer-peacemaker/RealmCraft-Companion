import SwiftUI
import UserNotifications

enum MapNotificationPermission { case unknown, allowed, denied, unavailable }
@MainActor protocol MapNotificationClient {
    func permission() async -> MapNotificationPermission
    func requestPermission() async throws -> Bool
    func send(id: String, gaps: Bool, english: Bool) async throws
}

@MainActor final class SystemMapNotificationClient: MapNotificationClient {
    private var available: Bool { Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil }
    func permission() async -> MapNotificationPermission {
        // CLI and isolated unbundled test executables must not contact the notification service.
        guard available else { return .unavailable }
        let settings=await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .allowed
        case .notDetermined: return .unknown
        default: return .denied
        }
    }
    func requestPermission() async throws -> Bool {
        guard available else { return false }
        return try await UNUserNotificationCenter.current().requestAuthorization(options:[.alert])
    }
    func send(id: String, gaps: Bool, english: Bool) async throws {
        guard available else { return }
        let content=UNMutableNotificationContent()
        content.title=english ? "RealmCraft map ready" : "RealmCraft-Karte fertig"
        content.body=gaps
            ? (english ? "The map has coverage gaps. Open Companion and use Open map to review them." : "Die Karte enthält Datenlücken. Öffne den Companion und prüfe sie über Karte öffnen.")
            : (english ? "Background rendering is complete. Open Companion and use Open map." : "Die Berechnung im Hintergrund ist abgeschlossen. Öffne den Companion und wähle Karte öffnen.")
        // No private world names, coordinates, library paths, or device identifiers on the lock screen.
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:id,content:content,trigger:nil))
    }
}

@MainActor final class MapNotifications: ObservableObject {
    static let preferenceKey="maps.systemCompletionNotifications"
    @Published private(set) var enabled: Bool
    @Published private(set) var requesting=false
    @Published private(set) var permission: MapNotificationPermission = .unknown
    @Published private(set) var failed=false
    private let client: MapNotificationClient
    private let defaults: UserDefaults
    private let isActive: @MainActor () -> Bool
    private var handled: [UUID]=[]
    init(client: MapNotificationClient? = nil, defaults: UserDefaults = .standard,
         isActive: @escaping @MainActor () -> Bool = { NSApplication.shared.isActive }) {
        self.client=client ?? SystemMapNotificationClient(); self.defaults=defaults; self.isActive=isActive
        enabled=defaults.bool(forKey:Self.preferenceKey)
    }
    func refresh() async { permission=await client.permission() }
    func enable() async {
        guard !requesting else { return }
        requesting=true; failed=false
        defer { requesting=false }
        permission=await client.permission()
        do {
            if permission == .unknown { permission = try await client.requestPermission() ? .allowed : .denied }
            enabled=permission == .allowed
        } catch { failed=true; enabled=false }
        defaults.set(enabled,forKey:Self.preferenceKey)
    }
    func disable() { enabled=false; failed=false; defaults.set(false,forKey:Self.preferenceKey) }
    func finished(jobID: UUID, gaps: Bool, english: Bool) async {
        guard !handled.contains(jobID) else { return }
        handled.append(jobID); if handled.count > 128 { handled.removeFirst() }
        guard enabled, !isActive() else { return }
        permission=await client.permission()
        guard enabled, permission == .allowed, !isActive() else { return }
        do { try await client.send(id:"realmcraft.map."+jobID.uuidString,gaps:gaps,english:english); failed=false }
        catch { failed=true } // In-app completion and Open map remain available.
    }
}

struct MapNotificationControls: View {
    @ObservedObject var notifications: MapNotifications
    let english: Bool
    var body: some View {
        VStack(alignment:.leading,spacing:4) {
            HStack {
                Label(english ? "macOS completion notice" : "macOS-Fertigmeldung",systemImage:"bell")
                if notifications.enabled {
                    Button(english ? "Disable" : "Ausschalten") { notifications.disable() }
                } else {
                    Button(english ? "Enable…" : "Aktivieren …") { Task { await notifications.enable() } }.disabled(notifications.requesting)
                }
                if notifications.requesting { ProgressView().controlSize(.small) }
            }.font(.caption)
            Text(message).font(.caption).foregroundStyle(.secondary)
        }.task { await notifications.refresh() }
        .onReceive(NotificationCenter.default.publisher(for:NSApplication.didBecomeActiveNotification)) { _ in Task { await notifications.refresh() } }
    }
    private var message: String {
        if notifications.failed { return english ? "System notice unavailable. Completion remains visible in Companion." : "Systemmitteilung nicht verfügbar. Der Abschluss bleibt im Companion sichtbar." }
        if notifications.permission == .denied { return english ? "Blocked by macOS. Allow notifications in System Settings → Notifications → RealmCraft Companion, then enable here." : "Von macOS gesperrt. Unter Systemeinstellungen → Mitteilungen → RealmCraft Companion erlauben, danach hier aktivieren." }
        if notifications.permission == .unavailable { return english ? "Requires a launched macOS app bundle." : "Benötigt ein gestartetes macOS-App-Bundle." }
        return notifications.enabled
            ? (english ? "Enabled when Companion is in the background; macOS Focus may suppress banners. No world names or coordinates are sent." : "Aktiviert, wenn der Companion im Hintergrund ist; macOS-Fokus kann Banner unterdrücken. Ohne Weltnamen oder Koordinaten.")
            : (english ? "Optional, off by default. macOS asks for permission when enabled; in-app notices stay available." : "Optional, standardmäßig aus. Beim Aktivieren fragt macOS nach Freigabe; Hinweise in der App bleiben verfügbar.")
    }
}
