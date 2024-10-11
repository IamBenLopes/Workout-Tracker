import SwiftUI
import CoreData

struct MuscleGroupSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var localSelectedMuscleGroup: MuscleGroup?
    let onDismiss: (MuscleGroup?) -> Void
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MuscleGroup.name, ascending: true)],
        animation: .default)
    private var muscleGroups: FetchedResults<MuscleGroup>
    
    init(selectedMuscleGroup: MuscleGroup?, onDismiss: @escaping (MuscleGroup?) -> Void) {
        _localSelectedMuscleGroup = State(initialValue: selectedMuscleGroup)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(muscleGroups, id: \.self) { muscleGroup in
                    Button(action: {
                        localSelectedMuscleGroup = muscleGroup
                    }) {
                        HStack {
                            Text(muscleGroup.name ?? "Unnamed Muscle Group")
                            Spacer()
                            if localSelectedMuscleGroup == muscleGroup {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Muscle Group")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    onDismiss(localSelectedMuscleGroup)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
