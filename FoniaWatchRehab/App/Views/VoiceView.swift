//
//  VoiceView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 1 — VOZ
//  Tiempo máximo de fonación, intensidad aproximada, estabilidad vocal,
//  repetición de /a/ y soplo sostenido. Biofeedback con círculo que crece
//  según el nivel de micrófono, háptica al superar el objetivo y aviso al
//  detenerse.
//

import SwiftUI

struct VoiceView: View {

    enum VoiceExercise: String, CaseIterable, Identifiable {
        case maxPhonation = "Tiempo máx. fonación"
        case vowelA       = "Repetir vocal /a/"
        case blow         = "Soplo sostenido"
        var id: String { rawValue }

        var instruction: String {
            switch self {
            case .maxPhonation: return "Di «aaaa» todo lo que puedas sin parar."
            case .vowelA:       return "Repite la vocal /a/ de forma sostenida."
            case .blow:         return "Sopla de forma continua frente al reloj."
            }
        }
    }

    var body: some View {
        List(VoiceExercise.allCases) { ex in
            NavigationLink {
                PhonationExerciseView(exercise: ex)
            } label: {
                Text(ex.rawValue).font(.system(size: 18, weight: .semibold))
                    .padding(.vertical, 6)
            }
        }
        .navigationTitle("Voz")
    }
}

struct PhonationExerciseView: View {
    let exercise: VoiceView.VoiceExercise

    @EnvironmentObject var store: SessionStore
    @StateObject private var audio = AudioLevelManager()

    @State private var isMeasuring = false
    @State private var elapsed: Double = 0
    @State private var bestDB: Double = -160
    @State private var levelSamples: [Double] = []   // para estabilidad
    @State private var reachedTarget = false
    @State private var silenceTime: Double = 0
    @State private var timer: Timer?

    private var target: Double { store.settings.phonationTargetSeconds }

    /// Estabilidad: 100 - (desviación estándar normalizada). Cuanto más
    /// constante el nivel, mayor estabilidad.
    private var stability: Int {
        guard levelSamples.count > 3 else { return 0 }
        let mean = levelSamples.reduce(0, +) / Double(levelSamples.count)
        let variance = levelSamples.reduce(0) { $0 + pow($1 - mean, 2) } / Double(levelSamples.count)
        let sd = sqrt(variance)
        return max(0, min(100, Int((1 - sd * 2) * 100)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(exercise.instruction)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Círculo que crece con la voz.
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(reachedTarget ? Color.green : (audio.isVoicing ? Color.blue : Color.orange))
                        .frame(width: 40 + CGFloat(audio.level) * 90,
                               height: 40 + CGFloat(audio.level) * 90)
                        .animation(.easeOut(duration: 0.1), value: audio.level)
                    Text(String(format: "%.1f s", elapsed))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(height: 140)

                if audio.permissionDenied {
                    Text("Activa el permiso de micrófono en Ajustes para medir la voz.")
                        .font(.system(size: 13)).foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    StatRow(label: "Objetivo", value: "\(Int(target)) s")
                }
                StatRow(label: "Intensidad", value: String(format: "%.0f dBFS", audio.decibels))
                StatRow(label: "Estabilidad", value: "\(stability)%")

                Button(isMeasuring ? "Detener y guardar" : "Iniciar") {
                    isMeasuring ? finish() : begin()
                }
                .tint(isMeasuring ? .red : .green)
                .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Voz")
        .onDisappear { cleanUp() }
    }

    private func begin() {
        elapsed = 0; bestDB = -160; levelSamples = []; reachedTarget = false; silenceTime = 0
        audio.start()
        isMeasuring = true
        Haptic.beat()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in tick() }
    }

    private func tick() {
        if audio.isVoicing {
            elapsed += 0.1
            silenceTime = 0
            levelSamples.append(audio.level)
            if audio.decibels > bestDB { bestDB = audio.decibels }
            if !reachedTarget && elapsed >= target {
                reachedTarget = true
                Haptic.success()   // vibración suave al superar el objetivo
            }
        } else if isMeasuring {
            // Aviso si se detiene la voz durante el ejercicio.
            silenceTime += 0.1
            if silenceTime >= 1.0 && elapsed > 0.5 {
                Haptic.warn()
                silenceTime = 0
            }
        }
    }

    private func finish() {
        timer?.invalidate(); timer = nil
        audio.stop()
        isMeasuring = false

        let record = ExerciseRecord(
            module: RehabModule.voice.rawValue,
            exercise: exercise.rawValue,
            durationSeconds: elapsed,
            bestLevelDB: bestDB,
            correct: reachedTarget ? 1 : 0,
            errors: reachedTarget ? 0 : 0,
            note: "Estabilidad \(stability)%"
        )
        store.add(record)
        Haptic.notify()
    }

    private func cleanUp() {
        timer?.invalidate(); timer = nil
        audio.stop()
    }
}
