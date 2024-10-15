import SwiftUI
import CoreData

struct WorkoutLoggingFlow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var splitManager: WorkoutSplitManager
    @State private var currentStep = 0
    @State private var workout: Workout?
    @State private var workoutDate = Date()
    let splitDay: SplitDay?
    @State private var isPresented = true
    @State private var showCancelAlert = false
    
    init(splitDay: SplitDay? = nil) {
        let context = PersistenceController.shared.container.viewContext
        _splitManager = StateObject(wrappedValue: WorkoutSplitManager(context: context))
        self.splitDay = splitDay
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                switch currentStep {
                case 0:
                    dateSelectionView
                case 1:
                    if let workout = workout {
                        PainCheckView(workout: workout, splitDay: splitDay, splitManager: splitManager, onNext: {
                            currentStep += 1
                        })
                    }
                case 2:
                    if let workout = workout {
                        WorkoutFocusView(workout: workout, splitDay: splitDay, isPresented: $isPresented, onNext: {
                            currentStep += 1
                        })
                    }
                case 3:
                    if let workout = workout {
                        WorkoutOverviewView(workout: workout, splitDay: splitDay, isPresented: $isPresented, onFinish: {
                            dismiss()
                        })
                    }
                default:
                    Text("Error: Invalid step")
                }
            }
            .navigationBarTitle(splitDay != nil ? "Log Split Workout" : "Log Workout", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                showCancelAlert = true
            })
            .alert(isPresented: $showCancelAlert) {
                Alert(
                    title: Text("Cancel Workout"),
                    message: Text("Are you sure you want to cancel? All data will be lost."),
                    primaryButton: .destructive(Text("Yes")) {
                        if let workout = workout {
                            viewContext.delete(workout)
                            try? viewContext.save()
                        }
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    var dateSelectionView: some View {
        VStack {
            DatePicker("Workout Date", selection: $workoutDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            Button("Next") {
                createWorkout(date: workoutDate)
                currentStep += 1
            }
            .padding()
        }
    }
    
    private func createWorkout(date: Date) {
        let newWorkout = Workout(context: viewContext)
        newWorkout.date = date
        newWorkout.workoutId = UUID()
        
        if let splitDay = splitDay {
            newWorkout.workoutSplit = splitDay.workoutSplit
            newWorkout.splitDayNumber = splitDay.dayNumber
            // Auto-populate movements if it's a split workout
            // You'll need to implement this part based on your data model
        }
        
        do {
            try viewContext.save()
            self.workout = newWorkout
        } catch {
            print("Error creating workout: \(error)")
        }
    }
}

struct WorkoutLoggingFlow_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLoggingFlow()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
