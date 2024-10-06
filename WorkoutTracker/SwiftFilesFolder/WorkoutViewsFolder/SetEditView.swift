import SwiftUI
import CoreData

struct SetEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var set: SetEntity
    
    @State private var primaryMetricValue: String
    @State private var secondaryMetricValue: String
    @State private var notes: String
    @State private var selectedPrimaryMetricType: String
    @State private var selectedSecondaryMetricType: String
    @State private var selectedPrimaryMetricUnit: String
    @State private var selectedSecondaryMetricUnit: String
    
    let metricTypes = ["Weight", "Time", "Distance", "Reps", "Steps", "None"]
    let units = ["lbs", "kg", "minutes", "seconds", "miles", "km", "count", "steps"]
    
    init(set: SetEntity) {
        self.set = set
        _primaryMetricValue = State(initialValue: String(set.primaryMetricValue))
        _secondaryMetricValue = State(initialValue: String(set.secondaryMetricValue))
        _notes = State(initialValue: set.notes ?? "")
        _selectedPrimaryMetricType = State(initialValue: set.primaryMetricType ?? "None")
        _selectedSecondaryMetricType = State(initialValue: set.secondaryMetricType ?? "None")
        _selectedPrimaryMetricUnit = State(initialValue: set.primaryMetricUnit ?? "")
        _selectedSecondaryMetricUnit = State(initialValue: set.secondaryMetricUnit ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Primary Metric")) {
                Picker("Type", selection: $selectedPrimaryMetricType) {
                    ForEach(metricTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                if selectedPrimaryMetricType != "None" {
                    HStack {
                        TextField("Value", text: $primaryMetricValue)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $selectedPrimaryMetricUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Secondary Metric")) {
                Picker("Type", selection: $selectedSecondaryMetricType) {
                    ForEach(metricTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                if selectedSecondaryMetricType != "None" {
                    HStack {
                        TextField("Value", text: $secondaryMetricValue)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $selectedSecondaryMetricUnit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle("Edit Set")
        .navigationBarItems(trailing: Button("Save") {
            saveChanges()
        })
    }
    
    private func saveChanges() {
        set.primaryMetricType = selectedPrimaryMetricType
        set.secondaryMetricType = selectedSecondaryMetricType
        set.primaryMetricUnit = selectedPrimaryMetricUnit
        set.secondaryMetricUnit = selectedSecondaryMetricUnit
        set.primaryMetricValue = Double(primaryMetricValue) ?? 0
        set.secondaryMetricValue = Double(secondaryMetricValue) ?? 0
        set.notes = notes
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
