import Foundation
import CoreData
import SwiftUI

extension Workout {
    var displayName: String {
        if let workoutSplitDays = self.workoutSplitDay as? Set<WorkoutSplitDay>,
           let firstSplitDay = workoutSplitDays.first,
           let splitName = firstSplitDay.splitDay?.workoutSplit?.splitName,
           let dayNumber = firstSplitDay.splitDay?.dayNumber {
            return "\(splitName): Day \(dayNumber)"
        } else if let customName = self.workoutName, !customName.isEmpty {
            return customName
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let dateString = self.date.map { dateFormatter.string(from: $0) } ?? "Unknown Date"
            return "Workout on \(dateString)"
        }
    }

    var movementLogsArray: [MovementLog] {
        return sortedMovementLogs
    }
}

extension MovementLog {
    var setsArray: [SetEntity] {
        let setSet = sets as? Set<SetEntity> ?? []
        return setSet.sorted { $0.setNumber < $1.setNumber }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date ?? Date())
    }
    
    static func countSets(for muscleGroup: MuscleGroup, in context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "movement.muscleGroups CONTAINS %@ AND date >= %@", muscleGroup, thirtyDaysAgo as NSDate)
        
        do {
            let logs = try context.fetch(fetchRequest)
            let totalSets = logs.reduce(0) { $0 + ($1.sets?.count ?? 0) }
            return totalSets
        } catch {
            print("Error fetching logs: \(error)")
            return 0 // Return 0 if there's an error
        }
    }
}

extension SetEntity {
    var formattedPrimaryMetricValue: String {
        String(format: "%.2f", primaryMetricValue)
    }
    
    var formattedSecondaryMetricValue: String {
        String(format: "%.2f", secondaryMetricValue)
    }
}

extension MovementLog {
    struct LogCard: View {
        let log: MovementLog
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Header with date and workout name
                HStack {
                    Text(log.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let workout = log.workout {
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            Text(workout.displayName)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Sets
                if let sets = log.sets as? Set<SetEntity> {
                    VStack(spacing: 6) {
                        ForEach(Array(sets.sorted { $0.setNumber < $1.setNumber }), id: \.self) { set in
                            NavigationLink(destination: MovementLogDetailView(movementLog: log)) {
                                SetEntity.SetRow(set: set)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
}

extension SetEntity {
    struct SetRow: View {
        let set: SetEntity
        
        var body: some View {
            HStack(spacing: 12) {
                // Set Number
                Text("Set \(set.setNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 32, alignment: .leading)
                
                // Primary Metrics
                Group {
                    if set.usePrimarySplitMetrics {
                        if areValuesEqual(set.primaryMetricValueLeft, set.primaryMetricValueRight) {
                            // Show single value when L/R are equal
                            MetricView(
                                value: formatValue(set.primaryMetricValueLeft),
                                unit: set.primaryMetricUnit ?? ""
                            )
                        } else {
                            // Show L/R values when different
                            HStack(spacing: 4) {
                                // Left value
                                HStack(spacing: 2) {
                                    Text("L")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatValue(set.primaryMetricValueLeft))
                                        .font(.subheadline.weight(.medium))
                                }
                                
                                // Right value
                                HStack(spacing: 2) {
                                    Text("R")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatValue(set.primaryMetricValueRight))
                                        .font(.subheadline.weight(.medium))
                                }
                                
                                // Unit (shown once for both L/R)
                                Text(set.primaryMetricUnit ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        MetricView(
                            value: formatValue(set.primaryMetricValue),
                            unit: set.primaryMetricUnit ?? ""
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Secondary Metrics
                Group {
                    if set.useSecondarySplitMetrics {
                        if areValuesEqual(set.secondaryMetricValueLeft, set.secondaryMetricValueRight) {
                            // Show single value when L/R are equal
                            MetricView(
                                value: formatValue(set.secondaryMetricValueLeft),
                                unit: set.secondaryMetricUnit ?? ""
                            )
                        } else {
                            // Show L/R values when different
                            HStack(spacing: 4) {
                                // Left value
                                HStack(spacing: 2) {
                                    Text("L")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatValue(set.secondaryMetricValueLeft))
                                        .font(.subheadline.weight(.medium))
                                }
                                
                                // Right value
                                HStack(spacing: 2) {
                                    Text("R")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatValue(set.secondaryMetricValueRight))
                                        .font(.subheadline.weight(.medium))
                                }
                                
                                // Unit (shown once for both L/R)
                                Text(set.secondaryMetricUnit ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        MetricView(
                            value: formatValue(set.secondaryMetricValue),
                            unit: set.secondaryMetricUnit ?? ""
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        
        private struct MetricView: View {
            let label: String?
            let value: String
            let unit: String
            
            init(label: String? = nil, value: String, unit: String) {
                self.label = label
                self.value = value
                self.unit = unit
            }
            
            var body: some View {
                HStack(spacing: 4) {
                    if let label = label {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(value)
                        .font(.subheadline.weight(.medium))
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private func areValuesEqual(_ left: Double, _ right: Double) -> Bool {
            abs(left - right) < 0.01  // Using small epsilon for float comparison
        }
        
        private func formatValue(_ value: Double) -> String {
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", value)
            } else {
                return String(format: "%.1f", value)
            }
        }
    }
}
