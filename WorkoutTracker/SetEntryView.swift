import SwiftUI
import CoreData
import UIKit
import AVFoundation

// Move extension outside the struct, at file scope
extension SetEntryView.Field {
    var isPrimaryMetric: Bool {
        switch self {
        case .primaryMetricValue, .primaryMetricValueLeft, .primaryMetricValueRight:
            return true
        case .secondaryMetricValue, .secondaryMetricValueLeft, .secondaryMetricValueRight:
            return false
        case .notes:
            return false
        }
    }
}

struct SetEntryView: View {
    // MARK: - Environment & Observed Objects
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var movementLog: MovementLog
    
    // Add a completion handler for dismissal
    var onFinish: (() -> Void)?
    
    // MARK: - State Variables
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

    // Split Metrics
    @State private var primaryMetricValueLeft = ""
    @State private var primaryMetricValueRight = ""
    @State private var secondaryMetricValueLeft = ""
    @State private var secondaryMetricValueRight = ""
    @State private var usePrimarySplitMetrics = false
    @State private var useSecondarySplitMetrics = false

    // Current SetEntity in editing
    @State private var currentSet: SetEntity?

    // Timer State
    @State private var timerValue: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var countdownSeconds: Int = 0
    @State private var audioPlayer: AVAudioPlayer?

    // Error Handling & Loading
    @State private var viewLoadError: String?
    @State private var showErrorAlert = false
    @State private var isLoading = true
    
    // Metric Type & Unit Options
    let metricTypes = ["Weight", "Time", "Distance", "Reps", "Steps", "None"]
    let units = ["lbs", "kg", "minutes", "seconds", "miles", "km", "count", "steps"]
    
    // Whether this view is creating a brand-new set or editing an existing set
    @State private var isNewSet: Bool
    
    // The fields we want to manage focus for
    enum Field: Hashable {
        case primaryMetricValue
        case primaryMetricValueLeft
        case primaryMetricValueRight
        case secondaryMetricValue
        case secondaryMetricValueLeft
        case secondaryMetricValueRight
        case notes
    }

