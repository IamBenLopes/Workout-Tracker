import SwiftUI
import CoreData

struct MovementSelectionViewForSplitDay: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var splitDay: SplitDay
    @ObservedObject var splitManager: WorkoutSplitManager
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingAddMovementSheet = false
    @State private var selectedMovements: [Movement] = []
    @State private var selectedMovementClass = "Strength"
    @State private var movementsToAdd: Set<Movement> = []

    let movementClasses = ["Strength", "Cardio", "Stretch"]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Split Day")) {
                    Text("\(splitDay.dayName ?? "Unknown Day")")
                        .font(.headline)
                }

                Section(header: Text("Movements for this Day")) {
                    ForEach(Array(selectedMovements.enumerated()), id: \.element) { index, movement in
                        HStack {
                            Text("\(index + 1). \(movement.name ?? "Unknown Movement")")
                            Spacer()
                        }
                    }
                    .onMove(perform: moveMovement)
                    .onDelete(perform: deleteMovement)
                }

                Section(header: Text("Add Movements")) {
                    Picker("Movement Class", selection: $selectedMovementClass) {
                        ForEach(movementClasses, id: \.self) { movementClass in
                            Text(movementClass).tag(movementClass)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    ForEach(filteredMovements, id: \.self) { movement in
                        Button(action: {
                            toggleMovementSelection(movement)
                        }) {
                            HStack {
                                Text(movement.name ?? "")
                                Spacer()
                                if movementsToAdd.contains(movement) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }

                    if !movementsToAdd.isEmpty {
                        Button(action: addSelectedMovements) {
                            Text("Add Selected Movements")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }

                Button(action: {
                    showingAddMovementSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Movement")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Manage Movements")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveMovements()
                }
            )
            .toolbar {
                EditButton()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Action Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingAddMovementSheet) {
            AddMovementView(splitDay: splitDay, splitManager: splitManager, onAdd: { newMovement in
                if let newMovement = newMovement {
                    selectedMovements.append(newMovement)
                }
                showingAddMovementSheet = false
            })
        }
        .onAppear {
            loadSelectedMovements()
        }
    }

    private var filteredMovements: [Movement] {
        splitManager.getAllMovements().filter { $0.movementClass == selectedMovementClass }
    }

    private func loadSelectedMovements() {
        let splitDayMovementsSet = splitDay.splitDayMovements as? Set<SplitDayMovement> ?? []
        selectedMovements = splitDayMovementsSet.sorted { $0.order < $1.order }.compactMap { $0.movement }
    }

    private func moveMovement(from source: IndexSet, to destination: Int) {
        selectedMovements.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteMovement(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            let movementToRemove = selectedMovements[index]
            if splitManager.removeMovementFromSplitDay(movementToRemove, splitDay: splitDay) {
                selectedMovements.remove(at: index)
            } else {
                showAlert(message: "Failed to remove movement from split day")
            }
        }
    }

    private func toggleMovementSelection(_ movement: Movement) {
        if movementsToAdd.contains(movement) {
            movementsToAdd.remove(movement)
        } else {
            movementsToAdd.insert(movement)
        }
    }

    private func addSelectedMovements() {
        for movement in movementsToAdd {
            if !selectedMovements.contains(movement) {
                if splitManager.addMovementToSplitDay(movement, splitDay: splitDay) {
                    selectedMovements.append(movement)
                } else {
                    showAlert(message: "Failed to add movement \(movement.name ?? "") to split day")
                }
            }
        }
        movementsToAdd.removeAll()
    }

    private func saveMovements() {
        if splitManager.updateMovementOrder(for: splitDay, movements: selectedMovements) {
            showAlert(message: "Movements order saved successfully.")
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert(message: "Failed to update movement order")
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}


import SwiftUI
import CoreData

struct AddMovementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var splitDay: SplitDay
    @ObservedObject var splitManager: WorkoutSplitManager
    @State private var searchText = ""
    @State private var newMovementName = ""
    @State private var selectedMovementClass = "Strength"
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onAdd: (Movement?) -> Void

    let movementClasses = ["Strength", "Cardio", "Stretch"]

    var filteredMovements: [Movement] {
        let allMovements = splitManager.getAllMovements()
        if searchText.isEmpty {
            return allMovements.filter { $0.movementClass == selectedMovementClass }
        } else {
            return allMovements.filter { ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) && $0.movementClass == selectedMovementClass }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Movement Class")) {
                    Picker("Class", selection: $selectedMovementClass) {
                        ForEach(movementClasses, id: \.self) { movementClass in
                            Text(movementClass).tag(movementClass)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Create New Movement")) {
                    HStack {
                        TextField("New Movement Name", text: $newMovementName)
                        Button("Add") {
                            addNewMovement()
                        }
                        .disabled(newMovementName.isEmpty)
                    }
                }

                Section(header: Text("Existing Movements")) {
                    ForEach(filteredMovements, id: \.self) { movement in
                        Button(action: {
                            addExistingMovement(movement)
                        }) {
                            HStack {
                                Text(movement.name ?? "")
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search movements")
            .navigationTitle("Add Movement")
            .navigationBarItems(trailing: Button("Cancel") {
                onAdd(nil)
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func addNewMovement() {
        let newMovement = Movement(context: viewContext)
        newMovement.name = newMovementName
        newMovement.movementId = UUID()
        newMovement.movementClass = selectedMovementClass

        // Save the new movement to Core Data
        do {
            try viewContext.save()
            // Update the allMovements array in splitManager
            _ = try splitManager.fetchAllMovements()
        } catch {
            showAlert(message: "Failed to save new movement: \(error.localizedDescription)")
            return
        }

        if splitManager.addMovementToSplitDay(newMovement, splitDay: splitDay) {
            onAdd(newMovement)
        } else {
            showAlert(message: "Failed to add new movement to split day")
        }
    }

    private func addExistingMovement(_ movement: Movement) {
        if splitManager.addMovementToSplitDay(movement, splitDay: splitDay) {
            onAdd(movement)
        } else {
            showAlert(message: "Failed to add existing movement to split day")
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
