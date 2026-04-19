import Foundation

/// Raw inertial measurement from a single CMDeviceMotion frame.
/// `userAcceleration` is gravity-removed; `rotationRate` in rad/s.
struct MotionSample {
    let timestamp: TimeInterval   // absolute CFAbsoluteTime from CMDeviceMotion
    let ax: Double                // user acceleration X (g)
    let ay: Double
    let az: Double
    let rx: Double                // rotation rate X (rad/s)
    let ry: Double
    let rz: Double

    /// Euclidean magnitude of linear acceleration
    var magnitude: Double {
        (ax * ax + ay * ay + az * az).squareRoot()
    }

    /// Combined inertial magnitude (acceleration + rotation contribution)
    var combinedMagnitude: Double {
        let accMag = magnitude
        let rotMag = (rx * rx + ry * ry + rz * rz).squareRoot()
        // Weight rotation less — hand flutter has dominant acceleration signal
        return accMag + 0.1 * rotMag
    }
}
