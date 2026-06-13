//
//  ContentView.swift
//  FoniaWatch Rehab
//
//  Pantalla principal: lista de módulos con botones grandes + ajustes.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(RehabModule.allCases) { module in
                    NavigationLink(value: module) {
                        BigMenuButton(module: module, childMode: store.settings.childMode)
                    }
                }
                NavigationLink {
                    SettingsView()
                } label: {
                    HStack {
                        Image(systemName: "gearshape").font(.system(size: 20, weight: .bold)).frame(width: 30)
                        Text("Ajustes").font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("FoniaWatch")
            .navigationDestination(for: RehabModule.self) { module in
                destination(for: module)
            }
        }
    }

    @ViewBuilder
    private func destination(for module: RehabModule) -> some View {
        switch module {
        case .voice:    VoiceView()
        case .rhythm:   RhythmView()
        case .aphasia:  AphasiaMenuView()
        case .reading:  ReadingView()
        case .writing:  WritingView()
        case .movement: MovementView()
        case .results:  ResultsView()
        }
    }
}

#Preview {
    ContentView().environmentObject(SessionStore())
}
