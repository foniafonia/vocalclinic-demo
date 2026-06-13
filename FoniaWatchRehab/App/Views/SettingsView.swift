//
//  SettingsView.swift
//  FoniaWatch Rehab
//
//  Ajustes: modo infantil, objetivos de ejercicio, metrónomo.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        List {
            Section("Accesibilidad") {
                Toggle(isOn: $store.settings.childMode) {
                    Text("Modo infantil (emojis)").font(.system(size: 16))
                }
                Toggle(isOn: $store.settings.highContrast) {
                    Text("Alto contraste").font(.system(size: 16))
                }
            }

            Section("Voz") {
                VStack(alignment: .leading) {
                    Text("Objetivo fonación: \(Int(store.settings.phonationTargetSeconds)) s")
                        .font(.system(size: 15))
                    Slider(value: $store.settings.phonationTargetSeconds, in: 3...30, step: 1)
                }
            }

            Section("Ritmo") {
                VStack(alignment: .leading) {
                    Text("Metrónomo: \(Int(store.settings.metronomeBPM)) ppm")
                        .font(.system(size: 15))
                    Slider(value: $store.settings.metronomeBPM, in: 30...120, step: 5)
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}
