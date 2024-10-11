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
    @State private var maxSets: Int = 1
    @State private var targetSets: Int = 0
    
    private let barHeight: CGFloat = 140
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(muscleGroup.name ?? "Unknown")
                .font(.headline)
            Text("Target: \(targetSets) sets per week")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis labels
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach([maxSets, maxSets/2, 0], id: \.self) { value in
                            Text("\(value)")
                                .font(.caption)
                                .frame(height: barHeight / 3)
                        }
                    }
                    .frame(width: 30)
                    
                    // Bar graph
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(weeklySets.indices.reversed(), id: \.self) { index in
                            VStack {
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: barHeight)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: CGFloat(weeklySets[index]) / CGFloat(maxSets) * barHeight)
                                }
                                Text("\(4-index) week\(index == 3 ? "" : "s") ago")
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(width: geometry.size.width - 40)
                    .overlay(
                        Rectangle()
                            .fill(Color.red)
                            .frame(height: 2)
                            .offset(y: -CGFloat(targetSets) / CGFloat(maxSets) * barHeight / 2)
                    )
                }
            }
            .frame(height: barHeight + 40)
            
            Text("Total: \(weeklySets.reduce(0, +)) sets in 4 weeks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onAppear {
            loadWeeklySets()
            loadTargetSets()
        }
    }
    
    private func loadWeeklySets() {
        weeklySets = MovementLog.countWeeklySets(for: muscleGroup, in: context)
        maxSets = max(weeklySets.max() ?? 1, targetSets, 1)
    }
    
    private func loadTargetSets() {
        targetSets = Int(muscleGroup.muscleGroupTarget?.targetSetsPerWeek ?? 0)
    }
}

struct MuscleGroupTargetDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var muscleGroup: MuscleGroup
    @State private var targetSets: Int = 0
    @State private var weeklySets: [Int] = [0, 0, 0, 0]
    @State private var maxSets: Int = 1
    
    var body: some View {
        Form {
            Section(header: Text("Target")) {
                Stepper("Target sets per week: \(targetSets)", value: $targetSets, in: 0...50)
                Button("Save Target") {
                    saveTarget()
                }
            }
            
            Section(header: Text("Actual")) {
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(weeklySets.indices.reversed(), id: \.self) { index in
                            VStack {
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(height: CGFloat(weeklySets[index]) / CGFloat(maxSets) * 200)
                                }
                                Text("\(4-index) week\(index == 3 ? "" : "s") ago")
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(width: geometry.size.width)
                    .overlay(
                        Rectangle()
                            .fill(Color.red)
                            .frame(height: 2)
                            .offset(y: -CGFloat(targetSets) / CGFloat(maxSets) * 100)
                    )
                }
                .frame(height: 240)
                
                Text("Total sets in last 4 weeks: \(weeklySets.reduce(0, +))")
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
        weeklySets = MovementLog.countWeeklySets(for: muscleGroup, in: viewContext)
        maxSets = max(weeklySets.max() ?? 1, targetSets, 1)
    }
    
    private func saveTarget() {
        if muscleGroup.muscleGroupTarget == nil {
            let newTarget = MuscleGroupTarget(context: viewContext)
            newTarget.muscleGroup = muscleGroup
            muscleGroup.muscleGroupTarget = newTarget
        }
        
        muscleGroup.muscleGroupTarget?.targetSetsPerWeek = Int16(targetSets)
        
        do {
            try viewContext.save()
            loadWeeklySets() // Reload to update the graph
        } catch {
            print("Failed to save target: \(error)")
        }
    }
}
