import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var isEditing = false
    @State private var showingMovementEntryView = false
    
    // Add state variables for editing
    @State private var workoutName: String
    @State private var prePainLevel: Int
    @State private var postPainLevel: Int
    @State private var workoutFocus: String
    @State private var postNotes: String
    
    init(workout: Workout) {
        self.workout = workout
        // Initialize state with current values
        _workoutName = State(initialValue: workout.workoutName ?? "")
        _prePainLevel = State(initialValue: Int(workout.prePainLevel))
        _postPainLevel = State(initialValue: Int(workout.postPainLevel))
        _workoutFocus = State(initialValue: workout.workoutFocus ?? "")
        _postNotes = State(initialValue: workout.postNotes ?? "")
    }

    var body: some View {
        List {
            workoutDetailsSection
            movementLogsSection
        }
        .navigationBarTitle(workout.displayName, displayMode: .inline)
        .navigationBarItems(trailing: Button(isEditing ? "Done" : "Edit") {
            if isEditing {
                saveChanges()
            }
            isEditing.toggle()
        })
        .sheet(isPresented: $showingMovementEntryView) {
            MovementEntryView(workout: workout, onFinish: {
                dismiss()
            })
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var workoutDetailsSection: some View {
        Section(header: Text("Workout Details")) {
            if isEditing {
                TextField("Workout Name", text: $workoutName)
                DatePicker("Date", selection: Binding(
                    get: { workout.date ?? Date() },
                    set: { workout.date = $0 }
                ))
                Stepper("Pre-Workout Pain: \(prePainLevel)", value: $prePainLevel, in: 0...10)
                Stepper("Post-Workout Pain: \(postPainLevel)", value: $postPainLevel, in: 0...10)
                Picker("Workout Focus", selection: $workoutFocus) {
                    Text("None").tag("")
                    Text("Strength").tag("Strength")
                    Text("Hypertrophy").tag("Hypertrophy")
                    Text("Endurance").tag("Endurance")
                }
                TextEditor(text: $postNotes)
                    .frame(height: 100)
            } else {
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
    }

    private func saveChanges() {
        workout.workoutName = workoutName
        workout.prePainLevel = Int16(prePainLevel)
        workout.postPainLevel = Int16(postPainLevel)
        workout.workoutFocus = workoutFocus
        workout.postNotes = postNotes
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving workout changes: \(error)")
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

