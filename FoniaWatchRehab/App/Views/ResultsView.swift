//
//  ResultsView.swift
//  FoniaWatch Rehab
//
//  MÓDULO 7 — RESULTADOS
//  Resumen simple de la ejecución y evolución de los últimos días.
//  Permite reiniciar todos los datos.
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var store: SessionStore
    @State private var showResetConfirm = false

    var body: some View {
        List {
            Section("Resumen") {
                StatRow(label: "Sesiones", value: "\(store.settings.sessions)")
                StatRow(label: "Ejercicios", value: "\(store.totalExercises)")
                StatRow(label: "Aciertos", value: "\(store.totalCorrect)")
                StatRow(label: "Aproximaciones", value: "\(store.totalApprox)")
                StatRow(label: "Errores", value: "\(store.totalErrors)")
                StatRow(label: "% Aciertos", value: "\(store.accuracyPercent)%")
            }

            Section("Detalle") {
                StatRow(label: "Mejor fonación", value: String(format: "%.1f s", store.bestPhonation))
                StatRow(label: "Resp./min", value: String(format: "%.0f", store.responsesPerMinute))
                StatRow(label: "Errores lectura", value: "\(store.readingErrors)")
                StatRow(label: "Errores escritura", value: "\(store.writingErrors)")
            }

            Section("Últimos 7 días") {
                EvolutionChart(data: store.last7Days())
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reiniciar datos", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Resultados")
        .confirmationDialog("¿Borrar todos los datos?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Borrar todo", role: .destructive) { store.resetAll(); Haptic.stop() }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

/// Mini gráfico de barras de evolución (sin dependencias externas).
struct EvolutionChart: View {
    let data: [(day: Date, count: Int)]

    private var maxCount: Int { max(1, data.map { $0.count }.max() ?? 1) }
    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; f.locale = Locale(identifier: "es_ES"); return f
    }()

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(data.enumerated()), id: \.offset) { pair in
                VStack(spacing: 2) {
                    Text("\(pair.element.count)")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(height: CGFloat(pair.element.count) / CGFloat(maxCount) * 50 + 2)
                    Text(fmt.string(from: pair.element.day).prefix(1).uppercased())
                        .font(.system(size: 10))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
        .padding(.vertical, 4)
    }
}
