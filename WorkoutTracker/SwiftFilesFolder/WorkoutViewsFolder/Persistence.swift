import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WorkoutTracker")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Preview setup
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for preview
        for i in 0..<5 {
            let newWorkout = Workout(context: viewContext)
            newWorkout.workoutId = UUID()
            newWorkout.date = Date()
            newWorkout.workoutName = "Workout \(i + 1)"
            newWorkout.workoutFocus = "Strength"
            newWorkout.prePainLevel = 2
            newWorkout.postPainLevel = 1

            let movement = Movement(context: viewContext)
            movement.movementId = UUID()
            movement.name = "Bench Press"
            movement.movementClass = "Strength"

            let movementLog = MovementLog(context: viewContext)
            movementLog.movementLogId = UUID()
            movementLog.workout = newWorkout
            movementLog.movement = movement

            let set = SetEntity(context: viewContext)
            set.setEntityId = UUID()
            set.setNumber = 1
            set.primaryMetricType = "Reps"
            set.primaryMetricValue = 10
            set.primaryMetricUnit = "kg"
            set.notes = "Felt strong"

            movementLog.addToSets(set)
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
}
