import SwiftUI
import CoreData

struct PainCheckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var painLevel: Double = 1
    @State private var navigateToWorkoutFocus = false
    @State private var showCancelAlert = false
    var splitDay: SplitDay?
    @ObservedObject var splitManager: WorkoutSplitManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Pre-Workout Pain Check")
                .font(.headline)

            Text("Pain Level: \(Int(painLevel))")
                .font(.headline)
            
            HStack {
                Text("1")
                Slider(value: $painLevel, in: 1...10, step: 1)
                    .accentColor(.blue)
                Text("10")
            }
            .padding(.horizontal)

            Button(action: {
                savePainLevel()
                navigateToWorkoutFocus = true
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
        .padding()
        .navigationTitle("Pain Check")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    showCancelAlert = true
                }
            }
        }
        .alert("Cancel Workout", isPresented: $showCancelAlert) {
            Button("Yes", role: .destructive) {
                viewContext.delete(workout)
                try? viewContext.save()
                dismiss()
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel? All data will be lost.")
        }
        .navigationDestination(isPresented: $navigateToWorkoutFocus) {
            WorkoutFocusView(workout: workout, splitDay: splitDay)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func savePainLevel() {
        workout.prePainLevel = Int16(painLevel)
        if let splitDay = splitDay {
            splitDay.isCompleted = true
            _ = splitManager.completeSplitDay(splitDay)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error saving pain level: \(error)")
        }
    }
}
