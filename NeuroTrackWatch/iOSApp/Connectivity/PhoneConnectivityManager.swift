import Foundation
import WatchConnectivity

// MARK: - PhoneConnectivityManager

/// Receives events from the Apple Watch and feeds them into `EventStore`.
///
/// Handles both real-time messages (watch app in foreground + reachable)
/// and guaranteed `userInfo` transfers (background delivery).
final class PhoneConnectivityManager: NSObject {

    static let shared = PhoneConnectivityManager()

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Payload decoding

    private func ingest(_ dict: [String: Any]) {
        guard
            let data  = dict["event"] as? Data,
            let event = try? JSONDecoder().decode(DetectedEvent.self, from: data)
        else { return }

        Task { @MainActor in
            EventStore.shared.add(event)
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    // Real-time message (watch reachable)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        ingest(message)
    }

    // Guaranteed background transfer
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        ingest(userInfo)
    }

    // Required on iOS — handle watch paired state changes
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
