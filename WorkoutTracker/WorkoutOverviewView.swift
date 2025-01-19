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
    @State private var refreshTrigger = false
    var isEditing: Bool
    var splitDay: SplitDay?
    @State private var movementsLoaded = false
    var onFinish: () -> Void
    @State private var showDismissAlert = false
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMovementLog: MovementLog?
    @State private var showSetEntryView = false

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
        let sortedMovementLogs: [MovementLog] = {
            let splitDayMovements = splitDay?.splitDayMovements as? Set<SplitDayMovement> ?? []
            let movementOrder: [Movement: Int] = Dictionary(uniqueKeysWithValues: splitDayMovements.compactMap { splitDayMovement in
                guard let movement = splitDayMovement.movement else { return nil }
                return (movement, Int(splitDayMovement.order))
            })
            
            return (workout.movementLogs as? Set<MovementLog> ?? [])
                .sorted { log1, log2 in
                    // If either has a start time, sort by that
                    if let date1 = log1.firstSetDate {
                        if let date2 = log2.firstSetDate {
                            return date1 < date2
                        }
                        return true // Started movements come first
                    }
                    if log2.firstSetDate != nil {
                        return false
                    }
                    
                    // If neither has started, check if they're from the plan
                    let isFromPlan1 = splitDay?.splitDayMovements?.contains(where: { ($0 as? SplitDayMovement)?.movement == log1.movement }) == true
                    let isFromPlan2 = splitDay?.splitDayMovements?.contains(where: { ($0 as? SplitDayMovement)?.movement == log2.movement }) == true
                    
                    if isFromPlan1 && isFromPlan2 {
                        // Both from plan, use plan order
                        let order1 = movementOrder[log1.movement!] ?? Int.max
                        let order2 = movementOrder[log2.movement!] ?? Int.max
                        return order1 < order2
                    }
                    
                    // Finally, sort by added date
                    return log1.date ?? Date() < log2.date ?? Date()
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
                ForEach(Array(sortedMovementLogs.enumerated()), id: \.element) { index, movementLog in
                    Button {
                        selectedMovementLog = movementLog
                        showSetEntryView = true
                    } label: {
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(movementLog.movement?.name ?? "Unknown Movement")
                                HStack(spacing: 8) {
                                    if let splitDay = splitDay, 
                                       let movement = movementLog.movement,
                                       splitDay.splitDayMovements?.contains(where: { ($0 as? SplitDayMovement)?.movement == movement }) == true {
                                        Text("Imported from workout plan")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Added by user")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let firstSetDate = movementLog.firstSetDate {
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Started: \(firstSetDate.formatted(date: .numeric, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                .onDelete(perform: { indexSet in
                    deleteMovementLog(movementLogs: sortedMovementLogs, at: indexSet)
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
                saveChanges()
                if !isEditing {
                    isPresented = false
                    onFinish()
                } else {
                    dismiss()
                }
            }
        )
        .sheet(isPresented: $showMovementEntryView) {
            MovementEntryView(workout: workout, onFinish: {
                print("DEBUG: WorkoutOverviewView - onFinish called from MovementEntryView")
                print("DEBUG: WorkoutOverviewView - Current sheets state before dismissal:")
                print("DEBUG: WorkoutOverviewView - showMovementEntryView: \(showMovementEntryView)")
                print("DEBUG: WorkoutOverviewView - selectedMovementLog exists: \(selectedMovementLog != nil)")
                // First dismiss any open SetEntryView
                selectedMovementLog = nil
                // Then dismiss MovementEntryView
                DispatchQueue.main.async {
                    showMovementEntryView = false
                    // Finally refresh the view
                    refreshTrigger.toggle()
                }
            })
            .environment(\.managedObjectContext, viewContext)
        }
        .refreshable {
            print("DEBUG: WorkoutOverviewView - Refresh triggered")
            // Trigger view refresh
            refreshTrigger.toggle()
        }
        .onChange(of: refreshTrigger) { _, _ in
            print("DEBUG: WorkoutOverviewView - Refresh trigger changed")
            // This will force the view to recalculate sortedMovementLogs
            workout.objectWillChange.send()
        }
        .onAppear {
            print("DEBUG: WorkoutOverviewView - View appeared")
            print("DEBUG: WorkoutOverviewView - Workout date: \(workout.date?.description ?? "nil")")
            if let splitDay = splitDay, !movementsLoaded {
                prepopulateMovements(from: splitDay)
                movementsLoaded = true
            }
        }
        .interactiveDismissDisabled(true)
        .alert("End Workout?", isPresented: $showDismissAlert) {
            Button("End Workout", role: .destructive) {
                saveChanges()
                isPresented = false
                onFinish()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to end this workout? Your progress will be saved.")
        }
        .alert("Finish Workout?", isPresented: $showFinishAlert) {
            Button("Finish", role: .none) {
                saveChanges()
                isPresented = false
                onFinish()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to finish this workout? Your progress will be saved.")
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                showDismissAlert = true
            }
        }
        .sheet(item: $selectedMovementLog) { movementLog in
            SetEntryView(movementLog: movementLog, onFinish: {
                print("DEBUG: WorkoutOverviewView - onFinish called from SetEntryView")
                print("DEBUG: WorkoutOverviewView - Current sheets state:")
                print("DEBUG: WorkoutOverviewView - selectedMovementLog exists: \(selectedMovementLog != nil)")
                print("DEBUG: WorkoutOverviewView - showMovementEntryView: \(showMovementEntryView)")
                // Close sheets in sequence
                DispatchQueue.main.async {
                    selectedMovementLog = nil
                    showMovementEntryView = false
                    print("DEBUG: WorkoutOverviewView - After closing sheets:")
                    print("DEBUG: WorkoutOverviewView - selectedMovementLog exists: \(selectedMovementLog != nil)")
                    print("DEBUG: WorkoutOverviewView - showMovementEntryView: \(showMovementEntryView)")
                    // Refresh after all sheets are closed
                    refreshTrigger.toggle()
                }
            })
            .environment(\.managedObjectContext, viewContext)
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
        let splitDayMovements = (splitDay.splitDayMovements as? Set<SplitDayMovement> ?? [])
            .sorted { $0.order < $1.order }
            
        for splitDayMovement in splitDayMovements {
            if let movement = splitDayMovement.movement {
                let movementLog = MovementLog(context: viewContext)
                movementLog.movementLogId = UUID()
                movementLog.workout = workout
                movementLog.movement = movement
                movementLog.date = Date()
                movementLog.logOrder = splitDayMovement.order
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
