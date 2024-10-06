import SwiftUI
import CoreData

struct WorkoutDateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var workoutDate = Date()
    @State private var showCancelAlert = false
    @State private var navigateToPainCheck = false
    @State private var newWorkout: Workout?
    var splitDay: SplitDay?
    @ObservedObject var splitManager: WorkoutSplitManager
    
    var body: some View {
        VStack {
            Text("Select Workout Date")
                .font(.headline)
                .padding()
            
            DatePicker("Workout Date", selection: $workoutDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            Button(action: {
                createNewWorkout()
                navigateToPainCheck = true
            }) {
                Text("Next")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("New Workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    showCancelAlert = true
                }
            }
        }
        .alert("Cancel Workout", isPresented: $showCancelAlert) {
            Button("Yes", role: .destructive) {
                dismiss()
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel? All data will be lost.")
        }
        .navigationDestination(isPresented: $navigateToPainCheck) {
            if let workout = newWorkout {
                PainCheckView(workout: workout, splitDay: splitDay, splitManager: splitManager)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func createNewWorkout() {
        let workout = Workout(context: viewContext)
        workout.date = workoutDate
        workout.workoutId = UUID()
        
        if let splitDay = splitDay {
            let workoutSplitDay = WorkoutSplitDay(context: viewContext)
            workoutSplitDay.workout = workout
            workoutSplitDay.splitDay = splitDay
        }
        
        do {
            try viewContext.save()
            self.newWorkout = workout
        } catch {
            print("Error saving new workout: \(error)")
        }
    }
}
