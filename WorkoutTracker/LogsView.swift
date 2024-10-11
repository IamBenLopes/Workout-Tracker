import SwiftUI
import CoreData

struct LogsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: false)],
        animation: .default)
    private var workouts: FetchedResults<Workout>

    var body: some View {
        NavigationView {
            List {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationTitle("Workout Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            offsets.map { workouts[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.displayName)
                .font(.headline)
            Text("Date: \(formattedDate)")
            Text("Focus: \(workout.workoutFocus ?? "None")")
            Text("Pre-workout Pain: \(workout.prePainLevel)")
            Text("Post-workout Pain: \(workout.postPainLevel)")
        }
    }

    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return workout.date.map { dateFormatter.string(from: $0) } ?? "Unknown Date"
    }
}
