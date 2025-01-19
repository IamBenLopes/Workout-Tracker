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
    
    @State private var searchText = ""
    @State private var selectedMovementClass: String? = nil
    @State private var selectedMuscleGroup: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Filter Pills ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Movement Class Pills
                            ForEach(["All"] + Array(Set(movements.compactMap { $0.movementClass })).sorted(), id: \.self) { movementClass in
                                MovementClassPill(
                                    title: movementClass,
                                    isSelected: selectedMovementClass == movementClass || (movementClass == "All" && selectedMovementClass == nil)
                                ) {
                                    if movementClass == "All" {
                                        selectedMovementClass = nil
                                    } else {
                                        selectedMovementClass = movementClass
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Muscle Group Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["All"] + Array(Set(getAllMuscleGroups())).sorted(), id: \.self) { muscleGroup in
                                MuscleGroupPill(
                                    title: muscleGroup,
                                    isSelected: selectedMuscleGroup == muscleGroup || (muscleGroup == "All" && selectedMuscleGroup == nil)
                                ) {
                                    if muscleGroup == "All" {
                                        selectedMuscleGroup = nil
                                    } else {
                                        selectedMuscleGroup = muscleGroup
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Movement Cards List
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMovements, id: \.self) { movement in
                            NavigationLink(destination: MovementHistoryView(movement: movement)) {
                                MovementCard(movement: movement)
                            }
                            
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Movements")
            .searchable(text: $searchText, prompt: "Search movements")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var filteredMovements: [Movement] {
        movements.filter { movement in
            let matchesSearch = searchText.isEmpty || 
                (movement.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesClass = selectedMovementClass == nil || 
                movement.movementClass == selectedMovementClass
            
            let matchesMuscleGroup = selectedMuscleGroup == nil || 
                (movement.muscleGroups?.contains { $0.name == selectedMuscleGroup } ?? false)
            
            return matchesSearch && matchesClass && matchesMuscleGroup
        }
    }
    
    private func getAllMuscleGroups() -> [String] {
        var muscleGroups: Set<String> = []
        for movement in movements {
            if let groups = movement.muscleGroups {
                for group in groups {
                    if let name = group.name {
                        muscleGroups.insert(name)
                    }
                }
            }
        }
        return Array(muscleGroups)
    }
}

struct MovementClassPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

struct MuscleGroupPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.green : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

struct MovementCard: View {
    @ObservedObject var movement: Movement
    
    var body: some View {
        HStack(spacing: 16) {
            // Movement Icon
            Image(systemName: getMovementIcon())
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                // Movement Name and Class
                HStack {
                    Text(movement.name ?? "Unknown")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(movement.movementClass ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Muscle Groups
                if let muscleGroups = movement.muscleGroups {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(muscleGroups), id: \.self) { muscleGroup in
                                Text(muscleGroup.name ?? "")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
    
    private func getMovementIcon() -> String {
        switch movement.movementClass {
        case "Strength":
            return "dumbbell.fill"
        case "Cardio":
            return "heart.circle.fill"
        case "Stretch":
            return "figure.flexibility"
        default:
            return "figure.walk"
        }
    }
}
