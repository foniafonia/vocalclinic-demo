import SwiftUI

// MARK: - SessionView

struct SessionView: View {

    @StateObject private var vm = SessionViewModel()

    var body: some View {
        VStack(spacing: 10) {
            header
            Divider()
            statusIndicator
            metricsRow
            controlButton
        }
        .padding(.horizontal, 4)
        .navigationTitle("NeuroTrack")
        .alert("Sensor no disponible", isPresented: .constant(!vm.sensorAvailable)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Device Motion no está disponible en este dispositivo.")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        Text("NeuroTrack")
            .font(.headline)
            .foregroundColor(.primary)
    }

    private var statusIndicator: some View {
        Group {
            if vm.isRunning {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isRunning)
    }

    private var metricsRow: some View {
        VStack(spacing: 4) {
            if vm.isRunning || vm.episodeCount > 0 {
                Label("\(vm.episodeCount) episodios", systemImage: "list.number")
                    .font(.caption)

                if let last = vm.lastEpisodeTime {
                    Text(last.formatted(.dateTime.hour().minute().second()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Sesión inactiva")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minHeight: 36)
    }

    private var controlButton: some View {
        Button {
            vm.toggleSession()
        } label: {
            Text(vm.isRunning ? "Detener" : "Iniciar")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(vm.isRunning ? .red : .green)
        .disabled(!vm.sensorAvailable)
    }
}

// MARK: - Preview

#Preview {
    SessionView()
}
