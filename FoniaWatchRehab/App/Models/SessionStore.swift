//
//  SessionStore.swift
//  FoniaWatch Rehab
//
//  Persistencia local sencilla con UserDefaults (JSON Codable).
//  No requiere backend. Es la "única fuente de verdad" de la app.
//

import Foundation
import Combine

/// Ajustes globales de la app.
struct AppSettings: Codable {
    var childMode: Bool = false            // modo infantil con emojis
    var highContrast: Bool = true          // alto contraste (por defecto activado)
    var phonationTargetSeconds: Double = 8 // objetivo de tiempo máximo de fonación
    var metronomeBPM: Double = 60          // pulsos por minuto del metrónomo
    var sessions: Int = 0                  // nº de sesiones (aperturas de la app)
}

/// Almacén observable de toda la información clínica de la app.
final class SessionStore: ObservableObject {

    @Published var records: [ExerciseRecord] = [] { didSet { save() } }
    @Published var settings: AppSettings      { didSet { saveSettings() } }

    private let recordsKey  = "foniawatch.records.v1"
    private let settingsKey = "foniawatch.settings.v1"

    init() {
        // Cargar ajustes.
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
        // Cargar registros.
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([ExerciseRecord].self, from: data) {
            self.records = decoded
        }
    }

    // MARK: - Sesión

    /// Llamar una vez al arrancar para contabilizar la sesión.
    func startSession() {
        settings.sessions += 1
    }

    // MARK: - Registro

    func add(_ record: ExerciseRecord) {
        records.append(record)
        objectWillChange.send()
    }

    func resetAll() {
        records.removeAll()
        settings.sessions = 0
    }

    // MARK: - Persistencia

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Resúmenes (Módulo 7: Resultados)

    var totalExercises: Int { records.count }

    var totalCorrect: Int { records.reduce(0) { $0 + $1.correct } }
    var totalApprox:  Int { records.reduce(0) { $0 + $1.approx } }
    var totalErrors:  Int { records.reduce(0) { $0 + $1.errors } }

    /// Mejor tiempo de fonación registrado (segundos).
    var bestPhonation: Double {
        records.compactMap { $0.module == RehabModule.voice.rawValue ? $0.durationSeconds : nil }
            .max() ?? 0
    }

    /// Respuestas por minuto aproximadas a partir de los ejercicios de
    /// fluidez verbal / ritmo (responses dividido por su ventana temporal).
    var responsesPerMinute: Double {
        let fluency = records.filter { $0.responses != nil && ($0.durationSeconds ?? 0) > 0 }
        guard !fluency.isEmpty else { return 0 }
        let perMinute = fluency.map { Double($0.responses ?? 0) / (($0.durationSeconds ?? 1) / 60.0) }
        return perMinute.reduce(0, +) / Double(perMinute.count)
    }

    var readingErrors: Int {
        records.filter { $0.module == RehabModule.reading.rawValue }.reduce(0) { $0 + $1.errors }
    }

    var writingErrors: Int {
        records.filter { $0.module == RehabModule.writing.rawValue }.reduce(0) { $0 + $1.errors }
    }

    /// Porcentaje de aciertos global (0–100).
    var accuracyPercent: Int {
        let attempts = totalCorrect + totalApprox + totalErrors
        guard attempts > 0 else { return 0 }
        return Int((Double(totalCorrect) / Double(attempts)) * 100.0)
    }

    /// Resumen de los últimos 7 días: (día, nº de intentos).
    func last7Days() -> [(day: Date, count: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [(Date, Int)] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = records.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            result.append((day, count))
        }
        return result
    }
}
