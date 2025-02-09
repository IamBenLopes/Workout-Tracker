import SwiftUI
import CoreData

struct PainCheckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var painLevel: Double = 0
    @State private var navigateToWorkoutFocus = false
    @State private var showCancelAlert = false
    var splitDay: SplitDay?
    @ObservedObject var splitManager: WorkoutSplitManager

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Pre-Workout Pain Check")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("How much pain are you experiencing?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                Text("\(Int(painLevel))")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(painLevelColor)
                
                Text(painLevelDescription)
                    .font(.headline)
                    .foregroundColor(painLevelColor)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("No Pain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Severe Pain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $painLevel, in: 0...10, step: 1)
                    .tint(painLevelColor)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    savePainLevel()
                    navigateToWorkoutFocus = true
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
        .padding(.top, 16)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Workout", isPresented: $showCancelAlert) {
            Button("Yes, Cancel", role: .destructive) {
                viewContext.delete(workout)
                try? viewContext.save()
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel? All data will be lost.")
        }
        .navigationDestination(isPresented: $navigateToWorkoutFocus) {
            WorkoutFocusView(workout: workout, splitDay: splitDay)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var painLevelColor: Color {
        switch Int(painLevel) {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        default:
            return .red
        }
    }
    
    private var painLevelDescription: String {
        switch Int(painLevel) {
        case 0:
            return "No Pain"
        case 1...3:
            return "Mild Pain"
        case 4...6:
            return "Moderate Pain"
        case 7...9:
            return "Severe Pain"
        case 10:
            return "Extreme Pain"
        default:
            return ""
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
