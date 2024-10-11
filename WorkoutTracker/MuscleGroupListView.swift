import SwiftUI
import CoreData

struct MuscleGroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var errorMessage: String?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MuscleGroup.name, ascending: true)],
        animation: .default)
    private var muscleGroups: FetchedResults<MuscleGroup>
    
    @State private var showingAddMuscleGroup = false
    
    var body: some View {
        List {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
            ForEach(muscleGroups) { muscleGroup in
                NavigationLink(destination: MuscleGroupDetailView(muscleGroup: muscleGroup)) {
                    Text(muscleGroup.name ?? "Unnamed Muscle Group")
                }
            }
            .onDelete(perform: deleteMuscleGroups)
        }
        .navigationTitle("Muscle Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddMuscleGroup = true }) {
                    Label("Add Muscle Group", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMuscleGroup) {
            AddMuscleGroupView()
        }
        .onAppear {
            // Remove the unnecessary fetch call
            if muscleGroups.isEmpty {
                errorMessage = "No muscle groups found."
            }
        }
    }
    
    private func deleteMuscleGroups(offsets: IndexSet) {
        withAnimation {
            offsets.map { muscleGroups[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                errorMessage = "Unresolved error \(nsError), \(nsError.userInfo)"
            }
        }
    }
}

struct MuscleGroupDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var muscleGroup: MuscleGroup
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                Text("Name: \(muscleGroup.name ?? "")")
                if let description = muscleGroup.muscleGroupDescription, !description.isEmpty {
                    Text("Description: \(description)")
                }
            }
            
            Section(header: Text("Associated Movements")) {
                if let movements = muscleGroup.movements, !movements.isEmpty {
                    ForEach(Array(movements), id: \.self) { movement in
                        Text(movement.name ?? "Unnamed Movement")
                    }
                } else {
                    Text("No associated movements")
                }
            }
        }
        .navigationTitle(muscleGroup.name ?? "Muscle Group Details")
    }
}

struct AddMuscleGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Muscle Group Details")) {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }
            }
            .navigationTitle("Add Muscle Group")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMuscleGroup()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMuscleGroup() {
        let newMuscleGroup = MuscleGroup(context: viewContext)
        newMuscleGroup.id = UUID()
        newMuscleGroup.name = name
        newMuscleGroup.muscleGroupDescription = description
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
