import SwiftUI

@main
struct NeuroTrackApp: App {

    init() {
        PhoneConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
