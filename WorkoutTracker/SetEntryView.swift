import SwiftUI
import CoreData
import UIKit

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
    @State private var currentSetIndex: Int = 0
    @State private var movementDescription: String = ""
    @State private var movementImage: UIImage?
    @State private var showImagePicker = false
    @State private var isEditingDescription = false
    @State private var highestSetNumber: Int16 = 1

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
                Text(movementLog.movement?.name ?? "Movement")
                    .font(.headline)
                
                navigationControls
                
                metricInputSection

                HStack(spacing: 15) {
                    Button(action: saveSet) {
                        Text("Save Set")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .disabled(!hasChanges())

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
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
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
            loadMovementInfo()
            focusedField = .primaryMetricValue
        }
    }

    var navigationControls: some View {
        HStack {
            Button(action: previousSet) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentSetIndex > 0 ? .blue : .gray)
            }
            .disabled(currentSetIndex == 0)
            
            Text("Set \(currentSetNumber)")
                .font(.headline)
                .frame(width: 100)
            
            Button(action: nextSet) {
                Image(systemName: "chevron.right")
                    .foregroundColor(currentSetIndex < highestSetNumber ? .blue : .gray)
            }
            .disabled(currentSetIndex >= highestSetNumber)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Movement Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description:")
                    .font(.subheadline)
                    .bold()
                
                if isEditingDescription {
                    TextEditor(text: $movementDescription)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                } else {
                    Text(movementDescription.isEmpty ? "No description available" : movementDescription)
                        .foregroundColor(movementDescription.isEmpty ? .gray : .primary)
                }
                
                Button(isEditingDescription ? "Save Description" : "Edit Description") {
                    if isEditingDescription {
                        saveMovementDescription()
                    }
                    isEditingDescription.toggle()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Photo:")
                    .font(.subheadline)
                    .bold()
                
                if let image = movementImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("No photo available")
                        .foregroundColor(.gray)
                }
                
                Button("Change Photo") {
                    showImagePicker = true
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        .sheet(isPresented: $showImagePicker, onDismiss: saveMovementImage) {
            ImagePicker(image: $movementImage)
        }
    }

    // Save the current set to Core Data
    private func saveSet() {
        if currentSetIndex < currentSets.count {
            // Update existing set
            updateSet(currentSets[currentSetIndex])
        } else {
            // Create new set
            let newSet = SetEntity(context: viewContext)
            updateSet(newSet)
            currentSets.append(newSet)
        }

        do {
            try viewContext.save()
            // Update highest set number if necessary
            highestSetNumber = max(highestSetNumber, currentSetNumber)
            
            // Always move to the next set after saving
            if currentSetIndex == currentSets.count - 1 {
                // If we're at the last set, prepare for a new one
                currentSetIndex = currentSets.count
                currentSetNumber = highestSetNumber + 1
                highestSetNumber = currentSetNumber
                resetFields()
            } else {
                // Move to the next existing set
                currentSetIndex += 1
                loadSet(at: currentSetIndex)
            }
            
            focusedField = .primaryMetricValue
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }

    private func updateSet(_ set: SetEntity) {
        set.setNumber = Int16(currentSetIndex + 1)
        set.primaryMetricType = usePrimaryMetric ? selectedPrimaryMetricType : "None"
        set.primaryMetricUnit = selectedPrimaryMetricUnit
        set.secondaryMetricType = useSecondaryMetric ? selectedSecondaryMetricType : "None"
        set.secondaryMetricUnit = selectedSecondaryMetricUnit
        set.notes = notes
        set.movementLog = movementLog

        if usePrimaryMetric {
            set.primaryMetricValue = Double(primaryMetricValue) ?? 0
        }

        if useSecondaryMetric {
            set.secondaryMetricValue = Double(secondaryMetricValue) ?? 0
        }
    }

    private func nextSet() {
        if currentSetIndex < currentSets.count - 1 {
            currentSetIndex += 1
            loadSet(at: currentSetIndex)
        } else if currentSetIndex == currentSets.count - 1 {
            // Prepare for a new set
            currentSetIndex = currentSets.count
            currentSetNumber = highestSetNumber + 1
            highestSetNumber = currentSetNumber
            resetFields()
        }
    }

    private func loadSet(at index: Int) {
        let set = currentSets[index]
        currentSetNumber = set.setNumber
        primaryMetricValue = set.formattedPrimaryMetricValue
        secondaryMetricValue = set.formattedSecondaryMetricValue
        notes = set.notes ?? ""
        selectedPrimaryMetricType = set.primaryMetricType ?? "None"
        selectedSecondaryMetricType = set.secondaryMetricType ?? "None"
        selectedPrimaryMetricUnit = set.primaryMetricUnit ?? ""
        selectedSecondaryMetricUnit = set.secondaryMetricUnit ?? ""
        usePrimaryMetric = selectedPrimaryMetricType != "None"
        useSecondaryMetric = selectedSecondaryMetricType != "None"
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
            currentSetIndex = currentSets.count
            currentSetNumber = Int16(currentSetIndex + 1)
            highestSetNumber = currentSetNumber
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

    private func previousSet() {
        if currentSetIndex > 0 {
            currentSetIndex -= 1
            loadSet(at: currentSetIndex)
        }
    }

    private func hasChanges() -> Bool {
        if currentSetIndex < currentSets.count {
            let currentSet = currentSets[currentSetIndex]
            return primaryMetricValue != currentSet.formattedPrimaryMetricValue ||
                   secondaryMetricValue != currentSet.formattedSecondaryMetricValue ||
                   notes != (currentSet.notes ?? "") ||
                   selectedPrimaryMetricType != (currentSet.primaryMetricType ?? "") ||
                   selectedSecondaryMetricType != (currentSet.secondaryMetricType ?? "")
        }
        return true // Always allow saving for new sets
    }

    private func loadMovementInfo() {
        movementDescription = movementLog.movement?.movementDescription ?? ""
        if let imageData = movementLog.movement?.movementPhoto,
           let image = UIImage(data: imageData) {
            movementImage = image
        }
    }

    private func saveMovementDescription() {
        movementLog.movement?.movementDescription = movementDescription
        do {
            try viewContext.save()
        } catch {
            print("Failed to save movement description: \(error)")
        }
    }

    private func saveMovementImage() {
        if let imageData = movementImage?.jpegData(compressionQuality: 0.8) {
            movementLog.movement?.movementPhoto = imageData
            do {
                try viewContext.save()
            } catch {
                print("Failed to save movement image: \(error)")
            }
        }
    }
}