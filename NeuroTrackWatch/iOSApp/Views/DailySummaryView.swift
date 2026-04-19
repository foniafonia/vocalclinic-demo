import SwiftUI
import Charts

// MARK: - DailySummaryView

struct DailySummaryView: View {

    @ObservedObject private var store = EventStore.shared
    @State private var selectedDate   = Date()

    /// Only non-false-positive events count towards metrics
    private var confirmedEvents: [DetectedEvent] {
        store.events(for: selectedDate)
            .filter { $0.validationStatus != .falsePositive }
    }

    private var allDayEvents: [DetectedEvent] {
        store.events(for: selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    datePicker
                    SummaryCardsView(events: confirmedEvents)

                    if confirmedEvents.isEmpty {
                        emptyState
                    } else {
                        HourlyDistributionChart(events: confirmedEvents)
                            .padding(.horizontal)

                        IntensityTimelineChart(events: confirmedEvents)
                            .padding(.horizontal)

                        ValidationBreakdownView(events: allDayEvents)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Resumen")
        }
    }

    // MARK: - Subviews

    private var datePicker: some View {
        DatePicker("Fecha", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.compact)
            .padding(.horizontal)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Sin datos",
            systemImage: "chart.bar.xaxis",
            description: Text("No hay episodios confirmados para este día.")
        )
        .padding(.top, 40)
    }
}

// MARK: - SummaryCardsView

struct SummaryCardsView: View {

    let events: [DetectedEvent]

    private var totalDuration: Double     { events.map(\.duration).reduce(0, +) }
    private var meanIntensity: Double     { events.isEmpty ? 0 : events.map(\.intensityRMS).mean() }
    private var validatedCount: Int       { events.filter { $0.validationStatus == .validated }.count }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            MetricCard(title: "Episodios",       value: "\(events.count)",                       icon: "waveform.path.ecg")
            MetricCard(title: "Duración total",   value: String(format: "%.0f s", totalDuration), icon: "timer")
            MetricCard(title: "Intens. media",    value: String(format: "%.2f g", meanIntensity), icon: "bolt.fill")
            MetricCard(title: "Validados",        value: "\(validatedCount)",                     icon: "checkmark.seal.fill")
        }
        .padding(.horizontal)
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let title: String
    let value: String
    let icon:  String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - HourlyDistributionChart

struct HourlyDistributionChart: View {

    let events: [DetectedEvent]

    private var buckets: [HourBucket] {
        var counts = [Int: Int]()
        for e in events {
            let h = Calendar.current.component(.hour, from: e.startTime)
            counts[h, default: 0] += 1
        }
        return (0 ..< 24).map { HourBucket(hour: $0, count: counts[$0, default: 0]) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Episodios por hora")
                .font(.headline)

            Chart(buckets) { b in
                BarMark(
                    x: .value("Hora",      b.hour),
                    y: .value("Episodios", b.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { v in
                    AxisValueLabel { Text("\(v.as(Int.self) ?? 0)h") }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { v in
                    AxisValueLabel { Text("\(v.as(Int.self) ?? 0)") }
                    AxisGridLine()
                }
            }
        }
    }
}

// MARK: - IntensityTimelineChart

struct IntensityTimelineChart: View {

    let events: [DetectedEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensidad (RMS) por episodio")
                .font(.headline)

            Chart(events) { e in
                PointMark(
                    x: .value("Tiempo",     e.startTime),
                    y: .value("Intensidad", e.intensityRMS)
                )
                .symbolSize(40)
                .foregroundStyle(color(for: e).opacity(0.8))
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                    AxisValueLabel(format: .dateTime.hour())
                    AxisGridLine()
                }
            }
        }
    }

    private func color(for event: DetectedEvent) -> Color {
        switch event.validationStatus {
        case .pending:       return .orange
        case .validated:     return .green
        case .falsePositive: return .red
        }
    }
}

// MARK: - ValidationBreakdownView

struct ValidationBreakdownView: View {

    let events: [DetectedEvent]

    private var pendingCount:       Int { events.filter { $0.validationStatus == .pending }.count }
    private var validatedCount:     Int { events.filter { $0.validationStatus == .validated }.count }
    private var falsePositiveCount: Int { events.filter { $0.validationStatus == .falsePositive }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estado de validación")
                .font(.headline)

            HStack(spacing: 16) {
                statusPill(label: "Pendientes",  count: pendingCount,       color: .orange)
                statusPill(label: "Validados",   count: validatedCount,     color: .green)
                statusPill(label: "F. positivos", count: falsePositiveCount, color: .red)
            }
        }
    }

    private func statusPill(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting types

struct HourBucket: Identifiable {
    let id   = UUID()
    let hour:  Int
    let count: Int
}

private extension Array where Element == Double {
    func mean() -> Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}
