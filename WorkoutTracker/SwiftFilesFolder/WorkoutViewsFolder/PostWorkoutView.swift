import SwiftUI
import CoreData

struct PostWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    @State private var postPainLevel: Double = 1
    @State private var navigateToHome = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Post-Workout Pain Level")
                .font(.headline)

            Text("Pain Level: \(Int(postPainLevel))")
                .font(.headline)
            
            HStack {
                Text("1")
                Slider(value: $postPainLevel, in: 1...10, step: 1)
                    .accentColor(.blue)
                Text("10")
            }
            .padding(.horizontal)

            Button(action: {
                if savePostWorkoutData() {
                    navigateToHome = true
                }
            }) {
                Text("Finish Workout")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Text("Current post-pain level: \(workout.postPainLevel)")
                .font(.caption)
        }
        .padding()
        .navigationTitle("Post Workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if savePostWorkoutData() {
                        navigateToHome = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToHome) {
            ContentView()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            print("PostWorkoutView appeared. Current post-pain level: \(workout.postPainLevel)")
        }
    }

    private func savePostWorkoutData() -> Bool {
        workout.postPainLevel = Int16(postPainLevel)
        print("Attempting to save post-pain level: \(Int16(postPainLevel))")
        do {
            try viewContext.save()
            print("Post-workout pain level saved successfully: \(workout.postPainLevel)")
            
            // Verify the save
            viewContext.refresh(workout, mergeChanges: true)
            print("After save and refresh, post-pain level is: \(workout.postPainLevel)")
            
            return true
        } catch {
            print("Error saving post-workout data: \(error)")
            alertMessage = "Failed to save workout data. Please try again."
            showAlert = true
            return false
        }
    }
}
