import Foundation
import CoreData

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
        let set = movementLogs as? Set<MovementLog> ?? []
        return set.sorted { $0.logOrder < $1.logOrder }
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
