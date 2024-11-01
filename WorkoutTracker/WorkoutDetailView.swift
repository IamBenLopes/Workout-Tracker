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
            Text("Name: \(workout.workoutName ?? "Unnamed Workout")")
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
            ForEach(Array(workout.movementLogsArray.enumerated()), id: \.element) { index, movementLog in
                NavigationLink(destination: MovementLogEditView(movementLog: movementLog)) {
                    HStack {
                        Text("\(index + 1).")
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        VStack(alignment: .leading) {
                            Text(movementLog.movement?.name ?? "Unknown Movement")
                            Text("Added: \(movementLog.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
        withAnimation {
            let sortedLogs = workout.sortedMovementLogs
            
            // Delete the logs
            for index in offsets {
                if index < sortedLogs.count {
                    let movementLogToDelete = sortedLogs[index]
                    workout.removeFromMovementLogs(movementLogToDelete)
                    viewContext.delete(movementLogToDelete)
                }
            }
            
            // Reorder remaining logs
            workout.reorderMovementLogs()
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting movement log: \(error)")
            }
        }
    }
}

