import SwiftUI
import CoreData

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Year"
    case all = "All Time"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return Int.max
        }
    }
}

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedMovementClass = "Strength"
    @State private var searchText = ""
    
    let movementClasses = ["Strength", "Cardio", "Stretch"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Movement Class Picker
                Picker("Movement Class", selection: $selectedMovementClass) {
                    ForEach(movementClasses, id: \.self) { movementClass in
                        Text(movementClass).tag(movementClass)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Movement List with Search
                MovementListView(movementClass: selectedMovementClass, searchText: searchText)
            }
            .navigationTitle("Progress")
            .searchable(text: $searchText, prompt: "Search movements")
        }
    }
}

struct MovementListView: View {
    @FetchRequest var movements: FetchedResults<Movement>
    let searchText: String
    
    init(movementClass: String, searchText: String) {
        self.searchText = searchText
        _movements = FetchRequest<Movement>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Movement.name, ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "movementClass == %@", movementClass),
                searchText.isEmpty ? NSPredicate(value: true) : NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            ])
        )
    }
    
    var body: some View {
        List {
            ForEach(movements, id: \.self) { movement in
                NavigationLink(destination: MovementDetailView(movement: movement)) {
                    MovementRowView(movement: movement)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct MovementRowView: View {
    @ObservedObject var movement: Movement
    @State private var recentStats: MovementStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Movement Name
            Text(movement.name ?? "Unknown Movement")
                .font(.headline)
            
            if let stats = recentStats {
                // Recent Performance Stats
                HStack {
                    if stats.usesSplitMetrics {
                        VStack(alignment: .leading) {
                            makeMetricView(label: "Left", value: stats.leftValue, unit: stats.unit)
                            makeMetricView(label: "Right", value: stats.rightValue, unit: stats.unit)
                        }
                    } else {
                        makeMetricView(label: stats.metricType, value: stats.value, unit: stats.unit)
                    }
                    
                    Spacer()
                    
                    // Trend Indicator
                    if let trend = stats.trend {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(trend > 0 ? .green : .red)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadRecentStats()
        }
    }
    
    private func makeMetricView(label: String, value: Double, unit: String) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
            Text(String(format: "%.1f", value))
            Text(unit)
        }
    }
    
    private func loadRecentStats() {
        // Step 1: Get and sort movement logs
        if let movementLogs = movement.movementLogs {
            let logs = Array(movementLogs)
            let sortedLogs = logs.sorted { 
                let date1 = $0.date ?? .distantPast
                let date2 = $1.date ?? .distantPast
                return date1 > date2
            }
            
            // Step 2: Get latest log and its sets
            guard let latestLog = sortedLogs.first else { return }
            guard let latestSets = latestLog.sets as? Set<SetEntity> else { return }
            guard let firstSet = latestSets.first else { return }
            
            // Step 3: Get previous log for trend calculation
            let previousLog = sortedLogs.count > 1 ? sortedLogs[1] : nil
            
            // Step 4: Get metric information
            let usesSplit = firstSet.usePrimarySplitMetrics
            let metricType = firstSet.primaryMetricType ?? "Weight"
            let unit = firstSet.primaryMetricUnit ?? ""
            
            // Step 5: Calculate latest averages
            let latestAvg = calculateAverageValues(from: latestSets)
            
            // Step 6: Calculate trend
            let trend = calculateTrend(
                latestAvg: latestAvg,
                previousLog: previousLog
            )
            
            // Step 7: Create and assign stats
            recentStats = MovementStats(
                metricType: metricType,
                usesSplitMetrics: usesSplit,
                value: latestAvg.primary,
                leftValue: latestAvg.leftPrimary,
                rightValue: latestAvg.rightPrimary,
                unit: unit,
                trend: trend
            )
        }
    }
    
    private func calculateTrend(
        latestAvg: (primary: Double, leftPrimary: Double, rightPrimary: Double),
        previousLog: MovementLog?
    ) -> Double? {
        guard let previousLog = previousLog,
              let previousSets = previousLog.sets as? Set<SetEntity> else {
            return nil
        }
        
        let previousAvg = calculateAverageValues(from: previousSets)
        
        if previousAvg.primary > 0 {
            return ((latestAvg.primary - previousAvg.primary) / previousAvg.primary) * 100
        }
        
        return nil
    }
    
    private func calculateAverageValues(from sets: Set<SetEntity>) -> (primary: Double, leftPrimary: Double, rightPrimary: Double) {
        var totalPrimary = 0.0
        var totalLeftPrimary = 0.0
        var totalRightPrimary = 0.0
        var count = 0
        
        for set in sets {
            if set.usePrimarySplitMetrics {
                totalLeftPrimary += set.primaryMetricValueLeft
                totalRightPrimary += set.primaryMetricValueRight
            } else {
                totalPrimary += set.primaryMetricValue
            }
            count += 1
        }
        
        return (
            primary: totalPrimary / Double(max(count, 1)),
            leftPrimary: totalLeftPrimary / Double(max(count, 1)),
            rightPrimary: totalRightPrimary / Double(max(count, 1))
        )
    }
}

// Helper struct to organize movement statistics
struct MovementStats {
    let metricType: String
    let usesSplitMetrics: Bool
    let value: Double
    let leftValue: Double
    let rightValue: Double
    let unit: String
    let trend: Double? // Percentage change
}

struct MovementDetailView: View {
    @ObservedObject var movement: Movement
    @Environment(\.managedObjectContext) private var viewContext
    @State private var timeRange: TimeRange = .month
    @State private var showingFilters = false
    @State private var showingAllSets = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with muscle groups
                if let muscleGroups = movement.muscleGroups, !muscleGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(muscleGroups), id: \.self) { muscleGroup in
                                Text(muscleGroup.name ?? "Unknown")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Time Range Picker with improved styling
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Period")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    timeRangePicker
                }
                .padding(.vertical, 8)
                
                // Movement Graph with improved layout
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Graph")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    MovementGraphView(movement: movement, timeRange: $timeRange)
                }
                
                // Stats Summary with improved styling
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    StatsSummaryView(movement: movement, timeRange: timeRange)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                }
                
                // Recent Sets List with improved styling
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Sets")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAllSets.toggle() }) {
                            Text(showingAllSets ? "Show Less" : "Show All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    RecentSetsView(movement: movement, showAll: showingAllSets)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(movement.name ?? "Movement Progress")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(movement: movement)
                .presentationDetents([.medium, .large])
        }
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

struct StatsSummaryView: View {
    let movement: Movement
    let timeRange: TimeRange
    @State private var stats: MovementSummaryStats?
    
    var body: some View {
        VStack(spacing: 12) {
            if let stats = stats {
                HStack {
                    StatCard(title: "Personal Best", value: stats.personalBest, unit: stats.unit, iconName: "trophy.fill", color: .yellow)
                    StatCard(title: "Average", value: stats.average, unit: stats.unit, iconName: "chart.bar.fill", color: .blue)
                    if stats.usesSplitMetrics {
                        StatCard(title: "L/R Ratio", value: stats.leftRightRatio, unit: "%", iconName: "arrow.left.arrow.right", color: .green)
                    }
                }
                
                if let volume = stats.totalVolume {
                    StatCard(title: "Total Volume", value: volume, unit: stats.unit, iconName: "sum", color: .purple)
                        .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading stats...")
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
            }
        }
        .padding()
        .onAppear {
            loadStats()
        }
        .onChange(of: timeRange) { oldValue, newValue in
            loadStats()
        }
    }
    
    private func loadStats() {
        // Implement stats calculation based on timeRange
        // This is a placeholder for the actual implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate loading data
            if movement.movementLogs?.count ?? 0 > 0 {
                stats = MovementSummaryStats(
                    personalBest: 225.0,
                    average: 195.0,
                    leftRightRatio: 0.9,
                    totalVolume: 3300.0,
                    usesSplitMetrics: movement.hasAnySplitMetrics,
                    unit: getMetricUnit(for: movement)
                )
            } else {
                stats = MovementSummaryStats(
                    personalBest: 0.0,
                    average: 0.0,
                    leftRightRatio: 0.0,
                    totalVolume: 0.0,
                    usesSplitMetrics: movement.hasAnySplitMetrics,
                    unit: getMetricUnit(for: movement)
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let unit: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(color)
                .padding(.bottom, 2)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f", value))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MovementSummaryStats {
    let personalBest: Double
    let average: Double
    let leftRightRatio: Double
    let totalVolume: Double?
    let usesSplitMetrics: Bool
    let unit: String
}

struct RecentSetsView: View {
    @ObservedObject var movement: Movement
    var showAll: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let movementLogs = movement.movementLogs {
                let sortedLogs = Array(movementLogs)
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                
                if sortedLogs.isEmpty {
                    emptyStateView
                } else {
                    let logsToShow = showAll ? sortedLogs : Array(sortedLogs.prefix(3))
                    
                    ForEach(logsToShow, id: \.self) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.formattedDate)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text(log.workout?.workoutName ?? "Unknown Workout")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            ForEach(log.setsArray.prefix(3), id: \.self) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 50, alignment: .leading)
                                    
                                    if set.usePrimarySplitMetrics {
                                        HStack(spacing: 2) {
                                            Text("L: \(Int(set.primaryMetricValueLeft))")
                                            Text("R: \(Int(set.primaryMetricValueRight))")
                                        }
                                        .font(.subheadline)
                                    } else {
                                        Text("\(Int(set.primaryMetricValue))")
                                            .font(.subheadline)
                                    }
                                    
                                    Text(set.primaryMetricUnit ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if set.secondaryMetricValue > 0 && set.secondaryMetricType == "Reps" {
                                        Text("\(Int(set.secondaryMetricValue)) reps")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if log.setsArray.count > 3 {
                                Text("+ \(log.setsArray.count - 3) more sets")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            } else {
                emptyStateView
            }
        }
        .padding(.vertical)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No sets recorded yet")
                .font(.headline)
            Text("Complete a workout with this movement to see your sets here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var movement: Movement
    @State private var selectedMetrics: Set<String> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Metrics to Show")) {
                    Toggle("Primary Metric", isOn: bindingForMetric("primary"))
                    Toggle("Secondary Metric", isOn: bindingForMetric("secondary"))
                    if movement.hasAnySplitMetrics {
                        Toggle("Left/Right Comparison", isOn: bindingForMetric("split"))
                    }
                }
                
                Section(header: Text("Date Range")) {
                    // Add date range filters here
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Apply") { dismiss() }
            )
        }
    }
    
    private func bindingForMetric(_ metric: String) -> Binding<Bool> {
        Binding(
            get: { selectedMetrics.contains(metric) },
            set: { isSelected in
                if isSelected {
                    selectedMetrics.insert(metric)
                } else {
                    selectedMetrics.remove(metric)
                }
            }
        )
    }
}

extension Movement {
    var hasAnySplitMetrics: Bool {
        guard let logs = movementLogs else { return false }
        return Array(logs).contains { log in
            guard let sets = log.sets as? Set<SetEntity> else { return false }
            return sets.contains { $0.usePrimarySplitMetrics || $0.useSecondarySplitMetrics }
        }
    }
}

private func processMovementLogs(_ movement: Movement) -> [MovementLog] {
    guard let movementLogs = movement.movementLogs else { return [] }
    return Array(movementLogs)
}

private func calculateProgress(for movement: Movement) -> Double {
    let logs = processMovementLogs(movement)
    
    // Break down complex calculations
    let filteredLogs = logs.filter { log in
        // Add your filtering conditions here
        return true // Replace with actual filtering logic
    }
    
    let calculatedValues = filteredLogs.map { log in
        // Add your mapping logic here
        return 0.0 // Replace with actual calculation
    }
    
    let finalValue = calculatedValues.reduce(0.0) { sum, value in
        // Add your reduction logic here
        return sum + value
    }
    
    return finalValue
}

// Helper function to get the metric unit from a movement
private func getMetricUnit(for movement: Movement) -> String {
    // Try to find the unit from the movement logs
    if let logs = movement.movementLogs,
       !logs.isEmpty {
        let logsArray = (logs as NSSet).allObjects as? [MovementLog]
        if let logsArray = logsArray,
           !logsArray.isEmpty,
           let firstLog = logsArray.first,
           let sets = firstLog.sets,
           (sets as NSSet).count > 0 {
            let setsArray = (sets as NSSet).allObjects as? [SetEntity]
            if let setsArray = setsArray,
               !setsArray.isEmpty,
               let firstSet = setsArray.first {
                return firstSet.primaryMetricUnit ?? "lbs"
            }
        }
    }
    
    // Default unit if no logs found
    return "lbs"
}
