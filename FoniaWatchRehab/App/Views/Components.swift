//
//  Components.swift
//  FoniaWatch Rehab
//
//  Componentes de interfaz reutilizables, pensados para accesibilidad:
//  botones grandes, texto grande y alto contraste.
//

import SwiftUI

/// Botón grande del menú principal.
struct BigMenuButton: View {
    let module: RehabModule
    let childMode: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(childMode ? module.emoji : "")
                .font(.system(size: 26))
                .frame(width: childMode ? 34 : 0)
            if !childMode {
                Image(systemName: module.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .frame(width: 30)
            }
            Text(module.rawValue)
                .font(.system(size: 22, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
}

/// Botón clínico grande para calificar (Correcto / Error / etc.).
struct ScoreButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptic.tap()
            action()
        }) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .tint(tint)
    }
}

/// Estímulo grande y de alto contraste (palabra / sílaba / frase).
struct StimulusCard: View {
    let text: String
    var emoji: String? = nil
    var childMode: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            if childMode, let emoji = emoji {
                Text(emoji).font(.system(size: 48))
            }
            Text(text)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Fila de resultado clave-valor para el módulo de Resultados.
struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.vertical, 2)
    }
}

/// Cabecera de sección dentro de un ejercicio.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
