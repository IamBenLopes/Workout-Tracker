import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var workout: Workout
    @State private var isEditing = false
    @State private var showingMovementEntryView = false
    
    // Add state variables for editing
    @State private var workoutName: String
    @State private var prePainLevel: Int
    @State private var postPainLevel: Int
    @State private var workoutFocus: String
    @State private var postNotes: String
    
    init(workout: Workout) {
        self.workout = workout
        // Initialize state with current values
        _workoutName = State(initialValue: workout.workoutName ?? "")
        _prePainLevel = State(initialValue: Int(workout.prePainLevel))
        _postPainLevel = State(initialValue: Int(workout.postPainLevel))
        _workoutFocus = State(initialValue: workout.workoutFocus ?? "")
        _postNotes = State(initialValue: workout.postNotes ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                workoutHeaderSection
                
                Divider()
                    .padding(.horizontal)
                
                if isEditing {
                    editableWorkoutDetailsSection
                } else {
                    workoutDetailsSection
                }
                
                Divider()
                    .padding(.horizontal)
                
                movementLogsSection
            }
            .padding(.vertical)
        }
        .navigationBarTitle(workout.displayName, displayMode: .large)
        .navigationBarItems(trailing: 
            Button(action: {
                if isEditing {
                    saveChanges()
                }
                isEditing.toggle()
            }) {
                Text(isEditing ? "Done" : "Edit")
                    .fontWeight(.semibold)
            }
        )
        .sheet(isPresented: $showingMovementEntryView) {
            MovementEntryView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var workoutHeaderSection: some View {
        VStack(spacing: 8) {
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            if !isEditing {
                HStack(spacing: 16) {
                    workoutMetricView(
                        title: "Pre-Pain",
                        value: "\(workout.prePainLevel)",
                        icon: "arrow.down.heart",
                        color: painColor(level: Int(workout.prePainLevel))
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    workoutMetricView(
                        title: "Post-Pain",
                        value: "\(workout.postPainLevel)",
                        icon: "arrow.up.heart",
                        color: painColor(level: Int(workout.postPainLevel))
                    )
                    
                    if !workoutFocus.isEmpty {
                        Divider()
                            .frame(height: 40)
                        
                        workoutMetricView(
                            title: "Focus",
                            value: workout.workoutFocus ?? "",
                            icon: "figure.strengthtraining.traditional",
                            color: .blue
                        )
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
        }
    }
    
    // Non-editing mode workout details
    private var workoutDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let postNotes = workout.postNotes, !postNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Notes", systemImage: "note.text")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(postNotes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Editing mode workout details
    private var editableWorkoutDetailsSection: some View {
        VStack(spacing: 16) {
            GroupBox(label: Label("Workout Details", systemImage: "dumbbell")) {
                VStack(spacing: 12) {
                    TextField("Workout Name", text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 4)
                    
                    DatePicker("Date", selection: Binding(
                        get: { workout.date ?? Date() },
                        set: { workout.date = $0 }
                    ))
                    .datePickerStyle(.compact)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pre-Workout Pain Level: \(prePainLevel)")
                            .font(.subheadline)
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(prePainLevel) },
                                set: { prePainLevel = Int($0) }
                            ), in: 0...10, step: 1)
                            .accentColor(painColor(level: prePainLevel))
                            
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Post-Workout Pain Level: \(postPainLevel)")
                            .font(.subheadline)
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(postPainLevel) },
                                set: { postPainLevel = Int($0) }
                            ), in: 0...10, step: 1)
                            .accentColor(painColor(level: postPainLevel))
                            
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Picker("Workout Focus", selection: $workoutFocus) {
                        Text("None").tag("")
                        Text("Strength").tag("Strength")
                        Text("Hypertrophy").tag("Hypertrophy")
                        Text("Endurance").tag("Endurance")
                    }
                    .pickerStyle(.segmented)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Post-Workout Notes")
                            .font(.subheadline)
                        
                        TextEditor(text: $postNotes)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.bottom, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }
    }
    
    private func workoutMetricView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func painColor(level: Int) -> Color {
        switch level {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        case 7...10:
            return .red
        default:
            return .gray
        }
    }

    private var movementLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Movements", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingMovementEntryView = true
                }) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if workout.movementLogsArray.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No movements added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingMovementEntryView = true
                    }) {
                        Text("Add Your First Movement")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(Array(workout.movementLogsArray.enumerated()), id: \.element) { index, movementLog in
                    NavigationLink(destination: MovementLogEditView(movementLog: movementLog)) {
                        HStack {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.blue))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movementLog.movement?.name ?? "Unknown Movement")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(movementLog.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(movementLog.setsArray.count) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: deleteMovementLog)
            }
        }
    }

    private var formattedDate: String {
        workout.date?.formatted(date: .long, time: .shortened) ?? "Unknown Date"
    }

    private func saveChanges() {
        workout.workoutName = workoutName
        workout.prePainLevel = Int16(prePainLevel)
        workout.postPainLevel = Int16(postPainLevel)
        workout.workoutFocus = workoutFocus
        workout.postNotes = postNotes
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving workout changes: \(error)")
        }
    }
    
    private func deleteMovementLog(at offsets: IndexSet) {
        withAnimation {
            let sortedLogs = workout.sortedMovementLogs
            
            // Delete the logs
            for index in offsets {
                if index < sortedLogs.count {
                    let movementLogToDelete = sortedLogs[index]
                    workout.removeFromMovementLogs(movementLogToDelete)
                    viewContext.delete(movementLogToDelete)
                }
            }
            
            // Reorder remaining logs
            workout.reorderMovementLogs()
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting movement log: \(error)")
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct WorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let workout = Workout(context: context)
        workout.date = Date()
        workout.workoutName = "Sample Workout"
        workout.prePainLevel = 3
        workout.postPainLevel = 5
        workout.workoutFocus = "Strength"
        workout.postNotes = "This was a great workout session. I felt stronger than last time."
        
        return NavigationView {
            WorkoutDetailView(workout: workout)
                .environment(\.managedObjectContext, context)
        }
    }
}