    // MARK: - Init
    init(
        movementLog: MovementLog,
        currentSetIndex: Int = 0,
        isNewSet: Bool = false,
        onFinish: (() -> Void)? = nil
    ) {
        self._movementLog = ObservedObject(wrappedValue: movementLog)
        self._isNewSet = State(initialValue: isNewSet)
        self._currentSetIndex = State(initialValue: currentSetIndex)
        self.onFinish = onFinish
        
        // Any additional setup can go here,
        // but avoid fetching Core Data in init—do it in onAppear.
        // SwiftUI may initialize the view multiple times.
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let error = viewLoadError {
                // Error UI
                VStack(spacing: 16) {
                    Text("Error Loading Set Entry")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        retryLoading()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                            Section(header: headerView) {
                                // Content
                                VStack(spacing: 24) {
                                    // Metric Cards
                                    metricCard(
                                        title: "Performance Metric",
                                        isEnabled: $usePrimaryMetric,
                                        isSplit: $usePrimarySplitMetrics,
                                        splitLabel: "Split the metrics",
                                        metricType: $selectedPrimaryMetricType,
                                        metricUnit: $selectedPrimaryMetricUnit,
                                        value: $primaryMetricValue,
                                        leftValue: $primaryMetricValueLeft,
                                        rightValue: $primaryMetricValueRight,
                                        nextField: usePrimarySplitMetrics ? .primaryMetricValueRight : .secondaryMetricValue
                                    )
                                    
                                    metricCard(
                                        title: "Supporting Metric",
                                        isEnabled: $useSecondaryMetric,
                                        isSplit: $useSecondarySplitMetrics,
                                        splitLabel: "Split the metrics",
                                        metricType: $selectedSecondaryMetricType,
                                        metricUnit: $selectedSecondaryMetricUnit,
                                        value: $secondaryMetricValue,
                                        leftValue: $secondaryMetricValueLeft,
                                        rightValue: $secondaryMetricValueRight,
                                        nextField: useSecondarySplitMetrics ? .secondaryMetricValueRight : .notes
                                    )
                                    
                                    // Timer (if primary metric is Time)
                                    if selectedPrimaryMetricType == "Time" {
                                        timerCard
                                    }
                                    
                                    // Notes
                                    notesCard
                                    
                                    // Previous Workout
                                    if !previousWorkoutSets.isEmpty {
                                        previousWorkoutCard
                                    }
                                    
                                    // Movement Info
                                    movementInfoCard
                                    
                                    // Extra padding for bottom buttons
                                    Color.clear.frame(height: 100)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    
                    // Persistent Bottom Action Bar
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 16) {
                    Button(action: saveSet) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                        Text("Save Set")
                                }
                            .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(hasChanges() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!hasChanges())

                    Button(action: {
                        print("DEBUG: SetEntryView - Finish button tapped")
                        print("DEBUG: SetEntryView - Current workout date: \(movementLog.workout?.date?.description ?? "nil")")
                        print("DEBUG: SetEntryView - Is in active workout: \(isInActiveWorkout)")
                        saveSet()
                        
                        if isInActiveWorkout {
                            print("DEBUG: SetEntryView - In active workout, calling onFinish")
                            print("DEBUG: SetEntryView - onFinish closure exists: \(onFinish != nil)")
                            // Let the parent handle dismissing all layers—don't also dismiss here
                            DispatchQueue.main.async {
                                print("DEBUG: SetEntryView - Executing onFinish closure")
                                onFinish?()  // The parent's closure handles closing *all* sheets
                            }
                        } else {
                            print("DEBUG: SetEntryView - Not in active workout, dismissing view")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Finish")
                                }
                            .frame(maxWidth: .infinity)
                                .frame(height: 44)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                    }
                }
            }
        }
        .navigationBarHidden(true)  // Hide the navigation bar completely
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button(action: focusPreviousField) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!hasPreviousField)
                    
                    Button(action: focusNextField) {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(!hasNextField)
                    
                    Spacer()
                    
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
        .onAppear {
            if isLoading {
                loadInitialData()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text(movementLog.movement?.name ?? "Movement")
                .font(.title2)
                .fontWeight(.bold)
            
            navigationControls
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            Color(uiColor: .systemBackground)
                .ignoresSafeArea(edges: .top)
                .shadow(color: Color.black.opacity(0.1), radius: 3, y: 2)
        )
    }
    
    // Add helper function to get safe area top padding
    private func getSafeAreaTop() -> CGFloat {
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.top ?? 0
        } else {
            return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        }
    }
    
    // Update navigationControls to be more compact
    private var navigationControls: some View {
        HStack(spacing: 16) {
            Button(action: previousSet) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .foregroundColor(currentSetIndex > 0 ? .blue : .gray)
            }
            .disabled(currentSetIndex == 0)
            .frame(width: 44, height: 44)
            
            Text("Set \(currentSetNumber)")
                .font(.headline)
                .frame(width: 80)
            
            Button(action: nextSet) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(currentSetIndex < Int(highestSetNumber) ? .blue : .gray)
            }
            .disabled(currentSetIndex >= Int(highestSetNumber))
            .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Lifecycle Helpers
    private func loadInitialData() {
        isLoading = true
        
        // 1) Validate that the MovementLog has a context
        guard let context = movementLog.managedObjectContext else {
            viewLoadError = "No Core Data context available"
            showErrorAlert = true
            isLoading = false
            return
        }
        
        // 2) Validate Movement & Workout relationships
        guard let _ = movementLog.movement else {
            viewLoadError = "Movement not found in MovementLog"
            showErrorAlert = true
            isLoading = false
            return
        }
        
        guard let _ = movementLog.workout else {
            viewLoadError = "Workout not found in MovementLog"
            showErrorAlert = true
            isLoading = false
            return
        }
        
        // 3) Fetch existing sets
        do {
            let request: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "movementLog == %@", movementLog)
            request.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]
            
            let sets = try context.fetch(request)
            currentSets = sets
            
            // 4) Decide how to handle sets based on isNewSet and currentSetIndex
            if isNewSet {
                currentSetNumber = Int16(sets.count + 1)
                highestSetNumber = currentSetNumber
            } else if currentSetIndex < sets.count {
                let setToLoad = sets[currentSetIndex]
                loadExistingSet(setToLoad)
                } else {
                currentSetIndex = sets.count
                currentSetNumber = Int16(sets.count + 1)
                highestSetNumber = currentSetNumber
            }
            
            // 5) Fetch previous workout sets
            try fetchPreviousWorkoutSets()
            
            // 6) Load movement info
            loadMovementInfo()
            
            // 7) Focus the first metric field
            focusedField = .primaryMetricValue
            
        } catch {
            viewLoadError = error.localizedDescription
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    private func retryLoading() {
        viewLoadError = nil
        isLoading = true
        loadInitialData()
    }
    
    // MARK: - Subviews
    
    // Metric card
    private func metricCard(
        title: String,
        isEnabled: Binding<Bool>,
        isSplit: Binding<Bool>,
        splitLabel: String,
        metricType: Binding<String>,
        metricUnit: Binding<String>,
        value: Binding<String>,
        leftValue: Binding<String>,
        rightValue: Binding<String>,
        nextField: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with toggle
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled.wrappedValue ? .primary : .secondary)
                Spacer()
                Toggle("Enable \(title)", isOn: isEnabled)
                    .labelsHidden()
            }
            .frame(height: 44)
            
