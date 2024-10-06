import SwiftUI
import CoreData

struct SetEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var movementLog: MovementLog
    @State private var currentSetNumber: Int16 = 1
    @State private var primaryMetricValue = ""
    @State private var secondaryMetricValue = ""
    @State private var notes = ""
    @State private var currentSets: [SetEntity] = []
    @State private var previousWorkoutSets: [SetEntity] = []
    @State private var selectedPrimaryMetricType = "Weight"
    @State private var selectedSecondaryMetricType = "Reps"
    @State private var selectedPrimaryMetricUnit = "lbs"
    @State private var selectedSecondaryMetricUnit = "count"
    @State private var usePrimaryMetric = true
    @State private var useSecondaryMetric = true

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case primaryMetricValue
        case secondaryMetricValue
        case notes
    }

    let metricTypes = ["Weight", "Time", "Distance", "Reps", "Steps", "None"]
    let units = ["lbs", "kg", "minutes", "seconds", "miles", "km", "count", "steps"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("\(movementLog.movement?.name ?? "Movement") - Set \(currentSetNumber)")
                    .font(.headline)

                metricInputSection

                HStack(spacing: 15) {
                    Button(action: saveSet) {
                        Text("Save Set")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .lineLimit(1) // Prevents text from wrapping
                            .minimumScaleFactor(0.5) // Allows text to shrink if necessary
                    }

                    Button(action: {
                        saveSet()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Finish Movement")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .lineLimit(1) // Prevents text from wrapping
                            .minimumScaleFactor(0.5) // Allows text to shrink if necessary
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)



                if !previousWorkoutSets.isEmpty {
                    previousWorkoutSection
                }

                movementInfoSection
            }
            .padding()
        }
        .navigationTitle("Log Sets")
        .onAppear {
            fetchCurrentSets()
            fetchPreviousWorkoutSets()
            focusedField = .primaryMetricValue
        }
    }

    var metricInputSection: some View {
        VStack(spacing: 15) {
            Toggle("Use Primary Metric", isOn: $usePrimaryMetric)

            if usePrimaryMetric {
                metricInputGroup(
                    metricType: $selectedPrimaryMetricType,
                    metricValue: $primaryMetricValue,
                    metricUnit: $selectedPrimaryMetricUnit,
                    label: "Primary Metric",
                    field: .primaryMetricValue
                )
            }

            Toggle("Use Secondary Metric", isOn: $useSecondaryMetric)

            if useSecondaryMetric {
                metricInputGroup(
                    metricType: $selectedSecondaryMetricType,
                    metricValue: $secondaryMetricValue,
                    metricUnit: $selectedSecondaryMetricUnit,
                    label: "Secondary Metric",
                    field: .secondaryMetricValue
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .notes)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary, lineWidth: 1)
            )
        }
    }

    func metricInputGroup(metricType: Binding<String>, metricValue: Binding<String>, metricUnit: Binding<String>, label: String, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            HStack {
                Picker("", selection: metricType) {
                    ForEach(metricTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if metricType.wrappedValue != "None" {
                    TextField("Value", text: metricValue)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: field)

                    Picker("", selection: metricUnit) {
                        ForEach(units, id: \.self) { unit in
                            Text(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        )
    }

    var previousWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Previous Workout")
                .font(.headline)
            ForEach(previousWorkoutSets, id: \.self) { set in
                VStack(alignment: .leading) {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                    if let primary = set.primaryMetricType, primary != "None" {
                        Text("\(primary): \(set.formattedPrimaryMetricValue) \(set.primaryMetricUnit ?? "")")
                    }
                    if let secondary = set.secondaryMetricType, secondary != "None" {
                        Text("\(secondary): \(set.formattedSecondaryMetricValue) \(set.secondaryMetricUnit ?? "")")
                    }
                    if let notes = set.notes, !notes.isEmpty {
                        Text("Notes: \(notes)")
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        )
    }

    var movementInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = movementLog.movement?.movementDescription, !description.isEmpty {
                Text("Movement Description:")
                    .font(.headline)
                Text(description)
                    .padding(.bottom)
            }

            if let imageData = movementLog.movement?.movementPhoto,
               let uiImage = UIImage(data: imageData) {
                Text("Movement Photo:")
                    .font(.headline)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        )
        .padding(.vertical)
    }

    // Save the current set to Core Data
    private func saveSet() {
        let newSet = SetEntity(context: viewContext)
        newSet.setNumber = currentSetNumber
        newSet.primaryMetricType = usePrimaryMetric ? selectedPrimaryMetricType : "None"
        newSet.primaryMetricUnit = selectedPrimaryMetricUnit
        newSet.secondaryMetricType = useSecondaryMetric ? selectedSecondaryMetricType : "None"
        newSet.secondaryMetricUnit = selectedSecondaryMetricUnit
        newSet.notes = notes
        newSet.movementLog = movementLog

        if usePrimaryMetric {
            newSet.primaryMetricValue = Double(primaryMetricValue) ?? 0
        }

        if useSecondaryMetric {
            newSet.secondaryMetricValue = Double(secondaryMetricValue) ?? 0
        }

        do {
            try viewContext.save()
            // Clear inputs for the next set
            resetFields()
            // Increment set number
            currentSetNumber += 1
            // Refresh current sets
            fetchCurrentSets()
            // Set focus to primary metric value
            focusedField = .primaryMetricValue
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }

    private func resetFields() {
        primaryMetricValue = ""
        secondaryMetricValue = ""
        notes = ""
    }

    // Fetch current sets
    private func fetchCurrentSets() {
        let request: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
        request.predicate = NSPredicate(format: "movementLog == %@", movementLog)
        request.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]

        do {
            currentSets = try viewContext.fetch(request)
            currentSetNumber = Int16(currentSets.count + 1)
        } catch {
            print("Failed to fetch current sets: \(error.localizedDescription)")
        }
    }

    // Fetch previous workout sets
    private func fetchPreviousWorkoutSets() {
        guard let movement = movementLog.movement,
              let currentWorkoutDate = movementLog.workout?.date else { return }

        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "workout.date", ascending: false)]
        request.predicate = NSPredicate(format: "movement == %@ AND workout.date < %@", movement, currentWorkoutDate as NSDate)
        request.fetchLimit = 1

        do {
            if let previousLog = try viewContext.fetch(request).first {
                let setRequest: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
                setRequest.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]
                setRequest.predicate = NSPredicate(format: "movementLog == %@", previousLog)
                previousWorkoutSets = try viewContext.fetch(setRequest)
            }
        } catch {
            print("Error fetching previous sets: \(error)")
        }
    }
}
