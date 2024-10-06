import Foundation
import CoreData

extension WorkoutSplitDay {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSplitDay> {
        return NSFetchRequest<WorkoutSplitDay>(entityName: "WorkoutSplitDay")
    }

    @NSManaged public var workout: Workout?
    @NSManaged public var splitDay: SplitDay?
}

extension WorkoutSplitDay : Identifiable {
}
