import SwiftUI

struct MovementLogDetailView: View {
    @ObservedObject var movementLog: MovementLog
    
    var body: some View {
        List {
            Section(header: Text("Details")) {
                Text("Date: \(movementLog.formattedDate)")
                Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
            }
            
            Section(header: Text("Sets")) {
                ForEach(movementLog.setsArray, id: \.self) { set in
                    VStack(alignment: .leading) {
                        Text("Set \(set.setNumber)")
                        if let primaryType = set.primaryMetricType, primaryType != "None" {
                            Text("\(primaryType): \(set.formattedPrimaryMetricValue) \(set.primaryMetricUnit ?? "")")
                        }
                        if let secondaryType = set.secondaryMetricType, secondaryType != "None" {
                            Text("\(secondaryType): \(set.formattedSecondaryMetricValue) \(set.secondaryMetricUnit ?? "")")
                        }
                        if let notes = set.notes, !notes.isEmpty {
                            Text("Notes: \(notes)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Log Details")
    }
}

