//
//  MotionManager.swift
//  FoniaWatch Rehab
//
//  Lectura de acelerómetro / giroscopio para el módulo de Movimiento.
//  Detecta inclinación izquierda/derecha y elevación de muñeca de forma
//  sencilla a partir de la gravedad del device motion.
//

import Foundation
import CoreMotion
import Combine

enum Tilt: String {
    case left = "Izquierda"
    case right = "Derecha"
    case center = "Centro"
    case up = "Arriba"
    case down = "Abajo"
}

final class MotionManager: ObservableObject {

    @Published var tilt: Tilt = .center
    @Published var roll: Double = 0       // inclinación lateral (radianes)
    @Published var pitch: Double = 0      // inclinación frontal (radianes)
    @Published var isAvailable: Bool = false
    @Published var isRunning: Bool = false

    private let motion = CMMotionManager()
    private let queue = OperationQueue()

    init() {
        isAvailable = motion.isDeviceMotionAvailable
    }

    func start() {
        guard motion.isDeviceMotionAvailable, !isRunning else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let roll = data.attitude.roll
            let pitch = data.attitude.pitch
            DispatchQueue.main.async {
                self.roll = roll
                self.pitch = pitch
                self.tilt = Self.classify(roll: roll, pitch: pitch)
            }
        }
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        motion.stopDeviceMotionUpdates()
        isRunning = false
        DispatchQueue.main.async { self.tilt = .center }
    }

    private static func classify(roll: Double, pitch: Double) -> Tilt {
        let threshold = 0.45 // ~25 grados
        if roll > threshold { return .right }
        if roll < -threshold { return .left }
        if pitch > threshold { return .down }
        if pitch < -threshold { return .up }
        return .center
    }
}
