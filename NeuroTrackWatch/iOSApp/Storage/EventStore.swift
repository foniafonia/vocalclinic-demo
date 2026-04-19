import Foundation
import Combine

// MARK: - EventStore

/// Persistent, observable event repository for the iOS companion app.
///
/// Storage: JSON on disk in the app's Documents directory.
/// Rationale: keeps the MVP dependency-free and makes the data trivially
/// portable / exportable. Move to CoreData only if query performance
/// becomes an issue (unlikely below ~10k events).
final class EventStore: ObservableObject {

    static let shared = EventStore()

    @Published private(set) var events: [DetectedEvent] = []

    private let url: URL
    private let saveQueue = DispatchQueue(label: "com.neurotrack.eventstore", qos: .utility)

    private init() {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("neurotrack_events.json")
        loadSync()
    }

    // MARK: - Write

    func add(_ event: DetectedEvent) {
        guard !events.contains(where: { $0.id == event.id }) else { return }
        events.append(event)
        events.sort { $0.startTime > $1.startTime }
        scheduleAsyncSave()
    }

    func update(_ event: DetectedEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
        scheduleAsyncSave()
    }

    // MARK: - Query

    func events(for date: Date) -> [DetectedEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.startTime, inSameDayAs: date) }
    }

    func events(for date: Date, status: EventValidationStatus) -> [DetectedEvent] {
        events(for: date).filter { $0.validationStatus == status }
    }

    // MARK: - Export

    func exportJSON(for date: Date? = nil) -> Data? {
        let toExport = date.map { events(for: $0) } ?? events
        return try? JSONEncoder().encode(toExport)
    }

    func exportCSV(for date: Date? = nil) -> String {
        let toExport = date.map { events(for: $0) } ?? events
        let rows = toExport.map(\.csvRow)
        return ([DetectedEvent.csvHeader] + rows).joined(separator: "\n")
    }

    // MARK: - Persistence

    private func loadSync() {
        guard
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([DetectedEvent].self, from: data)
        else { return }
        events = decoded
    }

    private func scheduleAsyncSave() {
        let snapshot = events
        saveQueue.async { [url] in
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
