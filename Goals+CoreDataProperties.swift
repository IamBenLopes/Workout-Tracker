//
//  Goals+CoreDataProperties.swift
//  WorkoutTracker
//
//  Created by Benjamin Lopes on 9/28/24.
//
//

import Foundation
import CoreData


extension Goals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goals> {
        return NSFetchRequest<Goals>(entityName: "Goals")
    }

    @NSManaged public var cardio: String?
    @NSManaged public var flexibility: String?
    @NSManaged public var strength: String?
    @NSManaged public var weight: String?

}

extension Goals : Identifiable {

}
