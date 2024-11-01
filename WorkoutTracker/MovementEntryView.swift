import SwiftUI
import CoreData

struct MovementEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var movementName = ""
    @State private var selectedMovementClass = "Strength"
    @State private var groupedMovements: [String: [Movement]] = [:]
    @State private var showSetEntry = false
    @State private var newMovementLog: MovementLog?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var searchText = ""

    let movementClasses = ["Strength", "Cardio", "Stretch"]

    var body: some View {
        VStack {
            Text("Add Movement")
                .font(.headline)
                .padding()

            Picker("Movement Class", selection: $selectedMovementClass) {
                ForEach(movementClasses, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedMovementClass) { _, _ in
                loadGroupedMovements()
            }

            List {
                ForEach(Array(groupedMovements.keys.sorted()), id: \.self) { muscleGroup in
                    let filteredMovements = groupedMovements[muscleGroup]?.filter {
                        searchText.isEmpty || 
                        ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false)
                    } ?? []
                    
                    if !filteredMovements.isEmpty {
                        Section(header: Text(muscleGroup)) {
                            ForEach(filteredMovements, id: \.self) { movement in
                                Button(action: {
                                    movementName = movement.name ?? ""
                                    createMovementLogAndProceed(movement: movement)
                                }) {
                                    Text(movement.name ?? "")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())

            TextField("Search or Enter New Movement", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { _, newValue in
                    movementName = newValue
                }

            Button(action: {
                if !movementName.isEmpty {
                    createMovementLogAndProceed()
                }
            }) {
                Text("Next")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(movementName.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(movementName.isEmpty)
        }
        .onAppear {
            loadGroupedMovements()
        }
        .sheet(isPresented: $showSetEntry) {
            if let movementLog = newMovementLog {
                SetEntryView(movementLog: movementLog)
            }
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })
    }

    func loadGroupedMovements() {
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Movement.name, ascending: true)]
        request.predicate = NSPredicate(format: "movementClass == %@", selectedMovementClass)
        do {
            let movements = try viewContext.fetch(request)
            groupedMovements = Dictionary(grouping: movements) { movement in
                movement.muscleGroups?.first?.name ?? "Uncategorized"
            }
        } catch {
            print("Error fetching movements: \(error)")
            errorMessage = "Failed to load movements: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    func createMovementLogAndProceed(movement: Movement? = nil) {
        do {
            let movement = try getOrCreateMovement(existingMovement: movement)
            
            let movementLog = MovementLog(context: viewContext)
            movementLog.movement = movement
            movementLog.workout = workout
            
            let now = Date()
            Thread.sleep(forTimeInterval: 0.1)
            movementLog.date = now
            movementLog.movementLogId = UUID()
            
            let currentMaxOrder = workout.movementLogsArray.map { $0.logOrder }.max() ?? -1
            let newOrder = currentMaxOrder + 1
            movementLog.logOrder = Int16(newOrder)
            
            workout.addToMovementLogs(movementLog)
            
            try viewContext.save()
            self.newMovementLog = movementLog
            self.showSetEntry = true
        } catch {
            print("Error saving movement log: \(error)")
            errorMessage = "Failed to create movement log: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func getOrCreateMovement(existingMovement: Movement?) throws -> Movement {
        if let movement = existingMovement {
            return movement
        }

        let fetchRequest: NSFetchRequest<Movement> = Movement.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND movementClass == %@", movementName, selectedMovementClass)
        fetchRequest.fetchLimit = 1
        
        if let existingMovement = try viewContext.fetch(fetchRequest).first {
            return existingMovement
        } else {
            let newMovement = Movement(context: viewContext)
            newMovement.name = movementName
            newMovement.movementClass = selectedMovementClass
            newMovement.movementId = UUID()
            return newMovement
        }
    }
}