import Foundation
import CoreData
import RichTextKit

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
}

extension SetEntity {
    var formattedPrimaryMetricValue: String {
        String(format: "%.2f", primaryMetricValue)
    }
    
    var formattedSecondaryMetricValue: String {
        String(format: "%.2f", secondaryMetricValue)
    }
}
