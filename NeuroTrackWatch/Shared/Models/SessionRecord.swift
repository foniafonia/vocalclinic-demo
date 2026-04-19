import Foundation

/// Metadata for a single recording session.
/// Events reference sessions via `sessionID` for future grouping.
struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let deviceID: String
    var eventCount: Int

    var duration: TimeInterval? {
        endTime.map { $0.timeIntervalSince(startTime) }
    }

    init(deviceID: String) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.deviceID = deviceID
        self.eventCount = 0
    }
}
