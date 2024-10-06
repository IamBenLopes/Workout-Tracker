import SwiftUI
import CoreData

struct SplitWorkoutFlow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let splitDay: SplitDay
    @ObservedObject var splitManager: WorkoutSplitManager
    @State private var workout: Workout?
    @State private var currentStep = 0
    @State private var workoutDate = Date()
    
    var body: some View {
        VStack {
            switch currentStep {
            case 0:
                dateSelectionView
            case 1:
                if let workout = workout {
                    PainCheckView(workout: workout, splitDay: splitDay, splitManager: splitManager)
                }
            case 2:
                if let workout = workout {
                    WorkoutOverviewView(workout: workout, splitDay: splitDay)
                }
            default:
                Text("Workout Complete!")
            }
        }
        .navigationTitle("Day \(splitDay.dayNumber): \(splitDay.dayName ?? "")")
        .navigationBarItems(leading: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
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
        newWorkout.workoutSplit = splitDay.workoutSplit
        newWorkout.splitDayNumber = splitDay.dayNumber
        
        do {
            try viewContext.save()
            self.workout = newWorkout
        } catch {
            print("Error creating workout: \(error)")
        }
    }
}
