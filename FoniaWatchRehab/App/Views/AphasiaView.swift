//
//  AphasiaView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 3 — AFASIA
//  1) Denominación  2) Comprensión auditiva  3) Asociación semántica
//  4) Fluidez verbal (30 s)  5) Repetición
//
//  Estos ejercicios NO diagnostican: el logopeda observa y marca la
//  ejecución. La app solo registra.
//

import SwiftUI

struct AphasiaMenuView: View {
    var body: some View {
        List {
            NavigationLink("1 · Denominación") { NamingView() }
            NavigationLink("2 · Comprensión") { ComprehensionView() }
            NavigationLink("3 · Asociación semántica") { SemanticView() }
            NavigationLink("4 · Fluidez verbal") { FluencyView() }
            NavigationLink("5 · Repetición") { RepetitionView() }
        }
        .font(.system(size: 17, weight: .semibold))
        .navigationTitle("Afasia")
    }
}

// MARK: - Botonera de calificación común

private struct ScoringBar: View {
    let onScore: (Scoring) -> Void
    var body: some View {
        VStack(spacing: 6) {
            ScoreButton(title: "Correcto", systemImage: "checkmark.circle.fill", tint: .green) { onScore(.correct) }
            ScoreButton(title: "Aproximación", systemImage: "circle.lefthalf.filled", tint: .yellow) { onScore(.approx) }
            ScoreButton(title: "Error", systemImage: "xmark.circle.fill", tint: .red) { onScore(.error) }
            ScoreButton(title: "No responde", systemImage: "minus.circle.fill", tint: .gray) { onScore(.noResponse) }
        }
    }
}

private func record(_ exercise: String, scoring: Scoring, stimulus: String) -> ExerciseRecord {
    ExerciseRecord(
        module: RehabModule.aphasia.rawValue,
        exercise: exercise,
        correct: scoring == .correct ? 1 : 0,
        approx: scoring == .approx ? 1 : 0,
        errors: (scoring == .error || scoring == .noResponse) ? 1 : 0,
        note: "\(stimulus) · \(scoring.rawValue)"
    )
}

// MARK: - 1. Denominación

struct NamingView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0

    private var item: (word: String, emoji: String) { Stimuli.naming[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: "El paciente debe decir la palabra")
                StimulusCard(text: item.word, emoji: item.emoji, childMode: store.settings.childMode)
                ScoringBar { s in
                    store.add(record("Denominación", scoring: s, stimulus: item.word))
                    next()
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Denominación")
    }

    private func next() { index = (index + 1) % Stimuli.naming.count }
}

// MARK: - 2. Comprensión auditiva

struct ComprehensionView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0
    @State private var feedback: String?

    private var item: (target: String, options: [String]) { Stimuli.comprehension[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "Consigna")
                Text("Toca \(item.target)")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.vertical, 4)

                ForEach(item.options, id: \.self) { option in
                    Button(option) {
                        let correct = option == item.target
                        Haptic.tap()
                        if correct { Haptic.success() } else { Haptic.warn() }
                        feedback = correct ? "✅ Correcto" : "❌ Revisar"
                        store.add(ExerciseRecord(
                            module: RehabModule.aphasia.rawValue,
                            exercise: "Comprensión auditiva",
                            correct: correct ? 1 : 0,
                            errors: correct ? 0 : 1,
                            note: "Objetivo \(item.target) · eligió \(option)"
                        ))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { next() }
                    }
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .tint(.blue)
                }

                if let feedback { Text(feedback).font(.system(size: 16)) }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Comprensión")
        .onAppear { Haptic.notify() }
    }

    private func next() {
        feedback = nil
        index = (index + 1) % Stimuli.comprehension.count
        Haptic.notify()
    }
}

// MARK: - 3. Asociación semántica

struct SemanticView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0
    @State private var options: [String] = []
    @State private var feedback: String?

    private var item: (target: String, correct: String, distractor: String) { Stimuli.semantic[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "¿Qué se relaciona con…?")
                StimulusCard(text: item.target)
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        let correct = option == item.correct
                        Haptic.tap()
                        if correct { Haptic.success() } else { Haptic.warn() }
                        feedback = correct ? "✅" : "❌"
                        store.add(ExerciseRecord(
                            module: RehabModule.aphasia.rawValue,
                            exercise: "Asociación semántica",
                            correct: correct ? 1 : 0,
                            errors: correct ? 0 : 1,
                            note: "\(item.target) → \(option)"
                        ))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { next() }
                    }
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .tint(.blue)
                }
                if let feedback { Text(feedback).font(.system(size: 20)) }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Asociación")
        .onAppear { shuffle() }
    }

    private func shuffle() {
        options = [item.correct, item.distractor].shuffled()
        feedback = nil
    }
    private func next() {
        index = (index + 1) % Stimuli.semantic.count
        shuffle()
    }
}

// MARK: - 4. Fluidez verbal (30 s)

struct FluencyView: View {
    @EnvironmentObject var store: SessionStore
    @State private var category = Stimuli.fluencyCategories[0]
    @State private var running = false
    @State private var remaining = 30
    @State private var count = 0
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: "Categoría")
                Text(category)
                    .font(.system(size: 30, weight: .heavy))
                Text("\(remaining) s")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(remaining <= 5 ? .red : .primary)
                Text("\(count) respuestas")
                    .font(.system(size: 18, weight: .semibold))

                Button("＋  Respuesta válida") {
                    guard running else { return }
                    Haptic.tap(); count += 1
                }
                .tint(.green)
                .font(.system(size: 20, weight: .bold))
                .disabled(!running)

                Button(running ? "Detener" : "Iniciar 30 s") {
                    running ? stop() : start()
                }
                .tint(running ? .red : .blue)
                .font(.system(size: 18, weight: .bold))

                Button("Otra categoría") {
                    category = Stimuli.fluencyCategories.randomElement() ?? category
                }
                .font(.system(size: 15))
                .disabled(running)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Fluidez")
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        count = 0; remaining = 30; running = true; Haptic.beat()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remaining -= 1
            if remaining <= 0 { stop() }
        }
    }

    private func stop() {
        timer?.invalidate(); timer = nil; running = false
        store.add(ExerciseRecord(
            module: RehabModule.aphasia.rawValue,
            exercise: "Fluidez verbal",
            durationSeconds: 30,
            responses: count,
            correct: count,
            note: "Categoría \(category)"
        ))
        Haptic.notify()
    }
}

// MARK: - 5. Repetición

struct RepetitionView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0

    private var stimulus: String { Stimuli.repetition[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "Pide que repita")
                StimulusCard(text: stimulus)
                ScoreButton(title: "Correcto", systemImage: "checkmark.circle.fill", tint: .green) {
                    store.add(record("Repetición", scoring: .correct, stimulus: stimulus)); next()
                }
                ScoreButton(title: "Aproximación", systemImage: "circle.lefthalf.filled", tint: .yellow) {
                    store.add(record("Repetición", scoring: .approx, stimulus: stimulus)); next()
                }
                ScoreButton(title: "Error", systemImage: "xmark.circle.fill", tint: .red) {
                    store.add(record("Repetición", scoring: .error, stimulus: stimulus)); next()
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Repetición")
    }

    private func next() { index = (index + 1) % Stimuli.repetition.count }
}
