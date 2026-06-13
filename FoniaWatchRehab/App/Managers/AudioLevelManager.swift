//
//  AudioLevelManager.swift
//  FoniaWatch Rehab
//
//  Biofeedback de voz REAL (aproximado) usando el micrófono del reloj.
//  Mide el nivel RMS de la señal de entrada y lo expone como:
//    - decibels: nivel aproximado en dBFS (negativo, 0 = máximo)
//    - level: valor normalizado 0...1 para animaciones
//    - isVoicing: true cuando hay voz por encima del umbral
//
//  LIMITACIÓN: no es un sonómetro calibrado. Sirve como medida RELATIVA
//  de intensidad y estabilidad, suficiente para biofeedback terapéutico.
//  Para una intensidad calibrada en dB SPL se necesitaría el iPhone
//  (queda el punto preparado: ver IntensityCalibration más abajo).
//

import Foundation
import AVFoundation
import Combine

final class AudioLevelManager: ObservableObject {

    @Published var level: Double = 0          // 0...1 normalizado
    @Published var decibels: Double = -160     // dBFS aproximado
    @Published var isVoicing: Bool = false     // hay voz por encima del umbral
    @Published var isRunning: Bool = false
    @Published var permissionDenied: Bool = false

    /// Umbral (en valor normalizado 0...1) por encima del cual se considera "voz".
    var voicingThreshold: Double = 0.10

    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()

    /// Solicita permiso de micrófono y arranca la captura.
    func start() {
        guard !isRunning else { return }
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.permissionDenied = false
                    self.beginEngine()
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }

    private func beginEngine() {
        do {
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: [])

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)

            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.process(buffer)
            }

            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
            print("AudioLevelManager error: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
        DispatchQueue.main.async {
            self.level = 0
            self.isVoicing = false
        }
    }

    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }

        // RMS de la trama.
        var sum: Float = 0
        for i in 0..<frames {
            let sample = channel[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frames))
        let db = 20 * log10(max(rms, 1e-7))            // dBFS (negativo)

        // Normalizar: -50 dBFS -> 0, 0 dBFS -> 1.
        let normalized = max(0, min(1, (Double(db) + 50.0) / 50.0))
        let voicing = normalized >= voicingThreshold

        DispatchQueue.main.async {
            self.decibels = Double(db)
            // Suavizado simple para una animación agradable.
            self.level = self.level * 0.6 + normalized * 0.4
            self.isVoicing = voicing
        }
    }
}

/// Punto preparado para una 2ª versión: calibración real de intensidad
/// usando el iPhone (WatchConnectivity + medición SPL en el teléfono).
enum IntensityCalibration {
    /// Devuelve dB SPL aproximados a partir de dBFS con un offset de calibración.
    /// El offset debería obtenerse comparando con un sonómetro / iPhone.
    static func approxSPL(fromDBFS dbfs: Double, offset: Double = 90) -> Double {
        return dbfs + offset
    }
}
