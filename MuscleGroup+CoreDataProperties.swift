import Foundation
import CoreData

extension MuscleGroup {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MuscleGroup> {
        return NSFetchRequest<MuscleGroup>(entityName: "MuscleGroup")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var muscleGroupDescription: String?
    @NSManaged public var movements: NSSet?
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
    // This conformance allows MuscleGroup to be used with SwiftUI's ForEach and List
}
