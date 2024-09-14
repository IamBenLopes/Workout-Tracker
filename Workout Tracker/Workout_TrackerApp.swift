//
//  Workout_TrackerApp.swift
//  Workout Tracker
//
//  Created by Benjamin Lopes on 9/14/24.
//

import SwiftUI

@main
struct Workout_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
