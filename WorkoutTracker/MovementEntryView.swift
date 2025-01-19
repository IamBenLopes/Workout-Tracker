import SwiftUI
import CoreData

struct MovementEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    var onFinish: (() -> Void)?
    @State private var selectedMovementClass = "Strength"
    @State private var groupedMovements: [String: [Movement]] = [:]
    @State private var showSetEntry = false
    @State private var newMovementLog: MovementLog?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var showNewMovementView = false

    let movementClasses = ["Strength", "Cardio", "Stretch"]

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Movement")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
                .onAppear {
                    print("DEBUG: MovementEntryView - View appeared")
                    print("DEBUG: MovementEntryView - Workout date: \(workout.date?.description ?? "nil")")
                }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search movements...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            .padding(.horizontal)

            // New Movement Button
            Button(action: {
                showNewMovementView = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Movement")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Picker("Movement Class", selection: $selectedMovementClass) {
                ForEach(movementClasses, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
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
        }
        .onAppear {
            loadGroupedMovements()
        }
        .sheet(isPresented: $showSetEntry) {
            if let movementLog = newMovementLog {
                SetEntryView(movementLog: movementLog, onFinish: {
                    print("DEBUG: MovementEntryView - onFinish called from SetEntryView")
                    showSetEntry = false
                    onFinish?()
                })
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage)
        })
        .sheet(isPresented: $showNewMovementView) {
            NewMovementView(workout: workout, onFinish: {
                print("DEBUG: MovementEntryView - onFinish called from NewMovementView")
                dismiss()
            })
                .environment(\.managedObjectContext, viewContext)
        }
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

    func createMovementLogAndProceed(movement: Movement) {
        do {
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
}