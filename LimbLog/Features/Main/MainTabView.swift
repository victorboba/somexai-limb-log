import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "ruler") }
            HistoryView()
                .tabItem { Label("History", systemImage: "chart.xyaxis.line") }
            ReportView()
                .tabItem { Label("Report", systemImage: "doc.text") }
        }
    }
}
