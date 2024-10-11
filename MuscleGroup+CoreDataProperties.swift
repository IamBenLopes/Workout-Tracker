//
//  MuscleGroup+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/11/24.
//
//

import Foundation
import CoreData


extension MuscleGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MuscleGroup> {
        return NSFetchRequest<MuscleGroup>(entityName: "MuscleGroup")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var muscleGroupDescription: String?
    @NSManaged public var name: String?
    @NSManaged public var movements: Set<Movement>?
    @NSManaged public var muscleGroupTarget: MuscleGroupTarget?

}

// MARK: Generated accessors for movements
extension MuscleGroup {

    @objc(addMovementsObject:)
    @NSManaged public func addToMovements(_ value: Movement)

    @objc(removeMovementsObject:)
    @NSManaged public func removeFromMovements(_ value: Movement)

    @objc(addMovements:)
    @NSManaged public func addToMovements(_ values: NSSet)

    @objc(removeMovements:)
    @NSManaged public func removeFromMovements(_ values: NSSet)

}

extension MuscleGroup : Identifiable {

}
