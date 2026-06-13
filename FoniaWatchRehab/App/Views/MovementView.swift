//
//  MovementView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 6 — MOVIMIENTO Y SECUENCIACIÓN
//  Usa el device motion (acelerómetro/giroscopio) para responder con la
//  muñeca: inclinar izquierda/derecha para elegir, levantar la muñeca y
//  secuencias de gestos. Aplicación clínica: apraxia, planificación motora,
//  atención, respuesta a órdenes y secuenciación.
//

import SwiftUI

struct MovementView: View {
    var body: some View {
        List {
            NavigationLink("Elegir con inclinación") { TiltChoiceView() }
            NavigationLink("Secuencia de gestos") { GestureSequenceView() }
            NavigationLink("Respuesta a consigna") { CommandResponseView() }
        }
        .font(.system(size: 17, weight: .semibold))
        .navigationTitle("Movimiento")
    }
}

/// Inclinar a izquierda o derecha para elegir entre dos opciones.
struct TiltChoiceView: View {
    @EnvironmentObject var store: SessionStore
    @StateObject private var motion = MotionManager()
    @State private var trials = 0
    @State private var hits = 0
    @State private var target: Tilt = .right
    @State private var locked = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !motion.isAvailable {
                    Text("Sensores de movimiento no disponibles.")
                        .font(.system(size: 14)).foregroundStyle(.red)
                }
                SectionTitle(text: "Consigna")
                Text("Inclina a la \(target.rawValue.uppercased())")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)

                HStack(spacing: 30) {
                    Image(systemName: "arrow.left").font(.system(size: 30))
                        .foregroundStyle(motion.tilt == .left ? .green : .gray)
                    Image(systemName: "arrow.right").font(.system(size: 30))
                        .foregroundStyle(motion.tilt == .right ? .green : .gray)
                }

                StatRow(label: "Aciertos", value: "\(hits)/\(trials)")
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Inclinación")
        .onAppear { motion.start(); newTarget() }
        .onDisappear { saveAndStop() }
        .onChange(of: motion.tilt) { _, newValue in evaluate(newValue) }
    }

    private func newTarget() { target = Bool.random() ? .left : .right; locked = false }

    private func evaluate(_ tilt: Tilt) {
        guard !locked, tilt == .left || tilt == .right else { return }
        locked = true
        trials += 1
        if tilt == target { hits += 1; Haptic.success() } else { Haptic.warn() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { newTarget() }
    }

    private func saveAndStop() {
        motion.stop()
        guard trials > 0 else { return }
        store.add(ExerciseRecord(
            module: RehabModule.movement.rawValue,
            exercise: "Elegir con inclinación",
            responses: trials,
            correct: hits,
            errors: trials - hits,
            note: "\(hits)/\(trials) aciertos"
        ))
    }
}

/// Secuencia de gestos: arriba, abajo, tocar. Atención y secuenciación.
struct GestureSequenceView: View {
    @EnvironmentObject var store: SessionStore
    @StateObject private var motion = MotionManager()

    private let sequence: [Tilt] = [.up, .down, .center]
    @State private var step = 0
    @State private var completed = 0
    @State private var locked = false

    private let labels: [Tilt: String] = [.up: "ARRIBA ⬆️", .down: "ABAJO ⬇️", .center: "TOCAR 👆"]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "Sigue la secuencia")
                Text(labels[sequence[step]] ?? "")
                    .font(.system(size: 26, weight: .bold))

                if sequence[step] == .center {
                    Button("TOCAR") { advance() }
                        .font(.system(size: 22, weight: .bold)).tint(.green)
                }

                Text("Paso \(step + 1)/\(sequence.count)")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
                StatRow(label: "Secuencias", value: "\(completed)")
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Secuencia")
        .onAppear { motion.start() }
        .onDisappear { saveAndStop() }
        .onChange(of: motion.tilt) { _, newValue in
            guard sequence[step] != .center else { return }
            if newValue == sequence[step] { advance() }
        }
    }

    private func advance() {
        guard !locked else { return }
        locked = true
        Haptic.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if step == sequence.count - 1 {
                completed += 1; step = 0; Haptic.notify()
            } else {
                step += 1
            }
            locked = false
        }
    }

    private func saveAndStop() {
        motion.stop()
        guard completed > 0 else { return }
        store.add(ExerciseRecord(
            module: RehabModule.movement.rawValue,
            exercise: "Secuencia de gestos",
            responses: completed,
            correct: completed,
            note: "\(completed) secuencias completas"
        ))
    }
}

/// Respuesta motora tras consigna verbal (la lee el logopeda).
struct CommandResponseView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "Da la orden en voz alta")
                StimulusCard(text: Stimuli.motorCommands[index])
                ScoreButton(title: "Responde bien", systemImage: "checkmark.circle.fill", tint: .green) {
                    save(true); next()
                }
                ScoreButton(title: "Tarda / dudoso", systemImage: "circle.lefthalf.filled", tint: .yellow) {
                    save(true); next()
                }
                ScoreButton(title: "No responde", systemImage: "xmark.circle.fill", tint: .red) {
                    save(false); next()
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Consigna")
    }

    private func save(_ correct: Bool) {
        store.add(ExerciseRecord(
            module: RehabModule.movement.rawValue,
            exercise: "Respuesta a consigna",
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            note: Stimuli.motorCommands[index]
        ))
    }

    private func next() { index = (index + 1) % Stimuli.motorCommands.count }
}
