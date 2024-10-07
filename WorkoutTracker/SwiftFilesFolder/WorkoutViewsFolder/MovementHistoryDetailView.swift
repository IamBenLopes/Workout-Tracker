import SwiftUI
import CoreData

struct MovementHistoryDetailView: View {
    @ObservedObject var movementLog: MovementLog
    
    var body: some View {
        List {
            Section(header: Text("Movement Log Details")) {
                Text("Date: \(movementLog.formattedDate)")
                Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
                if let workout = movementLog.workout {
                    Text("Workout: \(workout.displayName)")
                }
            }
            
            Section(header: Text("Sets")) {
                ForEach(movementLog.setsArray, id: \.self) { set in
                    VStack(alignment: .leading) {
                        Text("Set \(set.setNumber)")
                            .font(.headline)
                        if let primaryType = set.primaryMetricType, primaryType != "None" {
                            Text("\(primaryType): \(set.formattedPrimaryMetricValue) \(set.primaryMetricUnit ?? "")")
                        }
                        if let secondaryType = set.secondaryMetricType, secondaryType != "None" {
                            Text("\(secondaryType): \(set.formattedSecondaryMetricValue) \(set.secondaryMetricUnit ?? "")")
                        }
                        if let notes = set.notes, !notes.isEmpty {
                            Text("Notes: \(notes)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Movement Log Details")
    }
}

