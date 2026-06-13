//
//  RehabModels.swift
//  FoniaWatch Rehab
//
//  Modelos de datos centrales. Todo es Codable para poder persistir en
//  UserDefaults sin dependencias externas.
//

import Foundation

/// Módulos principales de la app (se corresponden con la pantalla de inicio).
enum RehabModule: String, CaseIterable, Identifiable, Codable {
    case voice      = "Voz"
    case rhythm     = "Ritmo"
    case aphasia    = "Afasia"
    case reading    = "Lectura"
    case writing    = "Escritura"
    case movement   = "Movimiento"
    case results    = "Resultados"

    var id: String { rawValue }

    /// Símbolo SF Symbols para el botón.
    var symbol: String {
        switch self {
        case .voice:    return "waveform"
        case .rhythm:   return "metronome"
        case .aphasia:  return "text.bubble"
        case .reading:  return "book"
        case .writing:  return "pencil.and.outline"
        case .movement: return "figure.walk.motion"
        case .results:  return "chart.bar"
        }
    }

    /// Emoji equivalente para el modo infantil.
    var emoji: String {
        switch self {
        case .voice:    return "🎤"
        case .rhythm:   return "🥁"
        case .aphasia:  return "💬"
        case .reading:  return "📖"
        case .writing:  return "✏️"
        case .movement: return "🤸"
        case .results:  return "⭐️"
        }
    }
}

/// Cómo califica el logopeda una respuesta. Es deliberadamente clínico y
/// NO diagnóstico: solo registra la ejecución observada.
enum Scoring: String, Codable, CaseIterable, Identifiable {
    case correct      = "Correcto"
    case approx       = "Aproximación"
    case error        = "Error"
    case noResponse   = "No responde"
    case selfCorrect  = "Autocorrección"

    var id: String { rawValue }
}

/// Tipos de error de LECTURA.
enum ReadingError: String, Codable, CaseIterable, Identifiable {
    case visual       = "Visual"
    case phonological  = "Fonológico"
    case selfCorrect  = "Autocorrección"
    case noRead       = "No lee"
    var id: String { rawValue }
}

/// Tipos de error de ESCRITURA.
enum WritingError: String, Codable, CaseIterable, Identifiable {
    case omission       = "Omisión"
    case substitution   = "Sustitución"
    case inversion      = "Inversión"
    case perseveration  = "Perseveración"
    case illegible      = "Ilegible"
    case selfCorrect    = "Autocorrección"
    var id: String { rawValue }
}

/// Registro unificado de un intento de cualquier ejercicio.
/// Se guarda uno por intento; los resúmenes se calculan a partir de ellos.
struct ExerciseRecord: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var module: String          // RehabModule.rawValue
    var exercise: String        // Nombre concreto del ejercicio

    // Métricas opcionales según el tipo de ejercicio.
    var durationSeconds: Double? = nil   // fonación / soplo / lectura cronometrada
    var responses: Int? = nil            // fluidez verbal, turnos, pulsos de ritmo
    var bestLevelDB: Double? = nil       // intensidad aproximada de voz
    var reactionMs: Double? = nil        // tiempo de respuesta (lectura)

    // Conteos de ejecución.
    var correct: Int = 0
    var approx: Int = 0
    var errors: Int = 0

    // Desglose libre de errores (p. ej. ["Omisión": 2, "Inversión": 1]).
    var errorBreakdown: [String: Int] = [:]

    var note: String = ""
}
