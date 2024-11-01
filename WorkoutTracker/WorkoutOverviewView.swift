import SwiftUI

struct WorkoutOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var isPresented: Bool
    @ObservedObject var workout: Workout
    @State private var showMovementEntryView = false
    @State private var showFinishAlert = false
    @State private var postNotes: String
    @State private var prePainLevel: Double
    @State private var postPainLevel: Double
    @State private var workoutFocus: String
    @State private var workoutName: String
    var isEditing: Bool
    var splitDay: SplitDay?
    @State private var movementsLoaded = false
    var onFinish: () -> Void
    @State private var showDismissAlert = false
    @Environment(\.dismiss) private var dismiss

    init(workout: Workout, isEditing: Bool = false, splitDay: SplitDay? = nil, isPresented: Binding<Bool>, onFinish: @escaping () -> Void) {
        self.workout = workout
        self.isEditing = isEditing
        self.splitDay = splitDay
        _isPresented = isPresented
        _postNotes = State(initialValue: workout.postNotes ?? "")
        _prePainLevel = State(initialValue: Double(workout.prePainLevel))
        _postPainLevel = State(initialValue: Double(workout.postPainLevel))
        _workoutFocus = State(initialValue: workout.workoutFocus ?? "")
        _workoutName = State(initialValue: workout.workoutName ?? "")
        self.onFinish = onFinish
    }

    var body: some View {
        let _: [MovementLog] = {
            let splitDayMovements = splitDay?.splitDayMovements as? Set<SplitDayMovement> ?? []
            let movementOrder: [Movement: Int] = Dictionary(uniqueKeysWithValues: splitDayMovements.compactMap { splitDayMovement in
                guard let movement = splitDayMovement.movement else { return nil }
                return (movement, Int(splitDayMovement.order))
            })
            
            return (workout.movementLogs as? Set<MovementLog> ?? [])
                .sorted { 
                    guard let movement1 = $0.movement, let movement2 = $1.movement else { return false }
                    return movementOrder[movement1] ?? Int.max < movementOrder[movement2] ?? Int.max
                }
        }()

        return Form {
            Section(header: Text("Workout Details")) {
                TextField("Workout Name", text: $workoutName)
                
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
                ForEach(Array(workout.movementLogsArray.enumerated()), id: \.element) { index, movementLog in
                    NavigationLink(destination: SetEntryView(movementLog: movementLog)) {
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
                .onDelete(perform: { indexSet in
                    deleteMovementLog(movementLogs: workout.movementLogsArray, at: indexSet)
                })

                Button(action: {
                    self.showMovementEntryView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Movement")
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Workout" : "Today's Workout")
        .navigationBarItems(
            leading: Button("Cancel") {
                showDismissAlert = true
            },
            trailing: Button(isEditing ? "Save" : "Finish") {
                self.showFinishAlert = true
            }
        )
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
                    isPresented = false
                    onFinish()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            if let splitDay = splitDay, !movementsLoaded {
                prepopulateMovements(from: splitDay)
                movementsLoaded = true
            }
        }
        .interactiveDismissDisabled(true)
        .alert("End Workout?", isPresented: $showDismissAlert) {
            Button("End Workout", role: .destructive) {
                isPresented = false
                onFinish()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to end this workout? All unsaved progress will be lost.")
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                showDismissAlert = true
            }
        }
    }

    private func deleteMovementLog(movementLogs: [MovementLog], at offsets: IndexSet) {
        withAnimation {
            let sortedLogs = workout.movementLogsArray
            
            print("\nBefore deletion - Current logs:")
            for (index, log) in sortedLogs.enumerated() {
                print("Index: \(index), Name: \(log.movement?.name ?? "Unknown"), Date: \(log.date?.formatted() ?? "No date")")
            }
            
            // Delete the logs
            for index in offsets {
                if index < sortedLogs.count {
                    let movementLogToDelete = sortedLogs[index]
                    print("Deleting movement: \(movementLogToDelete.movement?.name ?? "Unknown") at index: \(index)")
                    workout.removeFromMovementLogs(movementLogToDelete)
                    viewContext.delete(movementLogToDelete)
                }
            }
            
            do {
                try viewContext.save()
                
                print("\nAfter deletion - Current logs:")
                for (index, log) in workout.movementLogsArray.enumerated() {
                    print("Index: \(index), Name: \(log.movement?.name ?? "Unknown"), Date: \(log.date?.formatted() ?? "No date")")
                }
            } catch {
                print("Error deleting movement log: \(error)")
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

    private func prepopulateMovements(from splitDay: SplitDay) {
        let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement> ?? []
        for (index, splitDayMovement) in splitDayMovements.enumerated() {
            if let movement = splitDayMovement.movement {
                let movementLog = MovementLog(context: viewContext)
                movementLog.movementLogId = UUID()
                movementLog.workout = workout
                movementLog.movement = movement
                movementLog.logOrder = Int16(index) // Changed to logOrder
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
            WorkoutOverviewView(workout: workout, isPresented: .constant(true), onFinish: {})
                .environment(\.managedObjectContext, context)
        }
    }
}

