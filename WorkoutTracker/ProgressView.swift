import SwiftUI
import CoreData

// Remove all Core Data model redeclarations since they already exist elsewhere

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
                let date1 = $0.date ?? Date.distantPast
                let date2 = $1.date ?? Date.distantPast
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
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
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
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
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
                // Break up the stats cards into separate view builders
                VStack(spacing: 12) {
                    HStack {
                        personalBestCard(stats: stats)
                        averageCard(stats: stats)
                        
                        if stats.usesSplitMetrics {
                            leftRightRatioCard(stats: stats)
                        }
                    }
                    
                    if let volume = stats.totalVolume {
                        totalVolumeCard(stats: stats, volume: volume)
                    }
                }
            } else {
                // Loading state
                loadingView
            }
        }
        .padding()
        .onAppear {
            loadStats()
        }
        .onChange(of: timeRange) { _, _ in
            loadStats()
        }
    }
    
    // MARK: - Component Views
    
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading stats...")
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
    }
    
    private func personalBestCard(stats: MovementSummaryStats) -> some View {
        VStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)
                .padding(.bottom, 2)
            
            Text("Personal Best")
                .font(.caption)
                .foregroundColor(Color.secondary)
            
            Text(String(format: "%.1f", stats.personalBest))
                .font(.headline)
                .foregroundColor(Color.primary)
            
            Text(stats.unit)
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func averageCard(stats: MovementSummaryStats) -> some View {
        VStack {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .padding(.bottom, 2)
            
            Text("Average")
                .font(.caption)
                .foregroundColor(Color.secondary)
            
            Text(String(format: "%.1f", stats.average))
                .font(.headline)
                .foregroundColor(Color.primary)
            
            Text(stats.unit)
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func leftRightRatioCard(stats: MovementSummaryStats) -> some View {
        VStack {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .padding(.bottom, 2)
            
            Text("L/R Ratio")
                .font(.caption)
                .foregroundColor(Color.secondary)
            
            Text(String(format: "%.1f", stats.leftRightRatio))
                .font(.headline)
                .foregroundColor(Color.primary)
            
            Text("%")
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func totalVolumeCard(stats: MovementSummaryStats, volume: Double) -> some View {
        VStack {
            Image(systemName: "sum")
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .padding(.bottom, 2)
            
            Text("Total Volume")
                .font(.caption)
                .foregroundColor(Color.secondary)
            
            Text(String(format: "%.1f", volume))
                .font(.headline)
                .foregroundColor(Color.primary)
            
            Text(stats.unit)
                .font(.caption2)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Data Loading
    
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
            if let movementLogs = movement.movementLogs, !Array(movementLogs).isEmpty {
                workoutLogsContent
            } else {
                emptyStateView
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Content Views
    
    private var workoutLogsContent: some View {
        let logsArray = getFormattedLogs()
        
        return VStack(spacing: 16) {
            ForEach(logsArray) { logInfo in
                workoutLogCard(for: logInfo.log, date: logInfo.formattedDate, workoutName: logInfo.workoutName)
            }
        }
    }
    
    private func workoutLogCard(for log: MovementLog, date: String, workoutName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with date and workout name
            HStack {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(workoutName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Sets Display
            setsList(for: log)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func setsList(for log: MovementLog) -> some View {
        let sets = log.setsArray
        let setsToShow = sets.prefix(3)
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(setsToShow), id: \.self) { set in
                setSummaryRow(set: set)
            }
            
            if sets.count > 3 {
                Text("+ \(sets.count - 3) more sets")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
    }
    
    private func setSummaryRow(set: SetEntity) -> some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Metric values
            metricDisplay(for: set)
            
            Spacer()
            
            // Secondary metric (if available)
            if set.secondaryMetricValue > 0 && set.secondaryMetricType == "Reps" {
                Text("\(Int(set.secondaryMetricValue)) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func metricDisplay(for set: SetEntity) -> some View {
        HStack(spacing: 2) {
            if set.usePrimarySplitMetrics {
                Text("L: \(Int(set.primaryMetricValueLeft))")
                    .font(.subheadline)
                Text("R: \(Int(set.primaryMetricValueRight))")
                    .font(.subheadline)
            } else {
                Text("\(Int(set.primaryMetricValue))")
                    .font(.subheadline)
            }
            
            Text(set.primaryMetricUnit ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
            
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
    
    // MARK: - Helper Methods
    
    private struct LogInfo: Identifiable {
        let id = UUID()
        let log: MovementLog
        let formattedDate: String
        let workoutName: String
    }
    
    private func getFormattedLogs() -> [LogInfo] {
        guard let movementLogs = movement.movementLogs else { return [] }
        
        // Convert to array
        let logsArray = Array(movementLogs)
        
        // Sort by date
        let sortedLogs = logsArray.sorted { 
            let date1 = $0.date ?? Date.distantPast
            let date2 = $1.date ?? Date.distantPast
            return date1 > date2 
        }
        
        // Apply limit if not showing all
        let logsToProcess = showAll ? sortedLogs : Array(sortedLogs.prefix(3))
        
        // Format data for display
        return logsToProcess.map { log in
            LogInfo(
                log: log,
                formattedDate: log.formattedDate,
                workoutName: log.workout?.workoutName ?? "Unknown Workout"
            )
        }
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

// MovementGraphView is defined in MovementGraphView.swift
