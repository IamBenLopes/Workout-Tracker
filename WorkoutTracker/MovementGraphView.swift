import SwiftUI
import Charts
import CoreData

struct MovementGraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var movement: Movement
    @State private var weightData: [MovementDataPoint] = []
    @State private var repsData: [MovementDataPoint] = []
    @State private var selectedWeightPoint: MovementDataPoint?
    @State private var selectedRepsPoint: MovementDataPoint?
    @Binding var timeRange: TimeRange
    
    init(movement: Movement, timeRange: Binding<TimeRange>) {
        self.movement = movement
        self._timeRange = timeRange
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if #available(iOS 16.0, *) {
                if weightData.isEmpty {
                    emptyStateView
                } else {
                    weightChartSection
                    
                    if let selectedPoint = selectedWeightPoint {
                        weightDataDetailView(for: selectedPoint)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    if !repsData.isEmpty {
                        repsChartSection
                        
                        if let selectedPoint = selectedRepsPoint {
                            repsDataDetailView(for: selectedPoint)
                        }
                    }
                    
                    progressSection
                }
            } else {
                // Fallback for iOS 15 or earlier
                Text("Charts require iOS 16 or later")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
        .navigationTitle(movement.name ?? "Unknown Movement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGraphData()
        }
        .onChange(of: timeRange) { _, _ in
            loadGraphData()
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 44)) // Following minimum touch target size
                .foregroundColor(.secondary)
            Text("No data available")
                .font(.headline)
            Text("Complete workouts to see your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    @available(iOS 16.0, *)
    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Max Weight per Workout")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let maxWeight = weightData.max(by: { $0.value < $1.value })?.value {
                    Text("Max: \(String(format: "%.1f", maxWeight)) \(getMetricUnit())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                Chart(weightData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.gradient)
                    .symbol(.circle)
                    .symbolSize(50)
                }
                .frame(height: min(300, geometry.size.height * 0.8))
                .chartXAxis {
                    AxisMarks(preset: .aligned) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.gray.opacity(0.1))
                        .border(.gray.opacity(0.2))
                }
                .padding()
            }
            .frame(minHeight: 300)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    @available(iOS 16.0, *)
    private var repsChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Average Volume per Set")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let maxVolume = repsData.max(by: { $0.value < $1.value })?.value {
                    Text("Max: \(String(format: "%.1f", maxVolume))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                Chart(repsData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Volume", dataPoint.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.green.gradient)
                    .symbol(.circle)
                    .symbolSize(50)
                }
                .frame(height: min(300, geometry.size.height * 0.8))
                .chartXAxis {
                    AxisMarks(preset: .aligned) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.gray.opacity(0.1))
                        .border(.gray.opacity(0.2))
                }
                .padding()
            }
            .frame(minHeight: 300)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func weightDataDetailView(for point: MovementDataPoint) -> some View {
        let matchingRepsPoint = repsData.first { $0.date == point.date }
        return DataPointDetailCard(
            title: "Weight Details",
            date: point.date,
            metrics: [
                MetricDetail(label: "Weight", value: point.value, unit: getMetricUnit()),
                MetricDetail(label: "Volume", value: matchingRepsPoint?.value ?? 0, unit: "total")
            ]
        )
    }
    
    private func repsDataDetailView(for point: MovementDataPoint) -> some View {
        let matchingWeightPoint = weightData.first { $0.date == point.date }
        return DataPointDetailCard(
            title: "Volume Details",
            date: point.date,
            metrics: [
                MetricDetail(label: "Volume", value: point.value, unit: "total"),
                MetricDetail(label: "Weight", value: matchingWeightPoint?.value ?? 0, unit: getMetricUnit())
            ]
        )
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress Overview")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(calculateProgress())
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("%")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time Period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(timeRange.rawValue)
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Data Loading
    
    private func loadGraphData() {
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        let cutoffDate: Date = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        
        fetchRequest.predicate = NSPredicate(format: "movement == %@ AND workout.date >= %@", 
                                            movement, cutoffDate as NSDate)
        
        do {
            let logs = try viewContext.fetch(fetchRequest)
            
            // Process logs to extract data points
            var weightPoints: [MovementDataPoint] = []
            var repsPoints: [MovementDataPoint] = []
            
            // Group logs by date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            
            let groupedLogs = Dictionary(grouping: logs) { log in
                let date = log.date ?? Date()
                return dateFormatter.string(from: date)
            }
            
            for (dateString, logs) in groupedLogs {
                guard let date = dateFormatter.date(from: dateString) else { continue }
                
                // Find max weight for this date
                var maxWeight: Double = 0
                var totalVolume: Double = 0
                var setCount: Int = 0
                
                for log in logs {
                    for set in log.setsArray {
                        let weight = set.usePrimarySplitMetrics ? 
                            max(set.primaryMetricValueLeft, set.primaryMetricValueRight) : 
                            set.primaryMetricValue
                        
                        maxWeight = max(maxWeight, weight)
                        
                        // Calculate volume (weight × reps)
                        if set.secondaryMetricType == "Reps" {
                            let reps = set.secondaryMetricValue
                            totalVolume += weight * reps
                            setCount += 1
                        }
                    }
                }
                
                // Add data points if we have valid data
                if maxWeight > 0 {
                    weightPoints.append(MovementDataPoint(date: date, value: maxWeight))
                }
                
                if setCount > 0 {
                    let avgVolumePerSet = totalVolume / Double(setCount)
                    repsPoints.append(MovementDataPoint(date: date, value: avgVolumePerSet))
                }
            }
            
            // Sort by date
            weightPoints.sort { $0.date < $1.date }
            repsPoints.sort { $0.date < $1.date }
            
            // Update state
            self.weightData = weightPoints
            self.repsData = repsPoints
            
        } catch {
            print("Error loading graph data: \(error)")
        }
    }
    
    private func calculateProgress() -> String {
        guard let firstLog = weightData.first,
              let lastLog = weightData.last,
              firstLog.value > 0 else {
            return "0.0"
        }
        
        let progressPercentage = ((lastLog.value - firstLog.value) / firstLog.value) * 100
        return String(format: "%.1f", progressPercentage)
    }
    
    // Helper function to get the unit from the movement or its sets
    private func getMetricUnit() -> String {
        // Try to find the unit from the movement logs
        if let logs = movement.movementLogs,
           let logsArray = (logs as NSSet).allObjects as? [MovementLog],
           !logsArray.isEmpty,
           let firstLog = logsArray.first,
           let sets = firstLog.sets,
           let setsArray = (sets as NSSet).allObjects as? [SetEntity],
           !setsArray.isEmpty,
           let firstSet = setsArray.first {
            return firstSet.primaryMetricUnit ?? "lbs"
        }
        
        // Default unit if no logs found
        return "lbs"
    }
}

struct MovementDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricDetail {
    let label: String
    let value: Double
    let unit: String
}

struct DataPointDetailCard: View {
    let title: String
    let date: Date
    let metrics: [MetricDetail]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            ForEach(metrics.indices, id: \.self) { index in
                let metric = metrics[index]
                HStack {
                    Text(metric.label)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", metric.value)) \(metric.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
