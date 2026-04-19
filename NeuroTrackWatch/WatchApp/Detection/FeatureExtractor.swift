import Foundation

// MARK: - Window features

/// Signal features extracted from one analysis window.
struct WindowFeatures {
    /// Capture time (end of window)
    let timestamp: Date

    /// Root-mean-square of gravity-removed acceleration magnitude (g)
    let rmsAcceleration: Double

    /// Sample variance of acceleration magnitude
    let varianceAcceleration: Double

    /// Zero-crossing rate of mean-centred magnitude signal (crossings / sample)
    let zeroCrossingRate: Double

    /// Peak of normalised autocorrelation in the 1–4 Hz lag band.
    /// Range [0, 1]; values ≥ 0.30 indicate notable periodicity.
    let rhythmicityScore: Double

    /// Frequency (Hz) corresponding to the autocorrelation peak lag.
    /// 0 when no significant periodic component is found.
    let dominantFrequencyHz: Double
}

// MARK: - FeatureExtractor

/// Stateless extractor — pure functions only.
struct FeatureExtractor {

    let sampleRate: Double

    // Autocorrelation search band: 1–4 Hz is the typical stereotypy range.
    // Below 1 Hz = slow drift; above 4 Hz = fine tremor / artefact.
    private var minLagSamples: Int { Int(sampleRate / 4.0) }
    private var maxLagSamples: Int { Int(sampleRate / 1.0) }

    // MARK: - Public

    func extract(from samples: [MotionSample]) -> WindowFeatures {
        let mags = samples.map(\.magnitude)

        let rms      = computeRMS(mags)
        let variance = computeVariance(mags)
        let zcr      = computeZeroCrossingRate(mags)
        let (rhythmicity, dominantFreq) = computeRhythmicity(mags)

        return WindowFeatures(
            timestamp: Date(),
            rmsAcceleration: rms,
            varianceAcceleration: variance,
            zeroCrossingRate: zcr,
            rhythmicityScore: rhythmicity,
            dominantFrequencyHz: dominantFreq
        )
    }

    // MARK: - Private helpers

    private func computeRMS(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sumSq = values.reduce(0.0) { $0 + $1 * $1 }
        return (sumSq / Double(values.count)).squareRoot()
    }

    private func computeVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let n = Double(values.count)
        let mean = values.reduce(0, +) / n
        let sumSq = values.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
        return sumSq / (n - 1)
    }

    private func computeZeroCrossingRate(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let centred = values.map { $0 - mean }
        var crossings = 0
        for i in 1 ..< centred.count where centred[i - 1] * centred[i] < 0 {
            crossings += 1
        }
        return Double(crossings) / Double(values.count - 1)
    }

    /// Normalised autocorrelation — searches lags corresponding to 1–4 Hz.
    /// Returns the peak correlation coefficient and corresponding frequency.
    private func computeRhythmicity(_ values: [Double]) -> (score: Double, freqHz: Double) {
        let n = values.count
        guard n > maxLagSamples * 2 else { return (0, 0) }

        let mean = values.reduce(0, +) / Double(n)
        let centred = values.map { $0 - mean }

        // r(0) — normalisation denominator
        let r0 = centred.reduce(0.0) { $0 + $1 * $1 }
        guard r0 > 1e-10 else { return (0, 0) }

        var peakCorr = 0.0
        var peakLag  = 0

        let lagEnd = min(maxLagSamples, n / 2)
        for lag in minLagSamples ... lagEnd {
            var corr = 0.0
            for i in 0 ..< (n - lag) {
                corr += centred[i] * centred[i + lag]
            }
            let normalised = corr / r0
            if normalised > peakCorr {
                peakCorr = normalised
                peakLag  = lag
            }
        }

        let freqHz = peakLag > 0 ? sampleRate / Double(peakLag) : 0
        return (peakCorr, freqHz)
    }
}
