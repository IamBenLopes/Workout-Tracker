import SwiftUI
import CoreData
import UIKit
import AVFoundation

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

    @State private var primaryMetricValueLeft = ""
    @State private var primaryMetricValueRight = ""
    @State private var secondaryMetricValueLeft = ""
    @State private var secondaryMetricValueRight = ""
    @State private var usePrimarySplitMetrics = false
    @State private var useSecondarySplitMetrics = false

    @State private var currentSet: SetEntity?

    @State private var timerValue: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    @State private var countdownSeconds: Int = 0

    @State private var audioPlayer: AVAudioPlayer?

    enum Field: Hashable {
        case primaryMetricValue
        case primaryMetricValueLeft
        case primaryMetricValueRight
        case secondaryMetricValue
        case secondaryMetricValueLeft
        case secondaryMetricValueRight
        case notes
    }

    let metricTypes = ["Weight", "Time", "Distance", "Reps", "Steps", "None"]
    let units = ["lbs", "kg", "minutes", "seconds", "miles", "km", "count", "steps"]

    let isNewSet: Bool

    init(movementLog: MovementLog, currentSetIndex: Int = 0, isNewSet: Bool = false) {
        print("\nSetEntryView Initializer Debug:")
        print("Requested Set Index: \(currentSetIndex)")
        print("Is New Set: \(isNewSet)")
        
        self.movementLog = movementLog
        self.isNewSet = isNewSet
        _currentSetIndex = State(initialValue: currentSetIndex)
        
        // Fetch current sets
        let request: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
        request.predicate = NSPredicate(format: "movementLog == %@", movementLog)
        request.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]
        
        if let sets = try? movementLog.managedObjectContext?.fetch(request) {
            _currentSets = State(initialValue: sets)
            
            if isNewSet {
                // For new sets, use the next available set number
                _currentSetNumber = State(initialValue: Int16(sets.count + 1))
                _highestSetNumber = State(initialValue: Int16(sets.count + 1))
            } else if currentSetIndex < sets.count {
                // For existing sets, use the actual set number
                let set = sets[currentSetIndex]
                _currentSet = State(initialValue: set)
                _currentSetNumber = State(initialValue: set.setNumber)
                _highestSetNumber = State(initialValue: Int16(sets.count))
                
                // Load existing set values
                _selectedPrimaryMetricType = State(initialValue: set.primaryMetricType ?? "Weight")
                _selectedSecondaryMetricType = State(initialValue: set.secondaryMetricType ?? "Reps")
                _selectedPrimaryMetricUnit = State(initialValue: set.primaryMetricUnit ?? "lbs")
                _selectedSecondaryMetricUnit = State(initialValue: set.secondaryMetricUnit ?? "count")
                _notes = State(initialValue: set.notes ?? "")
                
                // Load metric values
                if set.usePrimarySplitMetrics {
                    _primaryMetricValueLeft = State(initialValue: String(set.primaryMetricValueLeft))
                    _primaryMetricValueRight = State(initialValue: String(set.primaryMetricValueRight))
                } else {
                    _primaryMetricValue = State(initialValue: set.formattedPrimaryMetricValue)
                }
                
                if set.useSecondarySplitMetrics {
                    _secondaryMetricValueLeft = State(initialValue: String(set.secondaryMetricValueLeft))
                    _secondaryMetricValueRight = State(initialValue: String(set.secondaryMetricValueRight))
                } else {
                    _secondaryMetricValue = State(initialValue: set.formattedSecondaryMetricValue)
                }
                
                print("Loaded existing set \(set.setNumber)")
                print("Primary Split: \(set.usePrimarySplitMetrics)")
                print("Secondary Split: \(set.useSecondarySplitMetrics)")
            }
        }
    }

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
            
            // Show the actual set number being edited
            Text("Set \(currentSetNumber)")
                .font(.headline)
                .frame(width: 100)
            
            Button(action: nextSet) {
                Image(systemName: "chevron.right")
                    .foregroundColor(currentSetIndex < Int(highestSetNumber) ? .blue : .gray)
            }
            .disabled(currentSetIndex >= Int(highestSetNumber))
        }
    }

    var metricInputSection: some View {
        VStack(spacing: 15) {
            Toggle("Use Primary Metric", isOn: $usePrimaryMetric)

            if usePrimaryMetric {
                Toggle("Split Primary Metric (Left/Right)", isOn: $usePrimarySplitMetrics)
                    .padding(.leading)
                
                if usePrimarySplitMetrics {
                    Group {
                        metricInputGroup(
                            metricType: $selectedPrimaryMetricType,
                            metricValue: $primaryMetricValueLeft,
                            metricUnit: $selectedPrimaryMetricUnit,
                            label: "Primary Metric (Left)",
                            field: .primaryMetricValueLeft
                        )
                        
                        metricInputGroup(
                            metricType: $selectedPrimaryMetricType,
                            metricValue: $primaryMetricValueRight,
                            metricUnit: $selectedPrimaryMetricUnit,
                            label: "Primary Metric (Right)",
                            field: .primaryMetricValueRight
                        )
                    }
                } else {
                    metricInputGroup(
                        metricType: $selectedPrimaryMetricType,
                        metricValue: $primaryMetricValue,
                        metricUnit: $selectedPrimaryMetricUnit,
                        label: "Primary Metric",
                        field: .primaryMetricValue
                    )
                }
            }

            Toggle("Use Secondary Metric", isOn: $useSecondaryMetric)

            if useSecondaryMetric {
                Toggle("Split Secondary Metric (Left/Right)", isOn: $useSecondarySplitMetrics)
                    .padding(.leading)
                
                if useSecondarySplitMetrics {
                    Group {
                        metricInputGroup(
                            metricType: $selectedSecondaryMetricType,
                            metricValue: $secondaryMetricValueLeft,
                            metricUnit: $selectedSecondaryMetricUnit,
                            label: "Secondary Metric (Left)",
                            field: .secondaryMetricValueLeft
                        )
                        
                        metricInputGroup(
                            metricType: $selectedSecondaryMetricType,
                            metricValue: $secondaryMetricValueRight,
                            metricUnit: $selectedSecondaryMetricUnit,
                            label: "Secondary Metric (Right)",
                            field: .secondaryMetricValueRight
                        )
                    }
                } else {
                    metricInputGroup(
                        metricType: $selectedSecondaryMetricType,
                        metricValue: $secondaryMetricValue,
                        metricUnit: $selectedSecondaryMetricUnit,
                        label: "Secondary Metric",
                        field: .secondaryMetricValue
                    )
                }
            }

            // Add timer view when primary metric is Time
            if selectedPrimaryMetricType == "Time" {
                timerView
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
                .onChange(of: metricType.wrappedValue) { oldValue, newValue in
                    if newValue == "Time" {
                        onPrimaryMetricTypeChange()
                    }
                }

                if metricType.wrappedValue != "None" {
                    if metricType.wrappedValue == "Time" {
                        // Time picker wheels
                        HStack {
                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            
                            Text(":")
                                .font(.title2)
                                .padding(.horizontal, 4)
                            
                            Picker("Seconds", selection: $selectedSeconds) {
                                ForEach(0...59, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                        }
                        .onChange(of: selectedMinutes) { _, newValue in
                            updateTimerFromPickers()
                        }
                        .onChange(of: selectedSeconds) { _, newValue in
                            updateTimerFromPickers()
                        }
                    } else {
                        // Regular numeric input for non-time metrics
                        TextField("Value", text: metricValue)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: field)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Next") {
                                        moveToNextField(from: field)
                                    }
                                }
                            }

                        if metricType.wrappedValue != "Time" {
                            Picker("", selection: metricUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
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
        print("\nSaving Set Debug:")
        
        let set: SetEntity
        if isNewSet {
            set = SetEntity(context: viewContext)
            set.setNumber = Int16(currentSets.count + 1)
        } else {
            set = currentSet ?? SetEntity(context: viewContext)
        }
        
        updateSet(set)
        
        do {
            try viewContext.save()
            fetchCurrentSets()
            
            // Clear values but maintain settings
            primaryMetricValue = ""
            primaryMetricValueLeft = ""
            primaryMetricValueRight = ""
            secondaryMetricValue = ""
            secondaryMetricValueLeft = ""
            secondaryMetricValueRight = ""
            notes = ""
            
            if isNewSet {
                currentSetNumber = Int16(currentSets.count + 1)
            } else {
                if currentSetIndex < currentSets.count - 1 {
                    currentSetIndex += 1
                    loadSet(at: currentSetIndex)
                } else {
                    currentSetIndex = currentSets.count
                    currentSetNumber = Int16(currentSets.count + 1)
                }
            }
            
            // Set focus to the appropriate primary metric field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if usePrimarySplitMetrics {
                    focusedField = .primaryMetricValueLeft
                } else {
                    focusedField = .primaryMetricValue
                }
            }
            
        } catch {
            print("Failed to save set: \(error.localizedDescription)")
        }
    }

    private func updateSet(_ set: SetEntity) {
        print("\nUpdating Set Debug:")
        print("Set Number: \(currentSetNumber)")
        print("Using Primary Split: \(usePrimarySplitMetrics)")
        print("Using Secondary Split: \(useSecondarySplitMetrics)")
        
        set.setNumber = currentSetNumber
        set.primaryMetricType = usePrimaryMetric ? selectedPrimaryMetricType : "None"
        set.primaryMetricUnit = selectedPrimaryMetricUnit
        set.secondaryMetricType = useSecondaryMetric ? selectedSecondaryMetricType : "None"
        set.secondaryMetricUnit = selectedSecondaryMetricUnit
        set.notes = notes
        set.movementLog = movementLog
        
        // Save split metrics flags
        set.usePrimarySplitMetrics = usePrimarySplitMetrics
        set.useSecondarySplitMetrics = useSecondarySplitMetrics
        
        if usePrimaryMetric {
            if usePrimarySplitMetrics {
                print("Saving Primary Split Values - Left: \(primaryMetricValueLeft), Right: \(primaryMetricValueRight)")
                set.primaryMetricValueLeft = Double(primaryMetricValueLeft) ?? 0
                set.primaryMetricValueRight = Double(primaryMetricValueRight) ?? 0
            } else {
                print("Saving Primary Combined Value: \(primaryMetricValue)")
                set.primaryMetricValue = Double(primaryMetricValue) ?? 0
            }
        }
        
        if useSecondaryMetric {
            if useSecondarySplitMetrics {
                print("Saving Secondary Split Values - Left: \(secondaryMetricValueLeft), Right: \(secondaryMetricValueRight)")
                set.secondaryMetricValueLeft = Double(secondaryMetricValueLeft) ?? 0
                set.secondaryMetricValueRight = Double(secondaryMetricValueRight) ?? 0
            } else {
                print("Saving Secondary Combined Value: \(secondaryMetricValue)")
                set.secondaryMetricValue = Double(secondaryMetricValue) ?? 0
            }
        }
    }

    private func nextSet() {
        if currentSetIndex < currentSets.count - 1 {
            currentSetIndex += 1
            loadSet(at: currentSetIndex)
        } else if currentSetIndex == currentSets.count - 1 && !isNewSet {
            currentSetIndex = currentSets.count
            currentSetNumber = Int16(currentSets.count + 1)
            
            // Clear values but maintain settings
            primaryMetricValue = ""
            primaryMetricValueLeft = ""
            primaryMetricValueRight = ""
            secondaryMetricValue = ""
            secondaryMetricValueLeft = ""
            secondaryMetricValueRight = ""
            notes = ""
        }
        
        // Set focus to the appropriate primary metric field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if usePrimarySplitMetrics {
                focusedField = .primaryMetricValueLeft
            } else {
                focusedField = .primaryMetricValue
            }
        }
    }

    private func loadSet(at index: Int) {
        print("\nLoadSet Debug:")
        print("Loading set at index: \(index)")
        
        guard index < currentSets.count else {
            print("Error: Index out of bounds")
            return
        }
        
        let set = currentSets[index]
        print("Set Number: \(set.setNumber)")
        print("Primary Split: \(set.usePrimarySplitMetrics)")
        print("Secondary Split: \(set.useSecondarySplitMetrics)")
        
        currentSetNumber = set.setNumber
        selectedPrimaryMetricType = set.primaryMetricType ?? "None"
        selectedSecondaryMetricType = set.secondaryMetricType ?? "None"
        selectedPrimaryMetricUnit = set.primaryMetricUnit ?? ""
        selectedSecondaryMetricUnit = set.secondaryMetricUnit ?? ""
        notes = set.notes ?? ""
        usePrimaryMetric = selectedPrimaryMetricType != "None"
        useSecondaryMetric = selectedSecondaryMetricType != "None"
        
        // Load split metrics settings
        usePrimarySplitMetrics = set.usePrimarySplitMetrics
        useSecondarySplitMetrics = set.useSecondarySplitMetrics
        
        if usePrimarySplitMetrics {
            primaryMetricValueLeft = String(set.primaryMetricValueLeft)
            primaryMetricValueRight = String(set.primaryMetricValueRight)
            primaryMetricValue = "" // Clear combined value
        } else {
            primaryMetricValue = set.formattedPrimaryMetricValue
            primaryMetricValueLeft = ""  // Clear split values
            primaryMetricValueRight = ""
        }
        
        if useSecondarySplitMetrics {
            secondaryMetricValueLeft = String(set.secondaryMetricValueLeft)
            secondaryMetricValueRight = String(set.secondaryMetricValueRight)
            secondaryMetricValue = "" // Clear combined value
        } else {
            secondaryMetricValue = set.formattedSecondaryMetricValue
            secondaryMetricValueLeft = ""  // Clear split values
            secondaryMetricValueRight = ""
        }
        
        print("Loaded Values:")
        print("Primary: \(primaryMetricValue)")
        print("Primary Left: \(primaryMetricValueLeft)")
        print("Primary Right: \(primaryMetricValueRight)")
        print("Secondary: \(secondaryMetricValue)")
        print("Secondary Left: \(secondaryMetricValueLeft)")
        print("Secondary Right: \(secondaryMetricValueRight)")
    }

    private func resetFields() {
        // Clear values but preserve split metric settings
        primaryMetricValue = ""
        primaryMetricValueLeft = ""
        primaryMetricValueRight = ""
        secondaryMetricValue = ""
        secondaryMetricValueLeft = ""
        secondaryMetricValueRight = ""
        notes = ""
        
        // Don't reset metric types, units, or split settings
        // Keep usePrimarySplitMetrics and useSecondarySplitMetrics as is
        
        // Set focus to the appropriate primary metric field
        if usePrimarySplitMetrics {
            focusedField = .primaryMetricValueLeft
        } else {
            focusedField = .primaryMetricValue
        }
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

    // Add timer functions
    private func startTimer() {
        isTimerRunning = true
        countdownSeconds = Int(timerValue)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                stopTimer()
                playTimerEndSound()
            }
        }
    }

    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        countdownSeconds = Int(timerValue)
    }

    // Update when primary metric type changes
    private func onPrimaryMetricTypeChange() {
        if selectedPrimaryMetricType == "Time" {
            selectedPrimaryMetricUnit = "minutes"
            // Convert existing value to time if needed
            if let value = Double(primaryMetricValue) {
                let totalSeconds = Int(value * 60)
                selectedMinutes = totalSeconds / 60
                selectedSeconds = totalSeconds % 60
                timerValue = Double(totalSeconds)
            } else {
                selectedMinutes = 0
                selectedSeconds = 0
                timerValue = 0
            }
        }
    }

    // Add function to handle field navigation
    private func moveToNextField(from currentField: Field) {
        switch currentField {
        case .primaryMetricValue:
            if useSecondaryMetric {
                focusedField = useSecondarySplitMetrics ? .secondaryMetricValueLeft : .secondaryMetricValue
            } else {
                focusedField = .notes
            }
        case .primaryMetricValueLeft:
            focusedField = .primaryMetricValueRight
        case .primaryMetricValueRight:
            if useSecondaryMetric {
                focusedField = useSecondarySplitMetrics ? .secondaryMetricValueLeft : .secondaryMetricValue
            } else {
                focusedField = .notes
            }
        case .secondaryMetricValue:
            focusedField = .notes
        case .secondaryMetricValueLeft:
            focusedField = .secondaryMetricValueRight
        case .secondaryMetricValueRight:
            focusedField = .notes
        case .notes:
            focusedField = nil
        }
    }

    // Add the timer view
    private var timerView: some View {
        VStack(spacing: 10) {
            Text("Timer")
                .font(.headline)
            
            // Only show the countdown display
            Text(String(format: "%02d:%02d", countdownSeconds / 60, countdownSeconds % 60))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(isTimerRunning ? .red : .primary)
            
            HStack(spacing: 20) {
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "Stop" : "Start")
                        .frame(width: 80)
                        .padding()
                        .background(isTimerRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: resetTimer) {
                    Text("Reset")
                        .frame(width: 80)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isTimerRunning)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        )
    }

    // Add function to update timer value from pickers
    private func updateTimerFromPickers() {
        timerValue = Double(selectedMinutes * 60 + selectedSeconds)
        
        // Format the primary metric value based on the total time
        let totalSeconds = selectedMinutes * 60 + selectedSeconds
        if totalSeconds < 60 {
            primaryMetricValue = "\(totalSeconds)"
            selectedPrimaryMetricUnit = "seconds"
        } else {
            primaryMetricValue = String(format: "%.2f", Double(totalSeconds) / 60.0)
            selectedPrimaryMetricUnit = "minutes"
        }
    }

    // Add function to play sound when timer ends
    private func playTimerEndSound() {
        guard let soundURL = Bundle.main.url(forResource: "timer_end", withExtension: "mp3") else {
            // If sound file not found, use system sound as fallback
            AudioServicesPlaySystemSound(1005) // iOS system sound
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play() // Remove try since play() is not throwing
        } catch {
            print("Failed to play timer end sound: \(error)")
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005)
        }
    }
}
