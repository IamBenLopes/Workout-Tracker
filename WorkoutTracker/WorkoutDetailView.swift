import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout
    @State private var isEditing = false
    @State private var showingMovementEntryView = false

    var body: some View {
        List {
            workoutDetailsSection
            movementLogsSection
        }
        .navigationBarTitle(workout.displayName, displayMode: .inline)
        .navigationBarItems(trailing: Button("Edit") {
            isEditing = true
        })
        .sheet(isPresented: $isEditing) {
            NavigationView {
                WorkoutEditView(workout: workout)
            }
        }
        .sheet(isPresented: $showingMovementEntryView) {
            MovementEntryView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var workoutDetailsSection: some View {
        Section(header: Text("Workout Details")) {
            Text("Date: \(formattedDate)")
            Text("Pre-Workout Pain Level: \(workout.prePainLevel)")
            Text("Post-Workout Pain Level: \(workout.postPainLevel)")
            Text("Workout Focus: \(workout.workoutFocus ?? "Not set")")
            if let postNotes = workout.postNotes, !postNotes.isEmpty {
                Text("Post-Workout Notes: \(postNotes)")
            }
        }
    }

    private var movementLogsSection: some View {
        Section(header: Text("Movements")) {
            ForEach(workout.movementLogsArray, id: \.self) { movementLog in
                NavigationLink(destination: MovementLogEditView(movementLog: movementLog)) {
                    Text(movementLog.movement?.name ?? "Unknown Movement")
                }
            }
            .onDelete(perform: deleteMovementLog)

            Button(action: {
                showingMovementEntryView = true
            }) {
                Label("Add Movement", systemImage: "plus")
            }
        }
    }

    private var formattedDate: String {
        workout.date?.formatted(date: .long, time: .shortened) ?? "Unknown Date"
    }

    private func deleteMovementLog(at offsets: IndexSet) {
        for offset in offsets {
            if offset < workout.movementLogsArray.count {
                let movementLogToDelete = workout.movementLogsArray[offset]
                viewContext.delete(movementLogToDelete)
                workout.removeFromMovementLogs(movementLogToDelete)
            }
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting movement log: \(error)")
        }
    }
}

extension Workout {
    var movementLogsArray: [MovementLog] {
        let set = movementLogs as? Set<MovementLog> ?? []
        return set.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }
}
