import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            EventListView()
                .tabItem {
                    Label("Eventos", systemImage: "list.bullet.clipboard.fill")
                }

            DailySummaryView()
                .tabItem {
                    Label("Resumen", systemImage: "chart.bar.fill")
                }
        }
    }
}
