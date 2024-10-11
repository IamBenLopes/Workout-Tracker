//
//  Workout+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
//
//

import Foundation
import CoreData


extension Workout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var date: Date?
    @NSManaged public var postNotes: String?
    @NSManaged public var postPainLevel: Int16
    @NSManaged public var prePainLevel: Int16
    @NSManaged public var splitDayNumber: Int16
    @NSManaged public var workoutFocus: String?
    @NSManaged public var workoutId: UUID?
    @NSManaged public var workoutName: String?
    @NSManaged public var movementLogs: NSSet?
    @NSManaged public var workoutSplit: WorkoutSplit?
    @NSManaged public var workoutSplitDay: NSSet?

}

// MARK: Generated accessors for movementLogs
extension Workout {

    @objc(addMovementLogsObject:)
    @NSManaged public func addToMovementLogs(_ value: MovementLog)

    @objc(removeMovementLogsObject:)
    @NSManaged public func removeFromMovementLogs(_ value: MovementLog)

    @objc(addMovementLogs:)
    @NSManaged public func addToMovementLogs(_ values: NSSet)

    @objc(removeMovementLogs:)
    @NSManaged public func removeFromMovementLogs(_ values: NSSet)

}

// MARK: Generated accessors for workoutSplitDay

extension Workout {
    
    @objc(addWorkoutSplitDayObject:)
    @NSManaged public func addToWorkoutSplitDay(_ value: WorkoutSplitDay)

    @objc(removeWorkoutSplitDayObject:)
    @NSManaged public func removeFromWorkoutSplitDay(_ value: WorkoutSplitDay)

    @objc(addWorkoutSplitDay:)
    @NSManaged public func addToWorkoutSplitDay(_ values: NSSet)

    @objc(removeWorkoutSplitDay:)
    @NSManaged public func removeFromWorkoutSplitDay(_ values: NSSet)
}
