import SwiftUI

// MARK: - EventListView

struct EventListView: View {

    @ObservedObject private var store = EventStore.shared
    @State private var selectedDate   = Date()
    @State private var showExport     = false
    @State private var exportPayload  = ""

    private var dayEvents: [DetectedEvent] {
        store.events(for: selectedDate)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                datePicker
                Divider()
                eventContent
            }
            .navigationTitle("Eventos")
            .toolbar { exportButton }
            .sheet(isPresented: $showExport) {
                ExportSheet(content: exportPayload)
            }
        }
    }

    // MARK: - Subviews

    private var datePicker: some View {
        DatePicker(
            "Fecha",
            selection: $selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var eventContent: some View {
        if dayEvents.isEmpty {
            ContentUnavailableView(
                "Sin episodios",
                systemImage: "waveform.slash",
                description: Text("No se registraron episodios este día.")
            )
        } else {
            List(dayEvents) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    EventRowView(event: event)
                }
            }
            .listStyle(.plain)
        }
    }

    private var exportButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Exportar JSON") { prepareExport(format: .json) }
                Button("Exportar CSV")  { prepareExport(format: .csv)  }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Export

    private enum ExportFormat { case json, csv }

    private func prepareExport(format: ExportFormat) {
        switch format {
        case .json:
            exportPayload = String(
                data: store.exportJSON(for: selectedDate) ?? Data(),
                encoding: .utf8
            ) ?? ""
        case .csv:
            exportPayload = store.exportCSV(for: selectedDate)
        }
        showExport = true
    }
}

// MARK: - EventRowView

struct EventRowView: View {

    let event: DetectedEvent

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            statusBadge
            VStack(alignment: .leading, spacing: 3) {
                Text(event.startTime.formatted(.dateTime.hour().minute().second()))
                    .font(.body.monospacedDigit())

                HStack(spacing: 10) {
                    metricLabel(
                        icon: "timer",
                        value: String(format: "%.1f s", event.duration)
                    )
                    metricLabel(
                        icon: "waveform",
                        value: String(format: "%.2f g", event.intensityRMS)
                    )
                    metricLabel(
                        icon: "metronome",
                        value: String(format: "%.1f Hz", event.dominantFrequencyHz)
                    )
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusBadge: some View {
        Group {
            switch event.validationStatus {
            case .pending:
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.orange)
            case .validated:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .falsePositive:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.title3)
    }

    private func metricLabel(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// MARK: - ExportSheet

private struct ExportSheet: View {
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Exportar datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: content) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
