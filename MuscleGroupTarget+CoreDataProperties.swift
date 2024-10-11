//
//  MuscleGroupTarget+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 10/11/24.
//
//

import Foundation
import CoreData


extension MuscleGroupTarget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MuscleGroupTarget> {
        return NSFetchRequest<MuscleGroupTarget>(entityName: "MuscleGroupTarget")
    }

    @NSManaged public var targetSetsPerWeek: Int16
    @NSManaged public var muscleGroup: MuscleGroup?

}

extension MuscleGroupTarget : Identifiable {

}
