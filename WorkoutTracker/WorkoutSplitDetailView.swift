import SwiftUI
import CoreData

struct WorkoutSplitDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workoutSplit: WorkoutSplit
    @ObservedObject var splitManager: WorkoutSplitManager
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedDays: [(dayNumber: Int, dayName: String)] = []
    @State private var selectedDay: SplitDay?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        List {
            Section(header: Text("Split Details")) {
                if isEditing {
                    TextField("Split Name", text: $editedName)
                } else {
                    Text("Name: \(workoutSplit.splitName ?? "Unnamed Split")")
                }
                Text("Created: \(workoutSplit.createdDate?.formatted() ?? "Unknown")")
                Text("Last Modified: \(workoutSplit.lastModifiedDate?.formatted() ?? "Unknown")")
            }

            Section(header: Text("Days")) {
                ForEach(editedDays.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        if isEditing {
                            HStack {
                                TextField("Day \(editedDays[index].dayNumber)", text: $editedDays[index].dayName)
                                Spacer()
                                Button(action: {
                                    deleteDay(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            Text("Day \(editedDays[index].dayNumber): \(editedDays[index].dayName)")
                        }

                        if let splitDays = workoutSplit.splitDays?.allObjects as? [SplitDay],
                           let currentDay = splitDays.first(where: { $0.dayNumber == Int16(editedDays[index].dayNumber) }) {
                            ForEach(currentDay.movementsArray, id: \.self) { movement in
                                Text("\(movement.name ?? "Unnamed") (\(movement.movementClass ?? "Unknown"))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .onMove { from, to in
                                moveMovement(in: currentDay, from: from, to: to)
                            }

                            Button(action: {
                                selectedDay = currentDay
                            }) {
                                Label("Add Movement", systemImage: "plus")
                            }
                        } else {
                            Text("No movements found for this day")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if isEditing {
                    Button(action: addNewDay) {
                        Label("Add Day", systemImage: "plus")
                    }
                }
            }

            if !isEditing {
                Section(header: Text("Actions")) {
                    Button("Start Workout") {
                        alertMessage = "Start Workout functionality not yet implemented"
                        showAlert = true
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Split" : "Split Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
        .sheet(item: $selectedDay) { day in
            MovementSelectionViewForSplitDay(splitDay: day, splitManager: splitManager)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Action Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            loadSplitDetails()
        }
    }

    private func loadSplitDetails() {
        editedName = workoutSplit.splitName ?? ""
        editedDays = (workoutSplit.splitDays?.allObjects as? [SplitDay] ?? [])
            .sorted { $0.dayNumber < $1.dayNumber }
            .map { (Int($0.dayNumber), $0.dayName ?? "") }
    }

    private func saveChanges() {
        workoutSplit.splitName = editedName
        workoutSplit.lastModifiedDate = Date()

        // Update split days
        let existingSplitDays = workoutSplit.splitDays?.allObjects as? [SplitDay] ?? []

        for editedDay in editedDays {
            if let existingDay = existingSplitDays.first(where: { $0.dayNumber == Int16(editedDay.dayNumber) }) {
                existingDay.dayName = editedDay.dayName
            } else {
                let newDay = SplitDay(context: viewContext)
                newDay.splitDayId = UUID()
                newDay.dayNumber = Int16(editedDay.dayNumber)
                newDay.dayName = editedDay.dayName
                newDay.workoutSplit = workoutSplit
            }
        }

        // Remove any extra days
        for existingDay in existingSplitDays {
            if !editedDays.contains(where: { $0.dayNumber == Int(existingDay.dayNumber) }) {
                viewContext.delete(existingDay)
            }
        }

        do {
            try viewContext.save()
            splitManager.fetchAllWorkoutSplits() // Refresh the list of workout splits
            alertMessage = "Changes saved successfully"
            showAlert = true
        } catch {
            print("Failed to save changes: \(error)")
            alertMessage = "Failed to save changes: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func deleteDay(at index: Int) {
        editedDays.remove(at: index)
        // Renumber the remaining days
        for i in index..<editedDays.count {
            editedDays[i].dayNumber = i + 1
        }
    }

    private func addNewDay() {
        let newDayNumber = editedDays.count + 1
        editedDays.append((dayNumber: newDayNumber, dayName: "Day \(newDayNumber)"))
    }

    private func moveMovement(in splitDay: SplitDay, from source: IndexSet, to destination: Int) {
        var movements = splitDay.movementsArray
        movements.move(fromOffsets: source, toOffset: destination)
        
        // Update the order of movements
        for (index, movement) in movements.enumerated() {
            if let splitDayMovement = splitDay.splitDayMovements?.first(where: { ($0 as? SplitDayMovement)?.movement == movement }) as? SplitDayMovement {
                splitDayMovement.order = Int16(index)
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to update movement order: \(error)")
        }
    }
}

extension SplitDay {
    var movementsArray: [Movement] {
        let splitDayMovements = splitDayMovements as? Set<SplitDayMovement> ?? []
        return splitDayMovements.sorted { $0.order < $1.order }.compactMap { $0.movement }
    }
}
