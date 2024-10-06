import SwiftUI
import CoreData

struct MovementTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    var workout: Workout

    var body: some View {
        NavigationStack {
            VStack {
                Text("Select Movement Type")
                    .font(.headline)
                    .padding()

                List {
                    NavigationLink("Cardio", destination: MovementSelectionView(workout: workout, movementType: "Cardio"))
                    NavigationLink("Strength", destination: MovementSelectionView(workout: workout, movementType: "Strength"))
                    NavigationLink("Stretch", destination: MovementSelectionView(workout: workout, movementType: "Stretch"))
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Movement Type")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MovementSelectionView: View {
    @ObservedObject var workout: Workout
    var movementType: String

    var body: some View {
        Text("Movement Selection for \(movementType)")
        // Implement the rest of the view here
    }
}
