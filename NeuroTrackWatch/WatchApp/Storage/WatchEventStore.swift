import Foundation

// MARK: - WatchEventStore

/// Lightweight persistent queue for events on watchOS.
///
/// Design rationale:
///  - No CoreData on watch — it adds weight and the event volume is low.
///  - JSON on disk in the app's Documents directory.
///  - Acts as a send-buffer: `drainForTransfer()` pops all events so
///    WatchConnectivityManager can forward them to the iPhone.
///  - If WatchConnectivity transfer fails, events stay on disk until next activation.
final class WatchEventStore {

    static let shared = WatchEventStore()

    private let url: URL
    private var buffer: [DetectedEvent] = []
    private let lock = NSLock()

    private init() {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("watch_events_queue.json")
        buffer = Self.loadFromDisk(at: url)
    }

    // MARK: - Write

    func enqueue(_ event: DetectedEvent) {
        lock.withLock {
            buffer.append(event)
            persist()
        }
    }

    // MARK: - Read / drain

    func allEvents() -> [DetectedEvent] {
        lock.withLock { buffer }
    }

    /// Returns all queued events and clears the queue.
    /// Call this before sending to iPhone; re-enqueue on failure.
    func drainForTransfer() -> [DetectedEvent] {
        lock.withLock {
            let copy = buffer
            buffer.removeAll(keepingCapacity: true)
            persist()
            return copy
        }
    }

    /// Re-enqueue events that could not be transferred.
    func requeue(_ events: [DetectedEvent]) {
        lock.withLock {
            buffer.insert(contentsOf: events, at: 0)
            persist()
        }
    }

    // MARK: - Persistence

    private func persist() {
        // Called while holding lock — writes are small and infrequent
        guard let data = try? JSONEncoder().encode(buffer) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func loadFromDisk(at url: URL) -> [DetectedEvent] {
        guard
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([DetectedEvent].self, from: data)
        else { return [] }
        return decoded
    }
}
