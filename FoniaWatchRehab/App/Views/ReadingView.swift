//
//  ReadingView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 4 — LECTURA
//  Lectura de sílabas y palabras frecuentes, decisión léxica (palabra /
//  pseudopalabra) y lectura cronometrada con registro de tipo de error y
//  tiempo de respuesta.
//

import SwiftUI

struct ReadingView: View {
    var body: some View {
        List {
            NavigationLink("Lectura de sílabas") { ReadAloudView(items: Stimuli.readingSyllables, title: "Sílabas") }
            NavigationLink("Palabras frecuentes") { ReadAloudView(items: Stimuli.readingWords, title: "Palabras") }
            NavigationLink("Decisión léxica") { LexicalDecisionView() }
        }
        .font(.system(size: 17, weight: .semibold))
        .navigationTitle("Lectura")
    }
}

/// Lectura en voz alta con cronómetro de tiempo de respuesta y marcado de
/// tipo de error.
struct ReadAloudView: View {
    let items: [String]
    let title: String

    @EnvironmentObject var store: SessionStore
    @State private var index = 0
    @State private var shownAt = Date()

    private var reactionMs: Double { Date().timeIntervalSince(shownAt) * 1000 }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionTitle(text: "Pide que lea en voz alta")
                StimulusCard(text: items[index])

                ScoreButton(title: "Correcto", systemImage: "checkmark.circle.fill", tint: .green) {
                    save(correct: true, errorType: nil); next()
                }
                ScoreButton(title: "Error visual", systemImage: "eye.trianglebadge.exclamationmark", tint: .orange) {
                    save(correct: false, errorType: .visual); next()
                }
                ScoreButton(title: "Error fonológico", systemImage: "waveform.badge.exclamationmark", tint: .red) {
                    save(correct: false, errorType: .phonological); next()
                }
                ScoreButton(title: "Autocorrección", systemImage: "arrow.uturn.backward.circle", tint: .yellow) {
                    save(correct: true, errorType: .selfCorrect); next()
                }
                ScoreButton(title: "No lee", systemImage: "minus.circle.fill", tint: .gray) {
                    save(correct: false, errorType: .noRead); next()
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle(title)
        .onAppear { shownAt = Date() }
    }

    private func save(correct: Bool, errorType: ReadingError?) {
        var breakdown: [String: Int] = [:]
        if let e = errorType, e != .selfCorrect { breakdown[e.rawValue] = 1 }
        store.add(ExerciseRecord(
            module: RehabModule.reading.rawValue,
            exercise: "Lectura \(title.lowercased())",
            reactionMs: reactionMs,
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            errorBreakdown: breakdown,
            note: "\(items[index]) · \(errorType?.rawValue ?? "OK") · \(Int(reactionMs)) ms"
        ))
    }

    private func next() {
        index = (index + 1) % items.count
        shownAt = Date()
    }
}

/// Decisión léxica: ¿es una palabra real o inventada?
struct LexicalDecisionView: View {
    @EnvironmentObject var store: SessionStore
    @State private var index = 0
    @State private var shownAt = Date()
    @State private var feedback: String?

    private var item: (text: String, isWord: Bool) { Stimuli.lexicalDecision[index] }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionTitle(text: "¿Es una palabra real?")
                StimulusCard(text: item.text)
                HStack(spacing: 8) {
                    Button("PALABRA") { answer(true) }
                        .tint(.green).font(.system(size: 18, weight: .bold))
                    Button("NO") { answer(false) }
                        .tint(.red).font(.system(size: 18, weight: .bold))
                }
                if let feedback { Text(feedback).font(.system(size: 18)) }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Decisión léxica")
        .onAppear { shownAt = Date() }
    }

    private func answer(_ said: Bool) {
        let correct = said == item.isWord
        Haptic.tap(); correct ? Haptic.success() : Haptic.warn()
        feedback = correct ? "✅ Correcto" : "❌ Revisar"
        store.add(ExerciseRecord(
            module: RehabModule.reading.rawValue,
            exercise: "Decisión léxica",
            reactionMs: Date().timeIntervalSince(shownAt) * 1000,
            correct: correct ? 1 : 0,
            errors: correct ? 0 : 1,
            note: "\(item.text) · \(correct ? "OK" : "fallo")"
        ))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            feedback = nil
            index = (index + 1) % Stimuli.lexicalDecision.count
            shownAt = Date()
        }
    }
}
