import Foundation
import Network
import Observation

/// Whether the phone is online, so maps only show when they can load. Offline, the spots fall back
/// to their addresses and Apple Maps, which has its own offline maps.
@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.isOnline = online
            }
        }
        monitor.start(queue: DispatchQueue(label: "io.github.li1000v2.mammamia.network"))
    }
}
