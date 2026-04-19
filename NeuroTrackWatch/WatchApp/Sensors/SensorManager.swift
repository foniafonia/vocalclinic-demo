import CoreMotion
import Combine
import WatchKit

// MARK: - SensorManager

/// Wraps CMMotionManager for watchOS.
///
/// Lifecycle notes:
///  - In foreground: DeviceMotion runs at `targetSampleRate` (50 Hz).
///  - Long sessions require a WKExtendedRuntimeSession (workout type) to keep
///    the app active. The caller is responsible for managing that session;
///    SensorManager only handles CoreMotion.
///  - Apple Watch delivers deviceMotion at the requested rate only while
///    the display is active or an extended runtime session is active.
///    Without it, the OS may throttle updates to ~1 Hz after wrist-down.
final class SensorManager: ObservableObject {

    static let shared = SensorManager()

    /// Requested sample rate. watchOS honours this in foreground/extended sessions.
    static let targetSampleRate: Double = 50.0

    let samplePublisher = PassthroughSubject<MotionSample, Never>()

    @Published private(set) var isRunning = false
    @Published private(set) var isAvailable: Bool

    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.name = "com.neurotrack.motion"
        q.qualityOfService = .userInitiated
        return q
    }()

    private init() {
        isAvailable = CMMotionManager().isDeviceMotionAvailable
    }

    // MARK: - Control

    func startCapture() {
        guard isAvailable, !isRunning else { return }

        motion.deviceMotionUpdateInterval = 1.0 / SensorManager.targetSampleRate
        motion.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: queue
        ) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            let sample = MotionSample(
                timestamp: data.timestamp,
                ax: data.userAcceleration.x,
                ay: data.userAcceleration.y,
                az: data.userAcceleration.z,
                rx: data.rotationRate.x,
                ry: data.rotationRate.y,
                rz: data.rotationRate.z
            )
            self.samplePublisher.send(sample)
        }

        DispatchQueue.main.async { self.isRunning = true }
    }

    func stopCapture() {
        guard isRunning else { return }
        motion.stopDeviceMotionUpdates()
        DispatchQueue.main.async { self.isRunning = false }
    }
}
