import SwiftUI
import CoreData

struct MovementEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var movementName = ""
    @State private var selectedMovementClass = "Strength"
    @State private var previousMovements: [Movement] = []
    @State private var showSetEntry = false
    @State private var newMovementLog: MovementLog?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

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
                loadPreviousMovements()
            }

            List {
                ForEach(previousMovements, id: \.self) { movement in
                    Button(action: {
                        movementName = movement.name ?? ""
                        createMovementLogAndProceed(movement: movement)
                    }) {
                        Text(movement.name ?? "")
                    }
                }
            }
            .listStyle(PlainListStyle())

            TextField("Or Enter New Movement", text: $movementName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

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
            loadPreviousMovements()
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

    func loadPreviousMovements() {
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Movement.name, ascending: true)]
        request.predicate = NSPredicate(format: "movementClass == %@", selectedMovementClass)
        do {
            previousMovements = try viewContext.fetch(request)
        } catch {
            print("Error fetching previous movements: \(error)")
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
            movementLog.date = Date()
            movementLog.movementLogId = UUID()

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
