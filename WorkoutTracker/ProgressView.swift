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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Time range picker
                timeRangePicker
                
                // Progress Graph
                MovementGraphView(movement: movement)
                    .frame(height: 200)
                    .padding()
                
                // Stats Summary
                StatsSummaryView(movement: movement, timeRange: timeRange)
                
                // Recent Sets List
                RecentSetsView(movement: movement)
            }
        }
        .navigationTitle(movement.name ?? "Movement Progress")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(movement: movement)
        }
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding()
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
                    StatCard(title: "Personal Best", value: stats.personalBest, unit: stats.unit)
                    StatCard(title: "Average", value: stats.average, unit: stats.unit)
                    if stats.usesSplitMetrics {
                        StatCard(title: "L/R Ratio", value: stats.leftRightRatio, unit: "%")
                    }
                }
                
                if let volume = stats.totalVolume {
                    StatCard(title: "Total Volume", value: volume, unit: stats.unit)
                }
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
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.headline)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sets")
                .font(.headline)
                .padding(.horizontal)
            
            if let movementLogs = movement.movementLogs {
                let sortedLogs = Array(movementLogs)
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                
                ForEach(sortedLogs.prefix(3), id: \.self) { log in
                    MovementLog.LogCard(log: log)  // Use the fully qualified name
                }
            } else {
                Text("No recent sets")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
    }
}



struct SetRow: View {
    let set: SetEntity
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Set \(set.setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44) // Following Apple's minimum touch target size
            
            if set.usePrimarySplitMetrics {
                Text("L: \(formatValue(set.primaryMetricValueLeft))")
                Text("R: \(formatValue(set.primaryMetricValueRight))")
            } else {
                Text(formatValue(set.primaryMetricValue))
            }
            
            Text(set.primaryMetricUnit ?? "")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(minHeight: 44) // Following Apple's minimum touch target size
    }
    
    private func formatValue(_ value: Double) -> String {
        String(format: "%.1f", value)
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


