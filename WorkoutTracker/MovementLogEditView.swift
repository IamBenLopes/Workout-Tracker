import SwiftUI
import CoreData

struct MovementLogEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var movementLog: MovementLog
    @State private var showSetEntry = false
    @State private var showDeleteConfirmation = false
    @State private var setToDelete: SetEntity?
    @State private var logDate: Date
    @State private var showingDeleteAlert = false
    
    init(movementLog: MovementLog) {
        self.movementLog = movementLog
        _logDate = State(initialValue: movementLog.date ?? Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Movement header card
                movementHeaderCard
                
                // Sets section
                setsCard
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle(movementLog.movement?.name ?? "Movement")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete Movement", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showSetEntry) {
            SetEntryView(
                movementLog: movementLog
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Set"),
                message: Text("Are you sure you want to delete this set?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let set = setToDelete {
                        viewContext.delete(set)
                        saveContext()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Delete Movement", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMovementLog()
            }
        } message: {
            Text("Are you sure you want to delete this movement and all its sets? This action cannot be undone.")
        }
    }
    
    private var movementHeaderCard: some View {
        VStack(spacing: 16) {
            // Movement info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        title: { Text(movementLog.movement?.name ?? "Unknown Movement").font(.headline) },
                        icon: { Image(systemName: "figure.strengthtraining.traditional").foregroundColor(.blue) }
                    )
                    
                    if let muscleGroups = movementLog.movement?.muscleGroups as? Set<MuscleGroup>, !muscleGroups.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.arms.open")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(muscleGroups.compactMap { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(movementLog.setsArray.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
            
            // Date picker
            DatePicker("Date & Time", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .onChange(of: logDate) { oldValue, newValue in
                    movementLog.date = newValue
                    saveContext()
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    private var setsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Sets", systemImage: "list.number")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showSetEntry = true
                }) {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if movementLog.setsArray.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No sets recorded yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showSetEntry = true
                    }) {
                        Text("Add Your First Set")
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Sets list
                ForEach(movementLog.setsArray) { set in
                    NavigationLink {
                        SetEntryView(
                            movementLog: movementLog
                        )
                        .id(set.objectID)
                    } label: {
                        HStack {
                            // Set number
                            Text("\(set.setNumber)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.blue))
                            
                            // Set details
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    // Primary metric
                                    if set.usePrimarySplitMetrics {
                                        HStack(spacing: 4) {
                                            Text("L: \(formatValue(set.primaryMetricValueLeft))")
                                                .font(.subheadline)
                                            Text("R: \(formatValue(set.primaryMetricValueRight))")
                                                .font(.subheadline)
                                            Text(set.primaryMetricUnit ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Text(formatValue(set.primaryMetricValue))
                                                .font(.subheadline)
                                            Text(set.primaryMetricUnit ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Text("×")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    // Secondary metric
                                    if set.useSecondarySplitMetrics {
                                        HStack(spacing: 4) {
                                            Text("L: \(formatValue(set.secondaryMetricValueLeft))")
                                                .font(.subheadline)
                                            Text("R: \(formatValue(set.secondaryMetricValueRight))")
                                                .font(.subheadline)
                                            Text(set.secondaryMetricUnit ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Text(formatValue(set.secondaryMetricValue))
                                                .font(.subheadline)
                                            Text(set.secondaryMetricUnit ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                if let notes = set.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            // Time indicator
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(set.date?.formatted(date: .omitted, time: .shortened) ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                setToDelete = set
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
            }
            
            // Add set button at bottom
            if !movementLog.setsArray.isEmpty {
                Button(action: {
                    showSetEntry = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Set")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    
    private func deleteSet(at offsets: IndexSet) {
        let sets = movementLog.setsArray
        offsets.forEach { index in
            let set = sets[index]
            viewContext.delete(set)
        }
        saveContext()
    }
    
    private func deleteMovementLog() {
        if let workout = movementLog.workout {
            workout.removeFromMovementLogs(movementLog)
        }
        viewContext.delete(movementLog)
        saveContext()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// Preview provider for SwiftUI canvas
struct MovementLogEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create test data
        let movement = Movement(context: context)
        movement.name = "Bench Press"
        
        let muscleGroup = MuscleGroup(context: context)
        muscleGroup.name = "Chest"
        movement.addToMuscleGroups(muscleGroup)
        
        let movementLog = MovementLog(context: context)
        movementLog.movement = movement
        movementLog.date = Date()
        
        // Create a sample set
        let set = SetEntity(context: context)
        set.setNumber = 1
        set.primaryMetricValue = 135.0
        set.primaryMetricUnit = "lbs"
        set.secondaryMetricValue = 8.0
        set.secondaryMetricUnit = "reps"
        set.date = Date()
        set.notes = "Good form, felt strong"
        movementLog.addToSets(set)
        
        return NavigationView {
            MovementLogEditView(movementLog: movementLog)
                .environment(\.managedObjectContext, context)
        }
    }
}
