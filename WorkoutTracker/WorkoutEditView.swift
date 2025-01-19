import SwiftUI
import CoreData

struct WorkoutEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var showAddMovement = false
    @State private var workoutDate: Date
    
    init(workout: Workout) {
        self.workout = workout
        _workoutDate = State(initialValue: workout.date ?? Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("Workout Details")) {
                if workout.workoutSplit == nil {
                    TextField("Workout Name", text: Binding(
                        get: { self.workout.workoutName ?? "" },
                        set: { self.workout.workoutName = $0 }
                    ))
                } else {
                    Text("Name: \(workout.displayName)")
                        .foregroundColor(.gray)
                }
                
                DatePicker("Date", selection: $workoutDate, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: workoutDate) { oldValue, newValue in
                        workout.date = newValue
                        saveContext()
                    }
                
                Picker("Workout Focus", selection: Binding(
                    get: { self.workout.workoutFocus ?? "" },
                    set: { self.workout.workoutFocus = $0 }
                )) {
                    Text("None").tag("")
                    Text("Strength").tag("Strength")
                    Text("Hypertrophy").tag("Hypertrophy")
                    Text("Endurance").tag("Endurance")
                }
            }
            
            Section(header: Text("Movements")) {
                ForEach(workout.movementLogsArray, id: \.self) { movementLog in
                    NavigationLink(destination: MovementLogEditView(movementLog: movementLog)) {
                        Text(movementLog.movement?.name ?? "Unknown Movement")
                    }
                }
                .onDelete(perform: deleteMovementLog)
                
                Button(action: {
                    showAddMovement = true
                }) {
                    Label("Add Movement", systemImage: "plus")
                }
            }
        }
        .navigationBarTitle("Edit Workout", displayMode: .inline)
        .navigationBarItems(trailing: Button("Save") {
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error saving workout: \(error)")
            }
        })
        .sheet(isPresented: $showAddMovement) {
            MovementEntryView(workout: workout, onFinish: {
                dismiss()
            })
                .environment(\.managedObjectContext, viewContext)
        }
        .onDisappear {
            saveContext()
        }
    }
    
    private func deleteMovementLog(at offsets: IndexSet) {
        for index in offsets {
            if let movementLog = workout.movementLogsArray[safe: index] {
                viewContext.delete(movementLog)
            }
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting movement log: \(error)")
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}