//
//  MetricType+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
//
//

import Foundation
import CoreData


extension MetricType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetricType> {
        return NSFetchRequest<MetricType>(entityName: "MetricType")
    }

    @NSManaged public var alternativeUnits: String?
    @NSManaged public var defaultUnit: String?
    @NSManaged public var name: String?

}

extension MetricType : Identifiable {

}
