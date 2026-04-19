import Foundation

// MARK: - Validation status

enum EventValidationStatus: String, Codable, CaseIterable {
    case pending      = "pending"
    case validated    = "validated"
    case falsePositive = "falsePositive"

    var label: String {
        switch self {
        case .pending:       return "Pendiente"
        case .validated:     return "Validado"
        case .falsePositive: return "Falso positivo"
        }
    }
}

// MARK: - Detected event

/// One detected episode of repetitive motor activity.
/// All numeric fields are derived from sensor windows — no clinical claims.
struct DetectedEvent: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date

    /// Mean RMS of gravity-removed acceleration across windows in this episode (g)
    let intensityRMS: Double

    /// Normalized autocorrelation peak — 0 (arrhythmic) to 1 (perfectly periodic)
    let rhythmicityScore: Double

    /// Estimated dominant oscillation frequency in Hz
    let dominantFrequencyHz: Double

    /// Number of analysis windows that contributed to this episode
    let windowCount: Int

    var validationStatus: EventValidationStatus
    var notes: String?

    /// Opaque device identifier — allows multi-patient use in future
    let deviceID: String

    // MARK: Computed

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Export helpers

extension DetectedEvent {
    /// Flat dictionary suitable for CSV row generation
    var csvRow: String {
        let fmt = ISO8601DateFormatter()
        let cols: [String] = [
            id.uuidString,
            fmt.string(from: startTime),
            fmt.string(from: endTime),
            String(format: "%.3f", duration),
            String(format: "%.4f", intensityRMS),
            String(format: "%.4f", rhythmicityScore),
            String(format: "%.2f", dominantFrequencyHz),
            "\(windowCount)",
            validationStatus.rawValue,
            notes?.replacingOccurrences(of: ",", with: ";") ?? "",
            deviceID
        ]
        return cols.joined(separator: ",")
    }

    static var csvHeader: String {
        "id,startTime,endTime,durationSeconds,intensityRMS,rhythmicityScore,dominantFreqHz,windowCount,validationStatus,notes,deviceID"
    }
}
