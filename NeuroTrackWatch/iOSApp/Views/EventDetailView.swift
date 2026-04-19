import SwiftUI

// MARK: - EventDetailView

/// Allows therapist or caregiver to review a detected episode,
/// validate it (confirmed / false positive), and add a short note.
struct EventDetailView: View {

    @State private var event: DetectedEvent
    @State private var notesDraft: String
    @ObservedObject private var store = EventStore.shared

    init(event: DetectedEvent) {
        _event      = State(initialValue: event)
        _notesDraft = State(initialValue: event.notes ?? "")
    }

    var body: some View {
        Form {
            timingSection
            signalSection
            validationSection
            notesSection
        }
        .navigationTitle("Episodio")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var timingSection: some View {
        Section("Tiempo") {
            LabeledContent("Inicio",    value: event.startTime.formatted(.dateTime))
            LabeledContent("Fin",       value: event.endTime.formatted(.dateTime))
            LabeledContent("Duración",  value: String(format: "%.1f s", event.duration))
        }
    }

    private var signalSection: some View {
        Section("Señal detectada") {
            LabeledContent(
                "Intensidad (RMS)",
                value: String(format: "%.3f g", event.intensityRMS)
            )
            LabeledContent(
                "Ritmicidad",
                value: String(format: "%.2f  (\(rhythmicityLabel))", event.rhythmicityScore)
            )
            LabeledContent(
                "Frecuencia dominante",
                value: String(format: "%.1f Hz", event.dominantFrequencyHz)
            )
            LabeledContent("Ventanas analizadas", value: "\(event.windowCount)")

            // Non-clinical disclaimer inline
            Text("Valores extraídos del acelerómetro del Watch. No constituyen valoración clínica.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var validationSection: some View {
        Section("Validación manual") {
            Picker("Estado", selection: validationBinding) {
                ForEach(EventValidationStatus.allCases, id: \.self) { status in
                    Text(status.label).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Notas") {
            TextEditor(text: $notesDraft)
                .frame(minHeight: 80)
                .onChange(of: notesDraft) { _, newValue in
                    event.notes = newValue.isEmpty ? nil : newValue
                    store.update(event)
                }
        }
    }

    // MARK: - Helpers

    private var rhythmicityLabel: String {
        switch event.rhythmicityScore {
        case ..<0.2:  return "baja"
        case ..<0.45: return "moderada"
        default:      return "alta"
        }
    }

    private var validationBinding: Binding<EventValidationStatus> {
        Binding(
            get: { event.validationStatus },
            set: { newStatus in
                event.validationStatus = newStatus
                store.update(event)
            }
        )
    }
}
