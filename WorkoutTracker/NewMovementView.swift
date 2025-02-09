import SwiftUI
import CoreData
import UIKit

struct NewMovementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: Workout
    var onFinish: (() -> Void)?
    
    @State private var name = ""
    @State private var movementClass = "Strength"
    @State private var description = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingMuscleGroupSelection = false
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSetEntry = false
    @State private var newMovementLog: MovementLog?
    
    let movementClasses = ["Strength", "Cardio", "Stretch"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                // Header section with clear instructions
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create New Movement")
                            .font(.title)
                            .bold()
                        
                        Text("Fill in the details below to add a new movement to your workout routine.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Basic Details Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Movement Name")
                            .font(.headline)
                        TextField("Enter movement name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minHeight: 44)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Movement Type")
                            .font(.headline)
                        Picker("Movement Class", selection: $movementClass) {
                            ForEach(movementClasses, id: \.self) { className in
                                Text(className).tag(className)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(minHeight: 44)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Basic Details")
                        .font(.headline)
                }
                
                // Description Section
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 150)
                        .padding(1) // Thin padding to prevent text touching the border
                } header: {
                    Text("Description")
                        .font(.headline)
                }
                
                // Photo Section
                Section {
                    VStack(spacing: 12) {
                        if let inputImage = inputImage {
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text(inputImage == nil ? "Add Photo" : "Change Photo")
                            }
                            .frame(minWidth: 200, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Movement Photo")
                        .font(.headline)
                }
                
                // Muscle Group Section
                Section {
                    Button(action: {
                        showingMuscleGroupSelection = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Target Muscle Group")
                                    .font(.body)
                                if let group = selectedMuscleGroup {
                                    Text(group.name ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Text("Muscle Group")
                        .font(.headline)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            
            // Create button - Fixed at bottom
            VStack(spacing: 0) {
                Divider()
                Button(action: {
                    if name.isEmpty {
                        dismiss()
                    } else {
                        print("DEBUG: NewMovementView - Create button tapped")
                        createMovement()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: name.isEmpty ? "minus.circle.fill" : "plus.circle.fill")
                        Text(name.isEmpty ? "Cancel" : "Create Movement")
                            .font(.headline)
                        Spacer()
                    }
                    .frame(minHeight: 54)
                    .foregroundColor(.white)
                    .background(name.isEmpty ? Color.red.opacity(0.8) : Color.accentColor)
                }
            }
            .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle("New Movement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingMuscleGroupSelection) {
            MuscleGroupSelectionView(selectedMuscleGroup: selectedMuscleGroup) { newSelection in
                selectedMuscleGroup = newSelection
            }
        }
        .sheet(isPresented: $showSetEntry) {
            if let movementLog = newMovementLog {
                SetEntryView(movementLog: movementLog, onFinish: {
                    print("DEBUG: NewMovementView - onFinish called from SetEntryView")
                    showSetEntry = false
                    onFinish?()
                })
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadImage() {
        // The inputImage is already set by the ImagePicker binding
        // No need to do anything else here since the image is displayed in the view
    }
    
    private func createMovement() {
        print("DEBUG: NewMovementView - Creating new movement")
        guard !name.isEmpty else {
            print("DEBUG: NewMovementView - Error: Empty movement name")
            errorMessage = "Please enter a movement name"
            showErrorAlert = true
            return
        }
        
        // Check for existing movement with the same name
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let existingMovements = try viewContext.fetch(request)
            if !existingMovements.isEmpty {
                print("DEBUG: NewMovementView - Error: Movement with this name already exists")
                errorMessage = "A movement with this name already exists"
                showErrorAlert = true
                return
            }
        } catch {
            print("DEBUG: NewMovementView - Error checking for existing movements: \(error)")
            errorMessage = "Error checking for existing movements"
            showErrorAlert = true
            return
        }
        
        let movement = Movement(context: viewContext)
        movement.movementId = UUID()
        movement.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        movement.movementClass = movementClass
        movement.movementDescription = description
        movement.movementPhoto = inputImage?.jpegData(compressionQuality: 0.8)
        
        // Create MovementLog
        let movementLog = MovementLog(context: viewContext)
        movementLog.movementLogId = UUID()
        movementLog.movement = movement
        movementLog.workout = workout
        movementLog.date = Date()
        
        // Set the order for the movement log
        let currentMaxOrder = workout.movementLogsArray.map { $0.logOrder }.max() ?? -1
        movementLog.logOrder = Int16(currentMaxOrder + 1)
        
        // Update muscle group
        if let muscleGroup = selectedMuscleGroup {
            muscleGroup.addToMovements(movement)
            movement.muscleGroups = [muscleGroup]
        }
        
        do {
            try viewContext.save()
            print("DEBUG: NewMovementView - Successfully created movement and movement log")
            self.newMovementLog = movementLog
            self.showSetEntry = true
        } catch {
            print("DEBUG: NewMovementView - Error saving context: \(error)")
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
} 
