import Foundation

// MARK: - MotionBuffer

/// Accumulates MotionSamples and emits fixed-size overlapping windows.
///
/// Window parameters:
///   windowDuration = 2.0 s → 100 samples @50 Hz  (captures 1–4 Hz oscillations cleanly)
///   stepDuration   = 0.5 s → 25-sample step       (75% overlap, 2 Hz analysis rate)
///
/// Memory: keeps only the minimum samples needed; trims aggressively.
final class MotionBuffer {

    let windowDuration: Double
    let stepDuration: Double
    let sampleRate: Double

    /// Called on the motion queue with a complete window slice.
    var onWindow: (([MotionSample]) -> Void)?

    private var samples: [MotionSample] = []
    private var emitCursor: Int = 0   // index of first sample in next window

    var windowSize: Int { Int(windowDuration * sampleRate) }
    var stepSize: Int   { Int(stepDuration  * sampleRate) }

    init(
        windowDuration: Double = 2.0,
        stepDuration: Double   = 0.5,
        sampleRate: Double     = SensorManager.targetSampleRate
    ) {
        self.windowDuration = windowDuration
        self.stepDuration   = stepDuration
        self.sampleRate     = sampleRate
        samples.reserveCapacity(windowSize * 4)
    }

    // MARK: - Feed

    func append(_ sample: MotionSample) {
        samples.append(sample)

        while samples.count - emitCursor >= windowSize {
            let window = Array(samples[emitCursor ..< emitCursor + windowSize])
            onWindow?(window)
            emitCursor += stepSize
        }

        // Trim consumed samples to bound memory — keep one extra windowSize as guard
        let trimThreshold = windowSize * 6
        if emitCursor > trimThreshold {
            samples.removeFirst(emitCursor)
            emitCursor = 0
        }
    }

    func reset() {
        samples.removeAll(keepingCapacity: true)
        emitCursor = 0
    }
}
