import SwiftUI
import CoreData

struct WorkoutEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var workout: Workout
    @State private var showAddMovement = false
    
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
                
                DatePicker("Date", selection: Binding(
                    get: { self.workout.date ?? Date() },
                    set: { self.workout.date = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                
                Picker("Workout Focus", selection: Binding(
                    get: { self.workout.workoutFocus ?? "" },
                    set: { self.workout.workoutFocus = $0 }
                )) {
                    Text("Not set").tag("")
                    Text("Strength").tag("Strength")
                    Text("Cardio").tag("Cardio")
                    Text("Flexibility").tag("Flexibility")
                    Text("Recovery").tag("Recovery")
                }
                
                Stepper(value: Binding(
                    get: { Double(self.workout.prePainLevel) },
                    set: { self.workout.prePainLevel = Int16($0) }
                ), in: 0...10) {
                    Text("Pre-Workout Pain: \(self.workout.prePainLevel)")
                }
                
                Stepper(value: Binding(
                    get: { Double(self.workout.postPainLevel) },
                    set: { self.workout.postPainLevel = Int16($0) }
                ), in: 0...10) {
                    Text("Post-Workout Pain: \(self.workout.postPainLevel)")
                }
                
                TextEditor(text: Binding(
                    get: { self.workout.postNotes ?? "" },
                    set: { self.workout.postNotes = $0 }
                ))
                .frame(height: 100)
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
            MovementEntryView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
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
    
}
    extension Collection {
        subscript(safe index: Index) -> Element? {
            return indices.contains(index) ? self[index] : nil
        }
    }
