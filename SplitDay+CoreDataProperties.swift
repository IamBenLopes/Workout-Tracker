//
//  SplitDay+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/1/24.
//
//

import Foundation
import CoreData


extension SplitDay {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SplitDay> {
        return NSFetchRequest<SplitDay>(entityName: "SplitDay")
    }

    @NSManaged public var dayName: String?
    @NSManaged public var dayNumber: Int16
    @NSManaged public var isCompleted: Bool
    @NSManaged public var splitDayId: UUID?
    @NSManaged public var movements: Movement?
    @NSManaged public var splitDayMovements: NSSet?
    @NSManaged public var workoutSplit: WorkoutSplit?
    @NSManaged public var workoutSplitDay: NSSet?

}

// MARK: Generated accessors for splitDayMovements
extension SplitDay {

    @objc(addSplitDayMovementsObject:)
    @NSManaged public func addToSplitDayMovements(_ value: SplitDayMovement)

    @objc(removeSplitDayMovementsObject:)
    @NSManaged public func removeFromSplitDayMovements(_ value: SplitDayMovement)

    @objc(addSplitDayMovements:)
    @NSManaged public func addToSplitDayMovements(_ values: NSSet)

    @objc(removeSplitDayMovements:)
    @NSManaged public func removeFromSplitDayMovements(_ values: NSSet)

}

// MARK: Generated accessors for workoutSplitDay
extension SplitDay {

    @objc(addWorkoutSplitDayObject:)
    @NSManaged public func addToWorkoutSplitDay(_ value: WorkoutSplitDay)

    @objc(removeWorkoutSplitDayObject:)
    @NSManaged public func removeFromWorkoutSplitDay(_ value: WorkoutSplitDay)

    @objc(addWorkoutSplitDay:)
    @NSManaged public func addToWorkoutSplitDay(_ values: NSSet)

    @objc(removeWorkoutSplitDay:)
    @NSManaged public func removeFromWorkoutSplitDay(_ values: NSSet)

}

extension SplitDay : Identifiable {

}
