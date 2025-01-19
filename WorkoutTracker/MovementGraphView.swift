import SwiftUI
import Charts
import CoreData

struct MovementGraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var movement: Movement
    @State private var weightData: [DataPoint] = []
    @State private var repsData: [DataPoint] = []
    @State private var selectedWeightPoint: DataPoint?
    @State private var selectedRepsPoint: DataPoint?
    @State private var timeRange: TimeRange = .month
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) { // Following consistent spacing guidelines
                // Time Range Picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: timeRange) { _, _ in
                    loadGraphData()
                }
                
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
                        
                        repsChartSection
                        
                        if let selectedPoint = selectedRepsPoint {
                            repsDataDetailView(for: selectedPoint)
                        }
                    }
                } else {
                    Text("Charts require iOS 16 or later")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding()
                }
                
                progressSection
            }
            .padding(.vertical)
        }
        .navigationTitle(movement.name ?? "Unknown Movement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
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
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    @available(iOS 16.0, *)
    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Max Weight per Workout")
                .font(.title3)
                .padding(.horizontal)
            
            Chart(weightData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Weight (lbs)", dataPoint.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue.gradient)
                .symbol(.circle)
                .symbolSize(50)
            }
            .frame(height: 300)
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    @available(iOS 16.0, *)
    private var repsChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Average Volume per Set (Weight × Reps)")
                .font(.title3)
                .padding(.horizontal)
            
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
            .frame(height: 300)
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func weightDataDetailView(for point: DataPoint) -> some View {
        let matchingRepsPoint = repsData.first { $0.date == point.date }
        return DataPointDetailCard(
            title: "Weight Details",
            date: point.date,
            primaryValue: ("Weight", point.value),
            secondaryValue: matchingRepsPoint.map { ("Reps", $0.value) }
        )
    }
    
    private func repsDataDetailView(for point: DataPoint) -> some View {
        let matchingWeightPoint = weightData.first { $0.date == point.date }
        return DataPointDetailCard(
            title: "Reps Details",
            date: point.date,
            primaryValue: ("Reps", point.value),
            secondaryValue: matchingWeightPoint.map { ("Weight", $0.value) }
        )
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            Text("Overall Progress")
                .font(.headline)
            
            Text("\(calculateProgress())%")
                .font(.title)
                .foregroundColor(calculateProgress().starts(with: "-") ? .red : .green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    
    private struct DataPointDetailCard: View {
        let title: String
        let date: Date
        let primaryValue: (label: String, value: Double)
        let secondaryValue: (label: String, value: Double)?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    DataValueView(label: primaryValue.label, value: primaryValue.value)
                    
                    if let secondary = secondaryValue {
                        DataValueView(label: secondary.label, value: secondary.value)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private struct DataValueView: View {
        let label: String
        let value: Double
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", value) as String)
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadGraphData() {
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        let cutoffDate: Date = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        
        fetchRequest.predicate = NSPredicate(format: "movement == %@ AND workout.date >= %@", 
                                           argumentArray: [movement, cutoffDate])
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.workout?.date, ascending: true)]

        do {
            let movementLogs = try viewContext.fetch(fetchRequest)
            processGraphData(from: movementLogs)
        } catch {
            print("Error fetching movement logs: \(error)")
        }
    }

    private func processGraphData(from logs: [MovementLog]) {
        var weightPoints: [DataPoint] = []
        var volumePoints: [DataPoint] = []

        for log in logs {
            guard let workoutDate = log.workout?.date,
                  let sets = log.sets as? Set<SetEntity> else { continue }

            let relevantSets = sets.filter { set in
                (set.primaryMetricType == "Weight" && set.secondaryMetricType == "Reps") ||
                (set.primaryMetricType == "Reps" && set.secondaryMetricType == "Weight")
            }

            var totalVolume: Double = 0
            var maxWeight: Double = 0

            for set in relevantSets {
                let weight: Double
                let reps: Double
                
                if set.primaryMetricType == "Weight" {
                    weight = set.primaryMetricValue
                    reps = set.secondaryMetricValue
                } else {
                    weight = set.secondaryMetricValue
                    reps = set.primaryMetricValue
                }
                
                // Calculate volume (weight × reps)
                totalVolume += weight * reps
                // Track max weight
                maxWeight = max(maxWeight, weight)
            }

            if !relevantSets.isEmpty {
                let avgVolume = totalVolume / Double(relevantSets.count)
                weightPoints.append(DataPoint(date: workoutDate, value: maxWeight))
                volumePoints.append(DataPoint(date: workoutDate, value: avgVolume))
            }
        }

        self.weightData = weightPoints
        self.repsData = volumePoints // Using repsData for volume
    }

    @available(iOS 16.0, *)
    private func createWeightChartOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        updateSelectedWeightPoint(value: value, proxy: proxy, geometry: geometry)
                    }
            )
    }

    @available(iOS 16.0, *)
    private func createRepsChartOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        updateSelectedRepsPoint(value: value, proxy: proxy, geometry: geometry)
                    }
            )
    }

    @available(iOS 16.0, *)
    private func updateSelectedWeightPoint(value: DragGesture.Value, proxy: ChartProxy, geometry: GeometryProxy) {
        let frame = getPlotFrame(proxy, geometry: geometry)
        let currentX = value.location.x - frame.origin.x
        
        guard currentX >= 0, currentX <= frame.width,
              let date: Date = proxy.value(atX: currentX) else {
            return
        }
        
        selectedWeightPoint = weightData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    @available(iOS 16.0, *)
    private func updateSelectedRepsPoint(value: DragGesture.Value, proxy: ChartProxy, geometry: GeometryProxy) {
        let frame = getPlotFrame(proxy, geometry: geometry)
        let currentX = value.location.x - frame.origin.x
        
        guard currentX >= 0, currentX <= frame.width,
              let date: Date = proxy.value(atX: currentX) else {
            return
        }
        
        selectedRepsPoint = repsData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    @available(iOS 16.0, *)
    private func getPlotFrame(_ proxy: ChartProxy, geometry: GeometryProxy) -> CGRect {
        if #available(iOS 17.0, *) {
            return geometry[proxy.plotFrame!]
        } else {
            return geometry[proxy.plotAreaFrame]
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
}
