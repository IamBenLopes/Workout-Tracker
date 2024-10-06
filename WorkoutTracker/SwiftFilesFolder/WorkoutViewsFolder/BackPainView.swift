import SwiftUI
import CoreData
import Charts

struct BackPainView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: true)],
        animation: .default)
    private var workouts: FetchedResults<Workout>

    var body: some View {
        VStack {
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(workouts) { workout in
                        LineMark(
                            x: .value("Date", workout.date ?? Date()),
                            y: .value("Pain Level", max(workout.prePainLevel, workout.postPainLevel))
                        )
                    }
                }
                .frame(height: 200)
                .padding()
            } else {
                Text("Charts are available on iOS 16 and later.")
            }

            Spacer()
        }
        .navigationTitle("Back Pain Trend")
    }
}

struct BackPainView_Previews: PreviewProvider {
    static var previews: some View {
        BackPainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
