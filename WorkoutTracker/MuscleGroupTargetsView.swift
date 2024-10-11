import SwiftUI
import CoreData

struct MuscleGroupTargetsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MuscleGroup.name, ascending: true)],
        animation: .default)
    private var muscleGroups: FetchedResults<MuscleGroup>
    
    var body: some View {
        List {
            ForEach(muscleGroups) { muscleGroup in
                NavigationLink(destination: MuscleGroupTargetDetailView(muscleGroup: muscleGroup)) {
                    MuscleGroupTargetRow(muscleGroup: muscleGroup, context: viewContext)
                }
            }
        }
        .navigationTitle("Muscle Group Targets")
    }
}

struct MuscleGroupTargetRow: View {
    @ObservedObject var muscleGroup: MuscleGroup
    let context: NSManagedObjectContext
    @State private var weeklySets: [Int] = [0, 0, 0, 0]
    
    private let barHeight: CGFloat = 140 // Increased by 40%
    private let maxSets: Int = 30 // Adjust this based on your expected maximum
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(muscleGroup.name ?? "Unknown")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach([maxSets, maxSets/2, 0], id: \.self) { value in
                        Text("\(value)")
                            .font(.caption)
                            .frame(height: barHeight / 3)
                    }
                }
                .frame(width: 20)
                
                // Bar graph
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklySets.indices, id: \.self) { index in
                        VStack {
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 30, height: barHeight)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: CGFloat(weeklySets[index]) / CGFloat(maxSets) * barHeight)
                            }
                            Text("W\(index + 1)")
                                .font(.caption)
                        }
                    }
                }
            }
            .background(
                Rectangle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .frame(height: barHeight + 20) // Add some extra height for the week labels
            
            Text("Total: \(weeklySets.reduce(0, +)) sets / 30 days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onAppear {
            loadWeeklySets()
        }
    }
    
    private func loadWeeklySets() {
        weeklySets = MovementLog.countWeeklySets(for: muscleGroup, in: context)
    }
}

struct MuscleGroupTargetDetailView: View {
    @ObservedObject var muscleGroup: MuscleGroup
    @State private var targetSets: Int = 0
    @State private var weeklySets: [Int] = [0, 0, 0, 0]
    
    var body: some View {
        Form {
            Section(header: Text("Target")) {
                Stepper("Target sets per week: \(targetSets)", value: $targetSets, in: 0...50)
            }
            
            Section(header: Text("Actual")) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(weeklySets.indices, id: \.self) { index in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 40, height: CGFloat(weeklySets[index]) * 5)
                            Text("W\(index + 1)")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
                Text("Total sets in last 30 days: \(weeklySets.reduce(0, +))")
                Text("Weekly average: \(String(format: "%.1f", Double(weeklySets.reduce(0, +)) / 4.0))")
            }
        }
        .navigationTitle(muscleGroup.name ?? "Unknown")
        .onAppear {
            loadTargetSets()
            loadWeeklySets()
        }
    }
    
    private func loadTargetSets() {
        targetSets = Int(muscleGroup.muscleGroupTarget?.targetSetsPerWeek ?? 0)
    }
    
    private func loadWeeklySets() {
        weeklySets = MovementLog.countWeeklySets(for: muscleGroup, in: muscleGroup.managedObjectContext!)
    }
}