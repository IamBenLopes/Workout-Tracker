import SwiftUI
import CoreData

struct WorkoutFocusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    let focusAreas = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Cardio"]
    @State private var selectedFocusAreas: Set<String> = []
    @State private var navigateToOverview = false
    @State private var showCancelAlert = false
    var splitDay: SplitDay?

    init(workout: Workout, splitDay: SplitDay? = nil) {
        self._workout = ObservedObject(initialValue: workout)
        self.splitDay = splitDay
        if let existingFocus = workout.workoutFocus {
            self._selectedFocusAreas = State(initialValue: Set(existingFocus.components(separatedBy: ", ")))
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Workout Focus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                
                Text("Select the muscle groups you'll be working on")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            List {
                ForEach(focusAreas, id: \.self) { area in
                    MultipleSelectionRow(
                        title: area,
                        isSelected: selectedFocusAreas.contains(area)
                    ) {
                        if selectedFocusAreas.contains(area) {
                            selectedFocusAreas.remove(area)
                        } else {
                            selectedFocusAreas.insert(area)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            VStack(spacing: 16) {
                Button(action: {
                    let sortedAreas = selectedFocusAreas.sorted()
                    workout.workoutFocus = sortedAreas.joined(separator: ", ")
                    do {
                        try viewContext.save()
                        navigateToOverview = true
                    } catch {
                        print("Error saving workout focus: \(error)")
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(selectedFocusAreas.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(selectedFocusAreas.isEmpty)
                
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
                viewContext.delete(workout)
                try? viewContext.save()
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel? All data will be lost.")
        }
        .navigationDestination(isPresented: $navigateToOverview) {
            WorkoutOverviewView(workout: workout, splitDay: splitDay, isPresented: $navigateToOverview, onFinish: {
                dismiss()
            })
            .environment(\.managedObjectContext, viewContext)
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
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
