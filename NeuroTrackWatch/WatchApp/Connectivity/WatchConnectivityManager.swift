import Foundation
import WatchConnectivity

// MARK: - WatchConnectivityManager (watchOS side)

/// Sends detected events to the iPhone companion app.
///
/// Transfer strategy (in preference order):
///   1. `sendMessage` — instant delivery when iPhone app is in foreground & reachable.
///   2. `transferUserInfo` — guaranteed background delivery, queued by the OS.
///
/// On activation, any events queued in `WatchEventStore` are flushed automatically.
final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send

    func send(event: DetectedEvent) {
        guard WCSession.default.activationState == .activated else {
            WatchEventStore.shared.enqueue(event)
            return
        }

        do {
            let payload: [String: Any] = ["event": try JSONEncoder().encode(event)]

            if WCSession.default.isReachable {
                WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                    // iPhone not available right now — use guaranteed transfer
                    self?.transferViaUserInfo(event)
                }
            } else {
                transferViaUserInfo(event)
            }
        } catch {
            WatchEventStore.shared.enqueue(event)
        }
    }

    // MARK: - Flush queued events

    func flushQueue() {
        let pending = WatchEventStore.shared.drainForTransfer()
        guard !pending.isEmpty else { return }

        for event in pending {
            do {
                let payload: [String: Any] = ["event": try JSONEncoder().encode(event)]
                WCSession.default.transferUserInfo(payload)
            } catch {
                // Re-queue this one — don't lose it
                WatchEventStore.shared.enqueue(event)
            }
        }
    }

    // MARK: - Private

    private func transferViaUserInfo(_ event: DetectedEvent) {
        do {
            let payload: [String: Any] = ["event": try JSONEncoder().encode(event)]
            WCSession.default.transferUserInfo(payload)
        } catch {
            WatchEventStore.shared.enqueue(event)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated {
            flushQueue()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            flushQueue()
        }
    }
}
