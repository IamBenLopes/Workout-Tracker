import SwiftUI
import CoreData

@main
struct WorkoutTrackerApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        print("WorkoutTrackerApp initializing")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    print("ContentView appeared")
                    // Add some debug prints here
                    print("ManagedObjectContext: \(persistenceController.container.viewContext)")
                }
        }
    }
}
