import SwiftUI

struct WorkoutOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var workout: Workout
    @State private var showMovementEntryView = false
    @State private var showFinishAlert = false
    @State private var navigateToPostWorkout = false
    @State private var postNotes: String
    @State private var prePainLevel: Double
    @State private var postPainLevel: Double
    @State private var workoutFocus: String
    var isEditing: Bool
    var splitDay: SplitDay?
    @State private var movementsLoaded = false

    init(workout: Workout, isEditing: Bool = false, splitDay: SplitDay? = nil) {
        self.workout = workout
        self.isEditing = isEditing
        self.splitDay = splitDay
        _postNotes = State(initialValue: workout.postNotes ?? "")
        _prePainLevel = State(initialValue: Double(workout.prePainLevel))
        _postPainLevel = State(initialValue: Double(workout.postPainLevel))
        _workoutFocus = State(initialValue: workout.workoutFocus ?? "")
    }

    var body: some View {
        // Define sortedMovementLogs outside the Form to simplify the ForEach
        let sortedMovementLogs: [MovementLog] = {
            // Since 'timestamp' does not exist, sort by movement name
            return (workout.movementLogs as? Set<MovementLog> ?? [])
                .sorted {
                    ($0.movement?.name ?? "") < ($1.movement?.name ?? "")
                }
        }()

        return Form {
            Section(header: Text("Workout Details")) {
                DatePicker("Date", selection: Binding(
                    get: { self.workout.date ?? Date() },
                    set: { self.workout.date = $0 }
                ), displayedComponents: [.date, .hourAndMinute])

                Picker("Workout Focus", selection: $workoutFocus) {
                    Text("Not set").tag("")
                    ForEach(["Strength", "Cardio", "Flexibility", "Recovery"], id: \.self) { focus in
                        Text(focus).tag(focus)
                    }
                }

                HStack {
                    Text("Pre-Workout Pain")
                    Slider(value: $prePainLevel, in: 0...10, step: 1)
                    Text("\(Int(prePainLevel))")
                }

                HStack {
                    Text("Post-Workout Pain")
                    Slider(value: $postPainLevel, in: 0...10, step: 1)
                    Text("\(Int(postPainLevel))")
                }

                TextEditor(text: $postNotes)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            Section(header: Text("Movements")) {
                // Use the sortedMovementLogs variable
                ForEach(sortedMovementLogs) { movementLog in
                    NavigationLink(destination: SetEntryView(movementLog: movementLog)) {
                        Text(movementLog.movement?.name ?? "Unknown Movement")
                    }
                }
                .onDelete(perform: deleteMovementLog)

                Button(action: {
                    self.showMovementEntryView = true
                }) {
                    Text("Add Movement")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Workout" : "Today's Workout")
        .navigationBarItems(trailing: Button(isEditing ? "Save" : "Finish") {
            self.showFinishAlert = true
        })
        .sheet(isPresented: $showMovementEntryView) {
            MovementEntryView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(isPresented: $showFinishAlert) {
            Alert(
                title: Text(isEditing ? "Save Changes" : "Finish Workout"),
                message: Text(isEditing ? "Are you sure you want to save these changes?" : "Are you sure you want to finish the workout?"),
                primaryButton: .default(Text("Yes")) {
                    saveChanges()
                    if isEditing {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        navigateToPostWorkout = true
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .navigationDestination(isPresented: $navigateToPostWorkout) {
            PostWorkoutView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            if let splitDay = splitDay, !movementsLoaded {
                prepopulateMovements(from: splitDay)
                movementsLoaded = true
            }
        }
    }

    private func deleteMovementLog(at offsets: IndexSet) {
        let movementLogs = Array(workout.movementLogs as? Set<MovementLog> ?? [])
        for index in offsets {
            let movementLog = movementLogs[index]
            viewContext.delete(movementLog)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting movement log: \(error)")
        }
    }

    private func saveChanges() {
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

    private func prepopulateMovements(from splitDay: SplitDay) {
        // For each movement in the split day, create a MovementLog and associate it with the workout
        let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement> ?? []
        for splitDayMovement in splitDayMovements {
            if let movement = splitDayMovement.movement {
                let movementLog = MovementLog(context: viewContext)
                movementLog.movementLogId = UUID()
                movementLog.workout = workout
                movementLog.movement = movement
                // movementLog.timestamp = Date() // Removed because 'timestamp' does not exist
            }
        }
        do {
            try viewContext.save()
        } catch {
            print("Error pre-populating movements: \(error)")
        }
    }
}

struct WorkoutOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let workout = Workout(context: context)
        workout.postNotes = "Feeling good"
        workout.prePainLevel = 2
        workout.postPainLevel = 1
        workout.workoutFocus = "Strength"
        workout.date = Date()

        // Create a sample Movement and MovementLog
        let movement = Movement(context: context)
        movement.name = "Bench Press"
        movement.movementId = UUID()
        movement.movementClass = "Strength"

        let movementLog = MovementLog(context: context)
        movementLog.movementLogId = UUID()
        movementLog.workout = workout
        movementLog.movement = movement
        // movementLog.timestamp = Date() // Removed because 'timestamp' does not exist

        return NavigationStack {
            WorkoutOverviewView(workout: workout)
                .environment(\.managedObjectContext, context)
        }
    }
}
