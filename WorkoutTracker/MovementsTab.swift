import SwiftUI
import CoreData

struct MovementsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Movement.movementClass, ascending: true),
            NSSortDescriptor(keyPath: \Movement.name, ascending: true)
        ],
        animation: .default)
    private var movements: FetchedResults<Movement>

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedMovements.keys.sorted(), id: \.self) { movementClass in
                    Section(header: Text(movementClass)) {
                        ForEach(groupedMovements[movementClass]!, id: \.self) { movement in
                            NavigationLink(destination: MovementHistoryView(movement: movement)) {
                                HStack {
                                    Text(movement.name ?? "Unknown Movement")
                                    Spacer()
                                    Text(movement.muscleGroups?.first?.name ?? "No Muscle Group")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Movements")
        }
    }

    private var groupedMovements: [String: [Movement]] {
        let grouped = Dictionary(grouping: movements) { $0.movementClass ?? "Unknown" }
        return grouped.mapValues { movements in
            movements.sorted { 
                ($0.muscleGroups?.first?.name ?? "") < ($1.muscleGroups?.first?.name ?? "")
            }
        }
    }
}
