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
            
            MovementsTab()
                .tabItem {
                    Label("Movements", systemImage: "dumbbell")
                }
            
            WorkoutTracker.ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
    }
}
