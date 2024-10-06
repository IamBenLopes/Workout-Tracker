import SwiftUI
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedMovementClass = "Strength"
    
    let movementClasses = ["Strength", "Cardio", "Stretch"]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Movement Class", selection: $selectedMovementClass) {
                    ForEach(movementClasses, id: \.self) { movementClass in
                        Text(movementClass).tag(movementClass)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                MovementListView(movementClass: selectedMovementClass)
            }
            .navigationTitle("Progress")
        }
    }
}

struct MovementListView: View {
    @FetchRequest var movements: FetchedResults<Movement>
    
    init(movementClass: String) {
        _movements = FetchRequest<Movement>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Movement.name, ascending: true)],
            predicate: NSPredicate(format: "movementClass == %@", movementClass)
        )
    }
    
    var body: some View {
        List(movements, id: \.self) { movement in
            NavigationLink(destination: MovementGraphView(movement: movement)) {
                Text(movement.name ?? "Unknown Movement")
            }
        }
    }
}


