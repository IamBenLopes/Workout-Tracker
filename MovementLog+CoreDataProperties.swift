//
//  MovementLog+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
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
    @NSManaged public var movement: Movement?
    @NSManaged public var sets: NSSet?
    @NSManaged public var workout: Workout?

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
