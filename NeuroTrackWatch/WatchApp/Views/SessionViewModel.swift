import Foundation
import Combine

// MARK: - SessionViewModel

@MainActor
final class SessionViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isRunning       = false
    @Published private(set) var episodeCount    = 0
    @Published private(set) var lastEpisodeTime: Date?
    @Published private(set) var sensorAvailable = true

    // MARK: - Dependencies (injected via composition)

    private let sensorManager  = SensorManager.shared
    private let connectivity   = WatchConnectivityManager.shared
    private let buffer         = MotionBuffer()
    private let extractor      = FeatureExtractor(sampleRate: SensorManager.targetSampleRate)
    private let detector       = HeuristicDetector()

    private var cancellables   = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        sensorAvailable = sensorManager.isAvailable
        connectivity.activate()
        wirePipeline()
    }

    // MARK: - Session control

    func startSession() {
        guard !isRunning else { return }
        isRunning     = true
        episodeCount  = 0
        lastEpisodeTime = nil
        buffer.reset()
        sensorManager.startCapture()
    }

    func stopSession() {
        guard isRunning else { return }
        sensorManager.stopCapture()
        detector.flushPending()
        isRunning = false
    }

    func toggleSession() {
        isRunning ? stopSession() : startSession()
    }

    // MARK: - Pipeline wiring

    private func wirePipeline() {
        // Sensor → buffer (motion queue, non-main)
        sensorManager.samplePublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] sample in
                self?.buffer.append(sample)
            }
            .store(in: &cancellables)

        // Buffer → feature extractor → detector (already on motion queue via onWindow)
        buffer.onWindow = { [weak self] windowSamples in
            guard let self else { return }
            let features = self.extractor.extract(from: windowSamples)
            self.detector.process(features: features)
        }

        // Detector → event dispatch
        detector.onEpisodeDetected = { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.episodeCount    += 1
                self.lastEpisodeTime  = event.startTime

                // Store locally as safety net, then send to iPhone
                WatchEventStore.shared.enqueue(event)
                self.connectivity.send(event: event)
            }
        }
    }
}
