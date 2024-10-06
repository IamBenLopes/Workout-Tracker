import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            LogsView()
                .tabItem {
                    Label("Workout Logs", systemImage: "list.bullet")
                }
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "figure.walk")
                }
            
            MovementHistoryView()
                .tabItem {
                    Label("Movements", systemImage: "dumbbell")
                }
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
    }
}
