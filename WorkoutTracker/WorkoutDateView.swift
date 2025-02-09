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
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Select Workout Date")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                Text("Choose when you completed this workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            DatePicker("Workout Date", selection: $workoutDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(.horizontal)
                .tint(.blue)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    createNewWorkout()
                    navigateToPainCheck = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    showCancelAlert = true
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Workout", isPresented: $showCancelAlert) {
            Button("Yes, Cancel", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
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
