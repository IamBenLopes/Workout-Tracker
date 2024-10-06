import Foundation
import CoreData

extension Workout: Identifiable {
    public var id: UUID {
        return workoutId ?? UUID()
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date ?? Date())
    }

    var totalMovements: Int {
        return movementLogs?.count ?? 0
    }

    // You can add more helper methods or computed properties here as needed
}
