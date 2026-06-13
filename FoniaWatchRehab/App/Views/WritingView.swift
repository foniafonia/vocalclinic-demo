//
//  WritingView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 5 — ESCRITURA
//  El reloj se usa como dispositivo de REGISTRO (no de escritura).
//  Tareas: copia, dictado, completar palabra y ordenar letras.
//  El logopeda marca el tipo de error observado en el papel del paciente.
//

import SwiftUI

struct WritingView: View {
    var body: some View {
        List {
            NavigationLink("Copia") { WritingTaskView(title: "Copia", items: Stimuli.copyWords) }
            NavigationLink("Dictado") { WritingTaskView(title: "Dictado", items: Stimuli.dictationWords) }
            NavigationLink("Completar palabra") { CompletionView() }
            NavigationLink("Ordenar letras") { ScrambleView() }
        }
        .font(.system(size: 17, weight: .semibold))
        .navigationTitle("Escritura")
    }
}

/// Copia / dictado: muestra el estímulo y registra el resultado.
struct WritingTaskView: View {
    let title: String
    let items: [String]

    @EnvironmentObject var store: SessionStore
    @State private var index = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: title == "Dictado"
                             ? "Dicta la palabra (no la muestres)"
                             : "El paciente copia la palabra")
                StimulusCard(text: items[index])

                ScoreButton(title: "Correcto", systemImage: "checkmark.circle.fill", tint: .green) {
                    save(correct: true, error: nil); next()
                }
                ScoreButton(title: "Autocorrección", systemImage: "arrow.uturn.backward.circle", tint: .yellow) {
                    save(correct: true, error: .selfCorrect); next()
                }
                ForEach(WritingError.allCases.filter { $0 != .selfCorrect }) { e in
                    ScoreButton(title: e.rawValue, systemImage: "xmark.circle.fill", tint: .red) {
                        save(correct: false, error: e); next()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle(title)
    }

    private func save(correct: Bool, error: WritingError?) {
        var breakdown: [String: Int] = [:]
        if let e = error, e != .selfCorrect { breakdown[e.rawValue] = 1 }
        store.add(ExerciseRecord(
            module: RehabModule.writing.rawValue,
            exercise: title,
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            errorBreakdown: breakdown,
            note: "\(items[index]) · \(error?.rawValue ?? "OK")"
        ))
    }

    private func next() { index = (index + 1) % items.count }
}

/// Completar palabra: muestra la pista, el paciente la completa por escrito.
struct CompletionView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0

    private var item: (hint: String, answer: String) { Stimuli.completion[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: "Completa la palabra")
                StimulusCard(text: item.hint)
                Text("(\(item.answer))").font(.system(size: 14)).foregroundStyle(.secondary)

                ScoreButton(title: "Correcto", systemImage: "checkmark.circle.fill", tint: .green) {
                    save(correct: true); next()
                }
                ScoreButton(title: "Error", systemImage: "xmark.circle.fill", tint: .red) {
                    save(correct: false); next()
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Completar")
    }

    private func save(correct: Bool) {
        store.add(ExerciseRecord(
            module: RehabModule.writing.rawValue,
            exercise: "Completar palabra",
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            note: "\(item.answer) · \(correct ? "OK" : "fallo")"
        ))
    }

    private func next() { index = (index + 1) % Stimuli.completion.count }
}

/// Ordenar letras en pantalla para formar la palabra.
struct ScrambleView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0
    @State private var letters: [String] = []
    @State private var built: [String] = []

    private var item: (letters: [String], answer: String) { Stimuli.scramble[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: "Toca las letras en orden")
                Text(built.joined())
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { pair in
                        Button(pair.element) {
                            Haptic.tap()
                            built.append(pair.element)
                            checkComplete()
                        }
                        .font(.system(size: 24, weight: .bold))
                        .tint(.blue)
                    }
                }

                Button("Borrar") { built.removeAll(); Haptic.tap() }
                    .font(.system(size: 15)).tint(.gray)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Ordenar")
        .onAppear { setup() }
    }

    private func setup() {
        letters = item.letters.shuffled()
        built = []
    }

    private func checkComplete() {
        guard built.count == item.letters.count else { return }
        let correct = built.joined() == item.answer
        correct ? Haptic.success() : Haptic.warn()
        store.add(ExerciseRecord(
            module: RehabModule.writing.rawValue,
            exercise: "Ordenar letras",
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            note: "\(item.answer) · \(built.joined())"
        ))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            index = (index + 1) % Stimuli.scramble.count
            setup()
        }
    }
}
