import Foundation

// MARK: - Thresholds

/// All numeric limits for episode detection.
/// Stored in UserDefaults so they can be adjusted per patient without recompiling.
struct DetectorThresholds: Codable {

    /// Minimum RMS acceleration to consider window active (g)
    var minRMS: Double = 0.15

    /// Minimum signal variance — filters out constant-velocity sweeps
    var minVariance: Double = 0.015

    /// Minimum autocorrelation peak — rhythmicity requirement
    var minRhythmicity: Double = 0.28

    /// Oscillation frequency band (Hz) — typical motor stereotypy range
    var minFrequencyHz: Double = 1.0
    var maxFrequencyHz: Double = 4.5

    /// How many consecutive active windows open an episode
    var minConsecutiveWindows: Int = 3   // 3 × 0.5 s step = 1.5 s minimum

    /// Consecutive silent windows tolerated within an ongoing episode before closing it
    var gapToleranceWindows: Int = 2     // 1.0 s gap bridge

    // MARK: - Persistence

    private static let defaultsKey = "DetectorThresholds"

    static func load() -> DetectorThresholds {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode(DetectorThresholds.self, from: data)
        else {
            return DetectorThresholds()
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: DetectorThresholds.defaultsKey)
    }
}

// MARK: - HeuristicDetector

/// Stateful sliding-window episode detector.
///
/// Feed one `WindowFeatures` per analysis step. The detector accumulates
/// consecutive active windows into episodes, tolerates brief silent gaps,
/// and fires `onEpisodeDetected` when an episode ends.
final class HeuristicDetector {

    var thresholds: DetectorThresholds {
        didSet { thresholds.save() }
    }

    /// Called on the motion queue when a full episode is finalised.
    var onEpisodeDetected: ((DetectedEvent) -> Void)?

    // MARK: - State

    private var consecutiveActive: Int = 0
    private var gapCount: Int          = 0
    private var episodeOpen: Bool      = false
    private var episodeStart: Date?
    private var windowAccumulator: [WindowFeatures] = []

    init(thresholds: DetectorThresholds = .load()) {
        self.thresholds = thresholds
    }

    // MARK: - Feed

    func process(features: WindowFeatures) {
        if meetsThresholds(features) {
            gapCount = 0
            consecutiveActive += 1
            windowAccumulator.append(features)

            // Open episode once we have enough consecutive active windows
            if !episodeOpen && consecutiveActive >= thresholds.minConsecutiveWindows {
                episodeOpen  = true
                episodeStart = windowAccumulator.first?.timestamp ?? features.timestamp
            }

        } else {
            if episodeOpen {
                gapCount += 1
                if gapCount <= thresholds.gapToleranceWindows {
                    // Bridge small gaps — common in real flapping cycles
                    windowAccumulator.append(features)
                } else {
                    finaliseEpisode(endTime: features.timestamp)
                }
            } else {
                // No open episode — reset streak
                consecutiveActive = 0
                windowAccumulator.removeAll(keepingCapacity: true)
            }
        }
    }

    /// Call when stopping a session to emit any open episode.
    func flushPending(at endTime: Date = Date()) {
        guard episodeOpen else {
            resetState()
            return
        }
        finaliseEpisode(endTime: endTime)
    }

    // MARK: - Private

    private func meetsThresholds(_ f: WindowFeatures) -> Bool {
        f.rmsAcceleration     >= thresholds.minRMS          &&
        f.varianceAcceleration >= thresholds.minVariance     &&
        f.rhythmicityScore    >= thresholds.minRhythmicity  &&
        f.dominantFrequencyHz >= thresholds.minFrequencyHz  &&
        f.dominantFrequencyHz <= thresholds.maxFrequencyHz
    }

    private func finaliseEpisode(endTime: Date) {
        defer { resetState() }

        guard let start = episodeStart, !windowAccumulator.isEmpty else { return }

        // Discard trailing gap windows from the accumulator before computing means
        let activeWindows = windowAccumulator.filter { meetsThresholds($0) }
        let windows = activeWindows.isEmpty ? windowAccumulator : activeWindows

        let meanRMS = windows.map(\.rmsAcceleration).mean()
        let meanRhythmicity = windows.map(\.rhythmicityScore).mean()
        let freqs = windows.map(\.dominantFrequencyHz).filter { $0 > 0 }
        let meanFreq = freqs.isEmpty ? 0 : freqs.mean()

        let event = DetectedEvent(
            id: UUID(),
            startTime: start,
            endTime: endTime,
            intensityRMS: meanRMS,
            rhythmicityScore: meanRhythmicity,
            dominantFrequencyHz: meanFreq,
            windowCount: windows.count,
            validationStatus: .pending,
            notes: nil,
            deviceID: DeviceIdentifier.current
        )

        onEpisodeDetected?(event)
    }

    private func resetState() {
        consecutiveActive = 0
        gapCount          = 0
        episodeOpen       = false
        episodeStart      = nil
        windowAccumulator.removeAll(keepingCapacity: true)
    }
}

// MARK: - Helpers

private extension Array where Element == Double {
    func mean() -> Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}

// MARK: - Device identifier

enum DeviceIdentifier {
    static var current: String {
        let key = "com.neurotrack.deviceID"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
