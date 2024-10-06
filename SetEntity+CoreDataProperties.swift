//
//  SetEntity+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
//
//

import Foundation
import CoreData


extension SetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SetEntity> {
        return NSFetchRequest<SetEntity>(entityName: "SetEntity")
    }

    @NSManaged public var notes: String?
    @NSManaged public var primaryMetricType: String?
    @NSManaged public var primaryMetricUnit: String?
    @NSManaged public var primaryMetricValue: Double
    @NSManaged public var secondaryMetricType: String?
    @NSManaged public var secondaryMetricUnit: String?
    @NSManaged public var secondaryMetricValue: Double
    @NSManaged public var setEntityId: UUID?
    @NSManaged public var setNumber: Int16
    @NSManaged public var movementLog: MovementLog?

}

extension SetEntity : Identifiable {

}
