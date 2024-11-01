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
    
    func deleteMovementLog(at offsets: IndexSet) {
        for index in offsets {
            guard index < movementLogsArray.count else { continue }
            let movementLog = movementLogsArray[index]
            managedObjectContext?.delete(movementLog)
        }
        do {
            try managedObjectContext?.save()
        } catch {
            print("Error deleting movement log: \(error)")
        }
    }
}