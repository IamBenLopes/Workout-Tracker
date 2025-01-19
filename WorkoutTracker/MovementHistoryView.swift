import SwiftUI
import CoreData
import Charts

struct MovementHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var movement: Movement
    @State private var movementLogs: [MovementLog] = []
    @State private var showingEditView = false
    @State private var selectedTimeRange: TimeRange = .month
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats Card
                QuickStatsCard(movement: movement)
                
                // Progress Graph Card
                NavigationLink(destination: MovementGraphView(movement: movement)) {
                    ProgressPreviewCard(movement: movement)
                }
                
                // Movement Details Card
                MovementDetailsCard(movement: movement)
                
                // Recent Logs Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    ForEach(movementLogs.prefix(5), id: \.self) { log in
                        MovementLog.LogCard(log: log)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(movement.name ?? "Movement History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditView = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            MovementEditView(movement: movement)
        }
        .onAppear {
            fetchMovementLogs()
        }
    }
    
    private func fetchMovementLogs() {
        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.predicate = NSPredicate(format: "movement == %@", movement)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.date, ascending: false)]
        
        do {
            movementLogs = try viewContext.fetch(request)
        } catch {
            print("Error fetching movement logs: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct QuickStatsCard: View {
    @ObservedObject var movement: Movement
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(title: "Total Sets", value: "\(calculateTotalSets())")
                Divider()
                StatItem(title: "Last Active", value: formatLastActiveDate())
                Divider()
                StatItem(title: "Progress", value: "\(calculateProgress())%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func calculateTotalSets() -> Int {
        let logs = Array(movement.movementLogs ?? [])
        return logs.reduce(0) { total, log in
            total + (log.sets?.count ?? 0)
        }
    }
    
    private func formatLastActiveDate() -> String {
        let logs = Array(movement.movementLogs ?? [])
        guard let lastLog = logs.sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }).first,
              let date = lastLog.date else {
            return "Never"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func calculateProgress() -> String {
        // Implement progress calculation
        return "0"
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProgressPreviewCard: View {
    let movement: Movement
    @State private var previewData: [DataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress Overview")
                    .font(.headline)
                Spacer()
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.blue)
            }
            
            if #available(iOS 16.0, *) {
                if !previewData.isEmpty {
                    Chart(previewData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(.blue.gradient)
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 100)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                } else {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                }
            } else {
                // Fallback for iOS 15
                Text("Charts require iOS 16")
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            loadPreviewData()
        }
    }
    
    private func loadPreviewData() {
        guard let logs = movement.movementLogs else { return }
        
        let sortedLogs = Array(logs)
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            .suffix(10) // Get last 10 logs for preview
        
        previewData = sortedLogs.compactMap { log in
            guard let date = log.date,
                  let sets = log.sets as? Set<SetEntity>,
                  !sets.isEmpty else { return nil }
            
            // Calculate the max value for this log
            let maxValue = sets.reduce(0.0) { currentMax, set in
                if set.usePrimarySplitMetrics {
                    return max(currentMax, max(set.primaryMetricValueLeft, set.primaryMetricValueRight))
                } else {
                    return max(currentMax, set.primaryMetricValue)
                }
            }
            
            return DataPoint(date: date, value: maxValue)
        }
    }
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MovementDetailsCard: View {
    @ObservedObject var movement: Movement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Movement Details")
                .font(.headline)
            
            // Movement Type
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: getMovementIcon())
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(movement.movementClass ?? "Unknown")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Description (if exists)
            if let description = movement.movementDescription,
               !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Muscle Groups
            if let muscleGroups = movement.muscleGroups,
               !muscleGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Muscle Groups")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(Array(muscleGroups), id: \.self) { group in
                            Text(group.name ?? "")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func getMovementIcon() -> String {
        switch movement.movementClass {
        case "Strength": return "dumbbell.fill"
        case "Cardio": return "heart.circle.fill"
        case "Stretch": return "figure.flexibility"
        default: return "figure.walk"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}


struct SetSummaryRow: View {
    let set: SetEntity
    
    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44)
            
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
        .frame(minHeight: 44)
    }
    
    private func formatValue(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

// Update the FlowLayout implementation
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            spacing: spacing,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            spacing: spacing,
            subviews: subviews
        )
        
        for (index, subview) in subviews.enumerated() {
            let point = result.points[index]
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }
    
    private struct FlowResult {
        var size: CGSize = .zero
        var points: [CGPoint] = []
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                points.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                
                // Update total width
                size.width = max(size.width, currentX - spacing)
            }
            
            // Set final height
            size.height = currentY + lineHeight
        }
    }
}
