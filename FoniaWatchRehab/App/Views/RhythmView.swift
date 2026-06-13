//
//  RhythmView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 2 — RITMO Y FLUIDEZ
//  Metrónomo visual + háptico. Repetición de sílabas (pa-ta-ka), frases
//  cortas a ritmo lento, control de pausas y turnos de respuesta.
//

import SwiftUI

struct RhythmView: View {
    @EnvironmentObject var store: SessionStore

    @State private var stimulus = Stimuli.syllableSequences[0]
    @State private var isRunning = false
    @State private var beatOn = false
    @State private var beatCount = 0
    @State private var responses = 0
    @State private var startDate: Date?
    @State private var timer: Timer?
    @State private var usePhrases = false

    private var interval: Double { 60.0 / store.settings.metronomeBPM }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Button(usePhrases ? "Modo: Frases" : "Modo: Sílabas") {
                    usePhrases.toggle()
                    nextStimulus()
                }
                .font(.system(size: 15, weight: .semibold))
                .tint(.purple)
                .disabled(isRunning)

                StimulusCard(text: stimulus)

                // Punto del metrónomo.
                Circle()
                    .fill(beatOn ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(beatOn ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.08), value: beatOn)

                StatRow(label: "Tempo", value: "\(Int(store.settings.metronomeBPM)) ppm")
                StatRow(label: "Pulsos", value: "\(beatCount)")
                StatRow(label: "Respuestas", value: "\(responses)")

                Button("＋ Respuesta válida") {
                    Haptic.tap(); responses += 1
                }
                .tint(.blue)
                .font(.system(size: 17, weight: .semibold))
                .disabled(!isRunning)

                Button(isRunning ? "Detener y guardar" : "Iniciar metrónomo") {
                    isRunning ? stop() : start()
                }
                .tint(isRunning ? .red : .green)
                .font(.system(size: 18, weight: .bold))

                Button("Otro estímulo") { nextStimulus() }
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Ritmo")
        .onDisappear { timer?.invalidate() }
    }

    private func nextStimulus() {
        stimulus = usePhrases
            ? (Stimuli.shortPhrases.randomElement() ?? "")
            : (Stimuli.syllableSequences.randomElement() ?? "")
    }

    private func start() {
        beatCount = 0; responses = 0; startDate = Date(); isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            beatCount += 1
            Haptic.beat()
            beatOn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { beatOn = false }
        }
    }

    private func stop() {
        timer?.invalidate(); timer = nil; isRunning = false
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        let record = ExerciseRecord(
            module: RehabModule.rhythm.rawValue,
            exercise: usePhrases ? "Frases a ritmo" : "Sílabas con metrónomo",
            durationSeconds: duration,
            responses: responses,
            correct: responses,
            note: "\(Int(store.settings.metronomeBPM)) ppm, \(beatCount) pulsos"
        )
        store.add(record)
        Haptic.notify()
    }
}