            if isEnabled.wrappedValue {
                VStack(spacing: 16) {
                    // Metric Type and Unit Selection
                    metricTypeUnitPicker(type: metricType, unit: metricUnit)
                        .padding(.horizontal, 8)
                    
                    // Split Toggle (disabled for time)
                    if metricType.wrappedValue != "Time" {
                        Toggle(splitLabel, isOn: isSplit)
                            .padding(.horizontal, 8)
                    }
                    
                    // Value Input Section
                    if isSplit.wrappedValue && metricType.wrappedValue != "Time" {
                        HStack(spacing: 16) {
                            metricTextField(value: leftValue, label: "Left", nextField: .primaryMetricValueRight)
                                .frame(maxWidth: .infinity)
                            metricTextField(value: rightValue, label: "Right", nextField: nextField)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        metricTextField(value: value, label: "Value", nextField: nextField)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isEnabled.wrappedValue)
            }
            }
            .padding()
            .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        )
        #if compiler(>=5.9)
        .onChange(of: metricType.wrappedValue) { oldValue, newValue in
            if newValue == "Time" {
                isSplit.wrappedValue = false
            }
        }
        #else
        .onChange(of: metricType.wrappedValue) { newValue in
            if newValue == "Time" {
                isSplit.wrappedValue = false
            }
        }
        #endif
    }
    
    private func metricTypeUnitPicker(type: Binding<String>, unit: Binding<String>) -> some View {
        HStack(spacing: 16) {
            // Type Picker
            Menu {
                ForEach(metricTypes, id: \.self) { metricType in
                    Button(action: {
                        type.wrappedValue = metricType
                        // Update unit when type changes
                        switch metricType {
                        case "Weight":
                            unit.wrappedValue = "lbs"
                        case "Distance":
                            unit.wrappedValue = "miles"
                        case "Reps", "Steps":
                            unit.wrappedValue = "count"
                        case "Time":
                            unit.wrappedValue = "minutes"
                        default:
                            unit.wrappedValue = "None"
                        }
                    }) {
                        HStack {
                            Text(metricType)
                            if type.wrappedValue == metricType {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(type.wrappedValue)
                    Image(systemName: "chevron.down")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
            }
            
            // Unit Picker (if applicable)
            if type.wrappedValue != "None" && type.wrappedValue != "Time" {
                Menu {
                    ForEach(units.filter { validUnit in
                        switch type.wrappedValue {
                        case "Weight":   return ["lbs", "kg"].contains(validUnit)
                        case "Distance": return ["miles", "km"].contains(validUnit)
                        case "Reps", "Steps": return ["count", "steps"].contains(validUnit)
                        default:         return false
                        }
                    }, id: \.self) { possibleUnit in
                        Button(action: {
                            unit.wrappedValue = possibleUnit
                        }) {
                            HStack {
                                Text(possibleUnit)
                                if unit.wrappedValue == possibleUnit {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(unit.wrappedValue)
                        Image(systemName: "chevron.down")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func metricTextField(value: Binding<String>, label: String, nextField: Field? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Group {
                if shouldShowTimeMetric(nextField: nextField, label: label) {
                    HStack(spacing: 8) {
                        // Minutes
                        HStack(spacing: 4) {
                            TextField("0", text: Binding(
                                get: {
                                    if let totalSeconds = Double(value.wrappedValue) {
                                        return String(format: "%02d", Int(totalSeconds) / 60)
                                    }
                                    return "00"
                                },
                                set: { newValue in
                                    let cleanValue = String(newValue.prefix(2))
                                    let minutes = min(Int(cleanValue) ?? 0, 99)
                                    let currentSeconds = Int(value.wrappedValue) ?? 0 % 60
                                    value.wrappedValue = "\(minutes * 60 + currentSeconds)"
                                    selectedMinutes = minutes
                                    countdownSeconds = minutes * 60 + currentSeconds
                                    timerValue = Double(countdownSeconds)
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 60)
                            .multilineTextAlignment(.trailing)
                            
                            Text("min")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                                
                        Text(":")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Seconds
                        HStack(spacing: 4) {
                            TextField("00", text: Binding(
                                get: {
                                    if let totalSeconds = Double(value.wrappedValue) {
                                        return String(format: "%02d", Int(totalSeconds) % 60)
                                    }
                                    return "00"
                                },
                                set: { newValue in
                                    let cleanValue = String(newValue.prefix(2))
                                    let currentMinutes = Int(value.wrappedValue) ?? 0 / 60
                                    let seconds = min(Int(cleanValue) ?? 0, 59)
                                    value.wrappedValue = "\(currentMinutes * 60 + seconds)"
                                    selectedSeconds = seconds
                                    countdownSeconds = currentMinutes * 60 + seconds
                                    timerValue = Double(countdownSeconds)
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 60)
                            .multilineTextAlignment(.trailing)
                            
                            Text("sec")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick preset buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([30, 45, 60, 90, 120], id: \.self) { seconds in
                                    Button(action: {
                                        value.wrappedValue = "\(seconds)"
                                        selectedMinutes = seconds / 60
                                        selectedSeconds = seconds % 60
                                        countdownSeconds = seconds
                                        timerValue = Double(seconds)
                                    }) {
                                        Text(formatTimePreset(seconds))
                                            .font(.subheadline)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(uiColor: .secondarySystemBackground))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .frame(height: 44)
                } else {
                    TextField(label, text: value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(minHeight: 44)
                        .submitLabel(nextField != nil ? .next : .done)
                        .onSubmit {
                            if let next = nextField {
                                focusedField = next
                            } else {
                                hideKeyboard()
                            }
                        }
                }
            }
        }
    }
    
    private func shouldShowTimeMetric(nextField: Field?, label: String) -> Bool {
        if let field = nextField {
            return field.isPrimaryMetric && selectedPrimaryMetricType == "Time"
        } else {
            return selectedPrimaryMetricType == "Time" && (label == "Value" || label.isEmpty)
        }
    }
    
    private func formatTimePreset(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
    
    private var timerCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Rest Timer")
                    .font(.headline)
                                    Spacer()
                if !isTimerRunning {
                    Button(action: {
                        showTimerPicker.toggle()
                    }) {
                        Image(systemName: "clock")
                            .font(.title3)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            
            // Timer Display
            Text(timerDisplay)
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(isTimerRunning ? .blue : .primary)
                .frame(height: 70)
            
            // Timer Controls
            HStack(spacing: 20) {
                // Start/Stop Button
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    HStack {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isTimerRunning ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(countdownSeconds == 0 && !isTimerRunning)
                
                // Reset Button
                Button(action: resetTimer) {
                        HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .disabled(countdownSeconds == 0 || isTimerRunning)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showTimerPicker) {
            TimerPickerView(minutes: $selectedMinutes, seconds: $selectedSeconds, onDone: {
                showTimerPicker = false
                countdownSeconds = (selectedMinutes * 60) + selectedSeconds
                timerValue = Double(countdownSeconds)
            })
        }
    }
    
    private struct TimerPickerView: View {
        @Binding var minutes: Int
        @Binding var seconds: Int
        let onDone: () -> Void
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Set Timer Duration")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack(spacing: 20) {
                        // Minutes Picker
                        VStack {
                            Text("Minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                            
                            Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Seconds Picker
                        VStack {
                            Text("Seconds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Seconds", selection: $seconds) {
                                ForEach(0...59, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                    }
                    .padding()
                    
                    // Quick Preset Buttons
                    HStack(spacing: 12) {
                        ForEach([30, 60, 90, 120], id: \.self) { seconds in
                            Button(action: {
                                minutes = seconds / 60
                                self.seconds = seconds % 60
                            }) {
                                Text("\(seconds)s")
                                    .frame(minWidth: 60)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Done") {
                        onDone()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
            RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }

    private var previousWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Workout")
                .font(.headline)
            
            ForEach(previousWorkoutSets.indices, id: \.self) { index in
                let set = previousWorkoutSets[index]
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let primary = set.primaryMetricType, primary != "None" {
                        HStack {
                            Text(primary)
                                .fontWeight(.medium)
                            Text(formatPreviousWorkoutPrimaryMetric(set))
                        }
                    }
                    
                    if let secondary = set.secondaryMetricType, secondary != "None" {
                        HStack {
                            Text(secondary)
                                .fontWeight(.medium)
                            Text(formatPreviousWorkoutSet(set))
                        }
                    }
                    
                    if let notes = set.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var movementInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Movement Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isEditingDescription {
                    TextEditor(text: $movementDescription)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text(movementDescription.isEmpty ? "No description available" : movementDescription)
                        .foregroundColor(movementDescription.isEmpty ? .secondary : .primary)
                }
                
                Button(isEditingDescription ? "Save Description" : "Edit Description") {
                    if isEditingDescription {
                        saveMovementDescription()
                    }
                    isEditingDescription.toggle()
                }
                .frame(height: 44)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Photo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let image = movementImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                } else {
                    Text("No photo available")
                        .foregroundColor(.secondary)
                }
                
                Button("Change Photo") {
                    showImagePicker = true
                }
                .frame(height: 44)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Data & Persistence
    
    private func saveSet() {
        guard let context = movementLog.managedObjectContext else {
            viewLoadError = "No context available to save"
            showErrorAlert = true
            return
        }
        
        let set: SetEntity
        if isNewSet {
            set = SetEntity(context: context)
            set.setNumber = Int16(currentSets.count + 1)
        } else {
            if let existingSet = currentSet {
                set = existingSet
            } else {
                set = SetEntity(context: context)
                set.setNumber = currentSetNumber
            }
        }
        
        updateSet(set)
        
        do {
            try context.save()
            try fetchCurrentSets()
            resetFields()
            
        } catch {
            viewLoadError = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func updateSet(_ set: SetEntity) {
        set.setNumber = currentSetNumber
        set.movementLog = movementLog
        set.date = Date()
        
        // Metric Types
        set.primaryMetricType = usePrimaryMetric ? selectedPrimaryMetricType : "None"
        set.secondaryMetricType = useSecondaryMetric ? selectedSecondaryMetricType : "None"
        
        // Units
        set.primaryMetricUnit = selectedPrimaryMetricUnit
        set.secondaryMetricUnit = selectedSecondaryMetricUnit
        
        // Notes
        set.notes = notes
        
        // Split flags
        set.usePrimarySplitMetrics = usePrimarySplitMetrics
        set.useSecondarySplitMetrics = useSecondarySplitMetrics
        
        // Primary Metric
        if usePrimaryMetric {
            if selectedPrimaryMetricType == "Time" {
                let totalSeconds = selectedMinutes * 60 + selectedSeconds
                if totalSeconds < 60 {
                    set.primaryMetricValue = Double(totalSeconds)
                    set.primaryMetricUnit = "seconds"
                } else {
                    set.primaryMetricValue = Double(totalSeconds) / 60.0
                    set.primaryMetricUnit = "minutes"
                }
            } else if usePrimarySplitMetrics {
                set.primaryMetricValueLeft = Double(primaryMetricValueLeft) ?? 0
                set.primaryMetricValueRight = Double(primaryMetricValueRight) ?? 0
            } else {
                set.primaryMetricValue = Double(primaryMetricValue) ?? 0
            }
        }
        
        // Secondary Metric
        if useSecondaryMetric {
            if useSecondarySplitMetrics {
                set.secondaryMetricValueLeft = Double(secondaryMetricValueLeft) ?? 0
                set.secondaryMetricValueRight = Double(secondaryMetricValueRight) ?? 0
            } else {
                set.secondaryMetricValue = Double(secondaryMetricValue) ?? 0
            }
        }
    }

    private func fetchCurrentSets() throws {
        guard let context = movementLog.managedObjectContext else {
            throw NSError(domain: "No context", code: 999, userInfo: nil)
        }
        
        let request: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
        request.predicate = NSPredicate(format: "movementLog == %@", movementLog)
        request.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]
        
        let sets = try context.fetch(request)
        currentSets = sets
        
        // After refreshing, set the index to the end so we can create a new set
        currentSetIndex = currentSets.count
        currentSetNumber = Int16(currentSetIndex + 1)
        highestSetNumber = currentSetNumber
    }
    
    private func loadExistingSet(_ set: SetEntity) {
        currentSet = set
        currentSetNumber = set.setNumber
        highestSetNumber = Int16(currentSets.count)
        
        selectedPrimaryMetricType = set.primaryMetricType ?? "Weight"
        selectedSecondaryMetricType = set.secondaryMetricType ?? "Reps"
        selectedPrimaryMetricUnit = set.primaryMetricUnit ?? "lbs"
        selectedSecondaryMetricUnit = set.secondaryMetricUnit ?? "count"
        notes = set.notes ?? ""
        
        usePrimaryMetric = (set.primaryMetricType != nil && set.primaryMetricType != "None")
        useSecondaryMetric = (set.secondaryMetricType != nil && set.secondaryMetricType != "None")
        
        usePrimarySplitMetrics = set.usePrimarySplitMetrics
        useSecondarySplitMetrics = set.useSecondarySplitMetrics
        
        // Primary
        if set.usePrimarySplitMetrics {
            primaryMetricValueLeft = String(set.primaryMetricValueLeft)
            primaryMetricValueRight = String(set.primaryMetricValueRight)
            primaryMetricValue = ""
        } else {
            primaryMetricValue = set.formattedPrimaryMetricValue
            primaryMetricValueLeft = ""
            primaryMetricValueRight = ""
        }
        
        // Secondary
        if set.useSecondarySplitMetrics {
            secondaryMetricValueLeft = String(set.secondaryMetricValueLeft)
            secondaryMetricValueRight = String(set.secondaryMetricValueRight)
            secondaryMetricValue = ""
        } else {
            secondaryMetricValue = set.formattedSecondaryMetricValue
            secondaryMetricValueLeft = ""
            secondaryMetricValueRight = ""
        }
        
        // Time-based
        if selectedPrimaryMetricType == "Time" {
            if let value = Double(primaryMetricValue) {
                let totalSeconds = Int(value * 60)
                selectedMinutes = totalSeconds / 60
                selectedSeconds = totalSeconds % 60
                timerValue = Double(totalSeconds)
                countdownSeconds = totalSeconds
            }
        }
    }
    
    private func fetchPreviousWorkoutSets() throws {
        guard let movement = movementLog.movement else { return }
        guard let currentWorkoutDate = movementLog.workout?.date else { return }

        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "workout.date", ascending: false)]
        request.predicate = NSPredicate(format: "movement == %@ AND workout.date < %@", movement, currentWorkoutDate as NSDate)
        request.fetchLimit = 1

            if let previousLog = try viewContext.fetch(request).first {
                let setRequest: NSFetchRequest<SetEntity> = SetEntity.fetchRequest()
                setRequest.sortDescriptors = [NSSortDescriptor(key: "setNumber", ascending: true)]
                setRequest.predicate = NSPredicate(format: "movementLog == %@", previousLog)
                previousWorkoutSets = try viewContext.fetch(setRequest)
        } else {
            previousWorkoutSets = []
        }
    }
    
    // MARK: - Navigation
    
    private func nextSet() {
        // If we have existing sets, move forward
        if currentSetIndex < currentSets.count - 1 {
            currentSetIndex += 1
            loadSet(at: currentSetIndex)
        } else if currentSetIndex == currentSets.count - 1 && !isNewSet {
            // Reached the end of existing sets, prepare a new set
            currentSetIndex = currentSets.count
            currentSetNumber = Int16(currentSets.count + 1)
            
            // Clear fields but preserve toggles
            resetFields()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = usePrimarySplitMetrics ? .primaryMetricValueLeft : .primaryMetricValue
        }
    }

    private func previousSet() {
        if currentSetIndex > 0 {
            currentSetIndex -= 1
            loadSet(at: currentSetIndex)
        }
    }
    
    private func loadSet(at index: Int) {
        guard index < currentSets.count else { return }
        let set = currentSets[index]
        loadExistingSet(set)
    }
    
    // MARK: - Helpers
    
    private func resetFields() {
        primaryMetricValue = ""
        primaryMetricValueLeft = ""
        primaryMetricValueRight = ""
        secondaryMetricValue = ""
        secondaryMetricValueLeft = ""
        secondaryMetricValueRight = ""
        notes = ""
        
        // Set focus to the appropriate field
        focusedField = usePrimarySplitMetrics ? .primaryMetricValueLeft : .primaryMetricValue
    }

    private func hasChanges() -> Bool {
        // If we haven’t loaded a set yet, or if isNewSet, allow saving
        guard currentSetIndex < currentSets.count else {
            return true
        }
            let currentSet = currentSets[currentSetIndex]
        
        // Compare fields to the set’s values
        if primaryMetricValue != currentSet.formattedPrimaryMetricValue { return true }
        if secondaryMetricValue != currentSet.formattedSecondaryMetricValue { return true }
        if notes != (currentSet.notes ?? "") { return true }
        if selectedPrimaryMetricType != (currentSet.primaryMetricType ?? "") { return true }
        if selectedSecondaryMetricType != (currentSet.secondaryMetricType ?? "") { return true }
        
        return false
    }

    private func loadMovementInfo() {
        movementDescription = movementLog.movement?.movementDescription ?? ""
        if let imageData = movementLog.movement?.movementPhoto,
           let image = UIImage(data: imageData) {
            movementImage = image
        } else {
            movementImage = nil
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
        guard let imageData = movementImage?.jpegData(compressionQuality: 0.8) else { return }
            movementLog.movement?.movementPhoto = imageData
            do {
                try viewContext.save()
            } catch {
                print("Failed to save movement image: \(error)")
        }
    }

    // MARK: - Timer
    private func startTimer() {
        guard countdownSeconds > 0 else { return }
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
                if countdownSeconds == 0 {
                playTimerEndSound()
                    stopTimer()
                }
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

    private func playTimerEndSound() {
        guard let soundURL = Bundle.main.url(forResource: "timer_end", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    
    // MARK: - Previous Workout Formatting
    private func formatPreviousWorkoutSet(_ set: SetEntity) -> String {
        if set.useSecondarySplitMetrics {
            return "\(set.secondaryMetricValueLeft)/\(set.secondaryMetricValueRight)"
            } else {
            return set.formattedSecondaryMetricValue
        }
    }
    
    private func formatPreviousWorkoutPrimaryMetric(_ set: SetEntity) -> String {
        if set.usePrimarySplitMetrics {
            return "\(set.primaryMetricValueLeft)/\(set.primaryMetricValueRight)"
            } else {
            return set.formattedPrimaryMetricValue
        }
    }
    
    // Add these properties to the main struct
    @State private var showTimerPicker = false
    
    // Add this computed property
    private var timerDisplay: String {
        let minutes = countdownSeconds / 60
        let seconds = countdownSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Add these helper properties and methods for keyboard navigation
    private var hasPreviousField: Bool {
        guard let current = focusedField else { return false }
        return getPreviousField(from: current) != nil
    }
    
    private var hasNextField: Bool {
        guard let current = focusedField else { return false }
        return getNextField(from: current) != nil
    }
    
    private func focusPreviousField() {
        guard let current = focusedField,
              let previous = getPreviousField(from: current) else { return }
        focusedField = previous
    }
    
    private func focusNextField() {
        guard let current = focusedField,
              let next = getNextField(from: current) else { return }
        focusedField = next
    }
    
    private func getPreviousField(from current: Field) -> Field? {
        let fields: [Field] = getOrderedFields()
        guard let index = fields.firstIndex(of: current), index > 0 else { return nil }
        return fields[index - 1]
    }
    
    private func getNextField(from current: Field) -> Field? {
        let fields: [Field] = getOrderedFields()
        guard let index = fields.firstIndex(of: current), index < fields.count - 1 else { return nil }
        return fields[index + 1]
    }
    
    private func getOrderedFields() -> [Field] {
        var fields: [Field] = []
        
        if usePrimaryMetric {
            if usePrimarySplitMetrics {
                fields.append(contentsOf: [.primaryMetricValueLeft, .primaryMetricValueRight])
        } else {
                fields.append(.primaryMetricValue)
            }
        }
        
        if useSecondaryMetric {
            if useSecondarySplitMetrics {
                fields.append(contentsOf: [.secondaryMetricValueLeft, .secondaryMetricValueRight])
            } else {
                fields.append(.secondaryMetricValue)
            }
        }
        
        fields.append(.notes)
        return fields
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Update bottom action bar with navigation functionality
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                Button(action: {
                    if let current = focusedField,
                       let previous = getPreviousField(from: current) {
                        focusedField = previous
                        hapticFeedback(.light)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(width: 44, height: 44)
                .foregroundColor(hasPreviousField ? .blue : .gray)
                .disabled(!hasPreviousField)
                
                Button(action: saveSet) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Set")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(hasChanges() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!hasChanges())
                
                Button(action: {
                    print("DEBUG: SetEntryView - Finish button tapped")
                    print("DEBUG: SetEntryView - Current workout date: \(movementLog.workout?.date?.description ?? "nil")")
                    print("DEBUG: SetEntryView - Is in active workout: \(isInActiveWorkout)")
                    saveSet()
                    
                    if isInActiveWorkout {
                        print("DEBUG: SetEntryView - In active workout, calling onFinish")
                        print("DEBUG: SetEntryView - onFinish closure exists: \(onFinish != nil)")
                        // Let the parent handle dismissing all layers—don't also dismiss here
                        DispatchQueue.main.async {
                            print("DEBUG: SetEntryView - Executing onFinish closure")
                            onFinish?()  // The parent's closure handles closing *all* sheets
                        }
                    } else {
                        print("DEBUG: SetEntryView - Not in active workout, dismissing view")
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Finish")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    if let current = focusedField,
                       let next = getNextField(from: current) {
                        focusedField = next
                        hapticFeedback(.light)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                }
                .frame(width: 44, height: 44)
                .foregroundColor(hasNextField ? .blue : .gray)
                .disabled(!hasNextField)
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
    }
    
    // Add haptic feedback function
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // Add property to check if we're in an active workout
    private var isInActiveWorkout: Bool {
        guard let workout = movementLog.workout else { return false }
        // A workout is considered active if it was created today
        if let workoutDate = workout.date {
            return Calendar.current.isDateInToday(workoutDate)
        }
        return false
    }
}
