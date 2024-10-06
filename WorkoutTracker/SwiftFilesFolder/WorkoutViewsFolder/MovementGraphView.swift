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

    var body: some View {
        ScrollView {
            VStack {
                if #available(iOS 16.0, *) {
                    if weightData.isEmpty {
                        Text("No data available for this movement.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        // Weight Chart
                        Text("Average Weight per Set")
                            .font(.headline)
                            .padding(.top)

                        Chart(weightData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Average Weight", dataPoint.value)
                            )
                            .foregroundStyle(.blue)
                            .symbol(.circle)
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let frame = getPlotFrame(proxy, geometry: geometry)
                                                let currentX = value.location.x - frame.origin.x
                                                guard currentX >= 0, currentX <= frame.width else {
                                                    return
                                                }
                                                guard let date: Date = proxy.value(atX: currentX) else {
                                                    return
                                                }
                                                selectedWeightPoint = weightData.min(by: {
                                                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                                })
                                            }
                                    )
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: true))
                        .frame(height: 300)
                        .padding()

                        // Weight Data Point Details
                        if let selectedPoint = selectedWeightPoint {
                            VStack(alignment: .leading) {
                                Text("Selected Weight Data:")
                                    .font(.headline)
                                Text("Date: \(selectedPoint.date.formatted(date: .abbreviated, time: .omitted))")
                                Text("Average Weight: \(String(format: "%.2f", selectedPoint.value))")
                                if let matchingRepsPoint = repsData.first(where: { $0.date == selectedPoint.date }) {
                                    Text("Average Reps: \(String(format: "%.2f", matchingRepsPoint.value))")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        // Reps Chart
                        Text("Average Reps per Set")
                            .font(.headline)
                            .padding(.top)

                        Chart(repsData) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Average Reps", dataPoint.value)
                            )
                            .foregroundStyle(.green)
                            .symbol(.square)
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let frame = getPlotFrame(proxy, geometry: geometry)
                                                let currentX = value.location.x - frame.origin.x
                                                guard currentX >= 0, currentX <= frame.width else {
                                                    return
                                                }
                                                guard let date: Date = proxy.value(atX: currentX) else {
                                                    return
                                                }
                                                selectedRepsPoint = repsData.min(by: {
                                                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                                })
                                            }
                                    )
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: true))
                        .frame(height: 300)
                        .padding()

                        // Reps Data Point Details
                        if let selectedPoint = selectedRepsPoint {
                            VStack(alignment: .leading) {
                                Text("Selected Reps Data:")
                                    .font(.headline)
                                Text("Date: \(selectedPoint.date.formatted(date: .abbreviated, time: .omitted))")
                                Text("Average Reps: \(String(format: "%.2f", selectedPoint.value))")
                                if let matchingWeightPoint = weightData.first(where: { $0.date == selectedPoint.date }) {
                                    Text("Average Weight: \(String(format: "%.2f", matchingWeightPoint.value))")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Text("Charts are only available in iOS 16 and later")
                }

                Text("Progress: \(calculateProgress())%")
                    .font(.headline)
                    .padding()
            }
            .navigationTitle(movement.name ?? "Unknown Movement")
            .onAppear {
                loadGraphData()
            }
        }
    }

    @available(iOS 16.0, *)
    private func getPlotFrame(_ proxy: ChartProxy, geometry: GeometryProxy) -> CGRect {
        if #available(iOS 17.0, *) {
            return geometry[proxy.plotFrame!]
        } else {
            return geometry[proxy.plotAreaFrame]
        }
    }

    private func loadGraphData() {
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "movement == %@", movement)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "workout.date", ascending: true)]

        do {
            let movementLogs = try viewContext.fetch(fetchRequest)

            var weightPoints: [DataPoint] = []
            var repsPoints: [DataPoint] = []

            for log in movementLogs {
                guard let workoutDate = log.workout?.date,
                      let sets = log.sets as? Set<SetEntity> else { continue }

                // Filter sets where primaryMetricType is "Weight" and secondaryMetricType is "Reps"
                let relevantSets = sets.filter { set in
                    (set.primaryMetricType == "Weight" && set.secondaryMetricType == "Reps") ||
                    (set.primaryMetricType == "Reps" && set.secondaryMetricType == "Weight")
                }

                // Collect weights and reps from sets
                var weights: [Double] = []
                var reps: [Double] = []

                for set in relevantSets {
                    let weight: Double
                    let rep: Double

                    if set.primaryMetricType == "Weight" && set.secondaryMetricType == "Reps" {
                        weight = set.primaryMetricValue
                        rep = set.secondaryMetricValue
                    } else if set.primaryMetricType == "Reps" && set.secondaryMetricType == "Weight" {
                        weight = set.secondaryMetricValue
                        rep = set.primaryMetricValue
                    } else {
                        continue
                    }

                    weights.append(weight)
                    reps.append(rep)
                }

                guard !weights.isEmpty else { continue }

                let averageWeight = weights.reduce(0, +) / Double(weights.count)
                let averageReps = reps.reduce(0, +) / Double(reps.count)

                weightPoints.append(DataPoint(date: workoutDate, value: averageWeight))
                repsPoints.append(DataPoint(date: workoutDate, value: averageReps))
            }

            self.weightData = weightPoints
            self.repsData = repsPoints

        } catch {
            print("Error fetching movement logs: \(error)")
        }
    }

    private func calculateProgress() -> String {
        // Calculate progress based on average weight per set
        let sortedWeightData = weightData.sorted { $0.date < $1.date }

        guard sortedWeightData.count >= 2,
              let firstPoint = sortedWeightData.first,
              let lastPoint = sortedWeightData.last,
              firstPoint.value > 0 else {
            return "0"
        }

        let progressPercentage = ((lastPoint.value - firstPoint.value) / firstPoint.value) * 100
        return String(format: "%.1f", progressPercentage)
    }

    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}
