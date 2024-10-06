//
//  WorkoutSplit+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
//
//

import Foundation
import CoreData


extension WorkoutSplit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSplit> {
        return NSFetchRequest<WorkoutSplit>(entityName: "WorkoutSplit")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var splitId: UUID?
    @NSManaged public var splitName: String?
    @NSManaged public var splitDays: NSSet?
    @NSManaged public var workouts: Workout?

}

// MARK: Generated accessors for splitDays
extension WorkoutSplit {

    @objc(addSplitDaysObject:)
    @NSManaged public func addToSplitDays(_ value: SplitDay)

    @objc(removeSplitDaysObject:)
    @NSManaged public func removeFromSplitDays(_ value: SplitDay)

    @objc(addSplitDays:)
    @NSManaged public func addToSplitDays(_ values: NSSet)

    @objc(removeSplitDays:)
    @NSManaged public func removeFromSplitDays(_ values: NSSet)

}

extension WorkoutSplit : Identifiable {

}
