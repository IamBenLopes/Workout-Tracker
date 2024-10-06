//
//  Movement+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/1/24.
//
//

import Foundation
import CoreData


extension Movement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Movement> {
        return NSFetchRequest<Movement>(entityName: "Movement")
    }

    @NSManaged public var movementClass: String?
    @NSManaged public var movementDescription: String?
    @NSManaged public var movementId: UUID?
    @NSManaged public var movementPhoto: Data?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var movementLogs: NSSet?
    @NSManaged public var splitDayMovement: NSSet?
    @NSManaged public var splitDays: SplitDay?

}

// MARK: Generated accessors for movementLogs
extension Movement {

    @objc(addMovementLogsObject:)
    @NSManaged public func addToMovementLogs(_ value: MovementLog)

    @objc(removeMovementLogsObject:)
    @NSManaged public func removeFromMovementLogs(_ value: MovementLog)

    @objc(addMovementLogs:)
    @NSManaged public func addToMovementLogs(_ values: NSSet)

    @objc(removeMovementLogs:)
    @NSManaged public func removeFromMovementLogs(_ values: NSSet)

}

// MARK: Generated accessors for splitDayMovement
extension Movement {

    @objc(addSplitDayMovementObject:)
    @NSManaged public func addToSplitDayMovement(_ value: SplitDayMovement)

    @objc(removeSplitDayMovementObject:)
    @NSManaged public func removeFromSplitDayMovement(_ value: SplitDayMovement)

    @objc(addSplitDayMovement:)
    @NSManaged public func addToSplitDayMovement(_ values: NSSet)

    @objc(removeSplitDayMovement:)
    @NSManaged public func removeFromSplitDayMovement(_ values: NSSet)

}

extension Movement : Identifiable {

}
