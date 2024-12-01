import SwiftUI

struct MovementLogDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var movementLog: MovementLog
    @State private var logDate: Date
    
    init(movementLog: MovementLog) {
        self.movementLog = movementLog
        _logDate = State(initialValue: movementLog.date ?? Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                DatePicker("Date", selection: $logDate, displayedComponents: [.date])
                    .onChange(of: logDate) { oldValue, newValue in
                        movementLog.date = newValue
                        saveContext()
                    }
                Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
            }
            
            Section(header: Text("Sets")) {
                ForEach(movementLog.setsArray, id: \.self) { set in
                    VStack(alignment: .leading) {
                        Text("Set \(set.setNumber)")
                        if let primaryType = set.primaryMetricType, primaryType != "None" {
                            if set.usePrimarySplitMetrics {
                                Text("\(primaryType) Left: \(Int(set.primaryMetricValueLeft)) \(set.primaryMetricUnit ?? "")")
                                Text("\(primaryType) Right: \(Int(set.primaryMetricValueRight)) \(set.primaryMetricUnit ?? "")")
                            } else {
                                Text("\(primaryType): \(Int(Double(set.formattedPrimaryMetricValue) ?? 0)) \(set.primaryMetricUnit ?? "")")
                            }
                        }
                        if let secondaryType = set.secondaryMetricType, secondaryType != "None" {
                            if set.useSecondarySplitMetrics {
                                Text("\(secondaryType) Left: \(Int(set.secondaryMetricValueLeft)) \(set.secondaryMetricUnit ?? "")")
                                Text("\(secondaryType) Right: \(Int(set.secondaryMetricValueRight)) \(set.secondaryMetricUnit ?? "")")
                            } else {
                                Text("\(secondaryType): \(Int(Double(set.formattedSecondaryMetricValue) ?? 0)) \(set.secondaryMetricUnit ?? "")")
                            }
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
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
