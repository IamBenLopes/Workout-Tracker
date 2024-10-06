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

// Keep this extension here
extension MovementLog {
    var setsArray: [SetEntity] {
        let setSet = sets as? Set<SetEntity> ?? []
        return setSet.sorted { $0.setNumber < $1.setNumber }
    }
}

extension SetEntity {
    var formattedPrimaryMetricValue: String {
        String(format: "%.2f", primaryMetricValue)
    }
    
    var formattedSecondaryMetricValue: String {
        String(format: "%.2f", secondaryMetricValue)
    }
}
