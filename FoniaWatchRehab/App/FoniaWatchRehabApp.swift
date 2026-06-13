//
//  FoniaWatchRehabApp.swift
//  FoniaWatch Rehab
//
//  Punto de entrada de la app de watchOS.
//

import SwiftUI

@main
struct FoniaWatchRehab_Watch_AppApp: App {

    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { store.startSession() }
        }
    }
}
