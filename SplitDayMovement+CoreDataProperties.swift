//
//  SplitDayMovement+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/1/24.
//
//

import Foundation
import CoreData


extension SplitDayMovement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SplitDayMovement> {
        return NSFetchRequest<SplitDayMovement>(entityName: "SplitDayMovement")
    }

    @NSManaged public var order: Int16
    @NSManaged public var movement: Movement?
    @NSManaged public var splitDay: SplitDay?

}

extension SplitDayMovement : Identifiable {

}
