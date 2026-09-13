import Foundation

@MainActor final class FakeMapNotificationClient: MapNotificationClient {
    var status: MapNotificationPermission = .unknown
    var grants=true, throwsOnSend=false, throwsOnRequest=false
    var requests=0
    var sent:[(String,Bool,Bool)]=[]
    var onPermission: (() -> Void)?
    func permission() async -> MapNotificationPermission { onPermission?(); return status }
    func requestPermission() async throws -> Bool {
        requests += 1
        if throwsOnRequest { throw NSError(domain:"fixture",code:1) }
        status=grants ? .allowed : .denied
        return grants
    }
    func send(id:String,gaps:Bool,english:Bool) async throws {
        if throwsOnSend { throw NSError(domain:"fixture",code:2) }
        sent.append((id,gaps,english))
    }
}

@main struct MapNotificationsTests {
    @MainActor static func main() async {
        let suite="realmcraft.notification-test."+UUID().uuidString, defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let client=FakeMapNotificationClient()
        var active=false
        let service=MapNotifications(client:client,defaults:defaults,isActive:{ active })
        precondition(!service.enabled)
        await service.finished(jobID:UUID(),gaps:false,english:false)
        precondition(client.requests == 0 && client.sent.isEmpty,"completion cannot prompt or opt in")
        await service.enable()
        precondition(service.enabled && client.requests == 1 && defaults.bool(forKey:MapNotifications.preferenceKey))
        let job=UUID()
        await service.finished(jobID:job,gaps:true,english:true)
        await service.finished(jobID:job,gaps:true,english:true)
        precondition(client.sent.count == 1 && client.sent[0].1 && client.sent[0].2,"one notice per completed job; preserve gaps and language")
        active=true
        await service.finished(jobID:UUID(),gaps:false,english:false)
        precondition(client.sent.count == 1,"foreground uses in-app notice")
        active=false; client.status = .denied
        await service.finished(jobID:UUID(),gaps:false,english:false)
        precondition(client.sent.count == 1 && client.requests == 1,"revoked permission cannot prompt on completion")
        await service.enable()
        precondition(!service.enabled && client.requests == 1,"denial does not repeatedly request")
        client.status = .allowed; await service.enable()
        client.throwsOnSend=true
        await service.finished(jobID:UUID(),gaps:false,english:false)
        precondition(service.failed)
        client.throwsOnSend=false
        client.onPermission={ service.disable() }
        await service.finished(jobID:UUID(),gaps:false,english:false)
        precondition(client.sent.count == 1,"turning off while checking prevents dispatch")
        client.onPermission=nil; client.status = .unknown; client.throwsOnRequest=true
        await service.enable()
        precondition(!service.enabled && service.failed)
        let systemPermission=await SystemMapNotificationClient().permission()
        precondition(systemPermission == .unavailable,"unbundled tests never touch OS notification service")
        print("PASS: opt-in, permission denial/revocation, deduplication, foreground suppression, failure fallback, disable race and unbundled isolation")
    }
}
