//
//  ContentData.swift
//  FoniaWatch Rehab
//
//  Estímulos clínicos (palabras, sílabas, frases, categorías).
//  Listas cortas, frecuentes y de uso adulto. Editables por el logopeda.
//

import Foundation

enum Stimuli {

    // MÓDULO 2 – Ritmo
    static let syllableSequences = ["pa-ta-ka", "pa-pa-pa", "ta-ka-la", "ma-na-ma", "ka-ta-pa"]
    static let shortPhrases = ["Buenos días", "Quiero agua", "Hoy hace sol", "Voy a comer", "Estoy bien"]

    // MÓDULO 3 – Afasia
    /// Denominación: palabra + emoji (el emoji ayuda en modo infantil / apoyo visual).
    static let naming: [(word: String, emoji: String)] = [
        ("CASA", "🏠"), ("PERRO", "🐶"), ("MESA", "🪑"), ("SOL", "☀️"),
        ("AGUA", "💧"), ("PAN", "🍞"), ("COCHE", "🚗"), ("FLOR", "🌸"),
        ("RELOJ", "⏰"), ("LIBRO", "📖")
    ]

    /// Comprensión auditiva: consigna "toca X" con dos opciones.
    static let comprehension: [(target: String, options: [String])] = [
        ("CASA", ["CASA", "PERRO"]),
        ("AGUA", ["PAN", "AGUA"]),
        ("SOL",  ["SOL", "LUNA"]),
        ("MESA", ["SILLA", "MESA"]),
        ("FLOR", ["FLOR", "COCHE"])
    ]

    /// Asociación semántica: objetivo + opción correcta + distractor.
    static let semantic: [(target: String, correct: String, distractor: String)] = [
        ("PERRO",   "LADRAR",   "CUCHARA"),
        ("PÁJARO",  "VOLAR",    "MARTILLO"),
        ("CUCHILLO","CORTAR",   "DORMIR"),
        ("OJO",     "VER",      "CORRER"),
        ("PAN",     "COMER",    "ESCRIBIR")
    ]

    /// Categorías de fluidez verbal.
    static let fluencyCategories = ["animales", "comidas", "ropa", "frutas", "profesiones"]

    /// Repetición: de menor a mayor longitud.
    static let repetition = ["pa", "ta", "casa", "perro", "quiero agua", "hoy hace sol"]

    // MÓDULO 4 – Lectura
    static let readingSyllables = ["pa", "me", "lo", "si", "tu", "ca", "do", "fe"]
    static let readingWords = ["CASA", "AGUA", "PERRO", "MESA", "SOL", "PAN", "FLOR", "LIBRO"]
    /// Decisión léxica: palabra real (true) / pseudopalabra (false).
    static let lexicalDecision: [(text: String, isWord: Bool)] = [
        ("CASA", true), ("TASO", false), ("PERRO", true), ("LIMUR", false),
        ("AGUA", true), ("BREDO", false), ("FLOR", true), ("CANTUR", false)
    ]

    // MÓDULO 5 – Escritura
    static let copyWords = ["CASA", "SOL", "PAN", "AGUA", "MESA"]
    static let dictationWords = ["PERRO", "FLOR", "LIBRO", "RELOJ", "COCHE"]
    /// Completar palabra: pista mostrada + palabra esperada.
    static let completion: [(hint: String, answer: String)] = [
        ("CA__", "CASA"), ("PE__O", "PERRO"), ("S_L", "SOL"), ("AG__", "AGUA")
    ]
    /// Ordenar letras: letras desordenadas + palabra correcta.
    static let scramble: [(letters: [String], answer: String)] = [
        (["A", "S", "C", "A"], "CASA"),
        (["O", "S", "L"], "SOL"),
        (["N", "P", "A"], "PAN"),
        (["A", "G", "U", "A"], "AGUA")
    ]

    // MÓDULO 6 – Movimiento (consignas verbales)
    static let motorCommands = [
        "Levanta la muñeca", "Inclina a la DERECHA", "Inclina a la IZQUIERDA",
        "Toca la pantalla", "Arriba y abajo"
    ]
}
