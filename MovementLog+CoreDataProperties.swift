//
//  MovementLog+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/15/24.
//
//

import Foundation
import CoreData


extension MovementLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MovementLog> {
        return NSFetchRequest<MovementLog>(entityName: "MovementLog")
    }

    @NSManaged public var date: Date?
    @NSManaged public var movementLogId: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var reps: String?
    @NSManaged public var weight: String?
    @NSManaged public var logOrder: Int16
    @NSManaged public var movement: Movement?
    @NSManaged public var sets: NSSet?
    @NSManaged public var workout: Workout?
    @NSManaged public var logCount: Int32

}

// MARK: Generated accessors for sets
extension MovementLog {

    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: SetEntity)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: SetEntity)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSSet)

}

extension MovementLog : Identifiable {

}

extension MovementLog {
    static func countWeeklySets(for muscleGroup: MuscleGroup, in context: NSManagedObjectContext) -> [Int] {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "movement.muscleGroups CONTAINS %@ AND date >= %@", muscleGroup, thirtyDaysAgo as NSDate)
        
        do {
            let logs = try context.fetch(fetchRequest)
            var weeklySets = [0, 0, 0, 0]
            
            for log in logs {
                if let date = log.date, let weekIndex = calendar.dateComponents([.weekOfMonth], from: date, to: today).weekOfMonth {
                    let setCount = log.sets?.count ?? 0
                    if weekIndex < 4 {
                        weeklySets[3 - weekIndex] += setCount
                    }
                }
            }
            
            return weeklySets
        } catch {
            print("Error fetching movement logs: \(error)")
            return [0, 0, 0, 0]
        }
    }

    var firstSetDate: Date? {
        guard let sets = sets as? Set<SetEntity> else { return nil }
        return sets.compactMap { $0.date }.min()
    }
}
