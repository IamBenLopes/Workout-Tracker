import SwiftUI
import CoreData

struct WorkoutFocusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    let focusAreas = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Cardio"]
    @State private var selectedFocusAreas: [String] = []
    @State private var navigateToOverview = false
    @State private var showCancelAlert = false
    var splitDay: SplitDay?

    // Custom initializer to accept splitDay
    init(workout: Workout, splitDay: SplitDay? = nil) {
        self._workout = ObservedObject(initialValue: workout)
        self.splitDay = splitDay
    }

    var body: some View {
        VStack {
            Text("Select Workout Focus")
                .font(.headline)
                .padding()

            List {
                ForEach(focusAreas, id: \.self) { area in
                    MultipleSelectionRow(title: area, isSelected: selectedFocusAreas.contains(area)) {
                        if selectedFocusAreas.contains(area) {
                            selectedFocusAreas.removeAll(where: { $0 == area })
                        } else {
                            selectedFocusAreas.append(area)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())

            Button(action: {
                workout.workoutFocus = selectedFocusAreas.joined(separator: ", ")
                do {
                    try viewContext.save()
                    navigateToOverview = true
                } catch {
                    print("Error saving workout focus: \(error)")
                }
            }) {
                Text("Next")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedFocusAreas.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(selectedFocusAreas.isEmpty)
        }
        .navigationTitle("Workout Focus")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    showCancelAlert = true
                }
            }
        }
        .alert(isPresented: $showCancelAlert) {
            Alert(
                title: Text("Cancel Workout"),
                message: Text("All data will be lost if you continue."),
                primaryButton: .destructive(Text("Yes")) {
                    viewContext.delete(workout)
                    try? viewContext.save()
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .navigationDestination(isPresented: $navigateToOverview) {
            WorkoutOverviewView(workout: workout, splitDay: splitDay)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// Include the MultipleSelectionRow struct
struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct WorkoutFocusView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let workout = Workout(context: context)
        return NavigationStack {
            WorkoutFocusView(workout: workout)
                .environment(\.managedObjectContext, context)
        }
    }
}
