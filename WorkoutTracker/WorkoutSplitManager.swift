import SwiftUI
import CoreData

class WorkoutSplitManager: ObservableObject {
    @Published var workoutSplits: [WorkoutSplit] = []
    @Published private(set) var allMovements: [Movement] = []
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAllWorkoutSplits()
        do {
            _ = try fetchAllMovements()
        } catch {
            print("Failed to fetch all movements: \(error)")
        }
    }

    // MARK: - Fetching Data

    func fetchAllWorkoutSplits() {
        let request: NSFetchRequest<WorkoutSplit> = WorkoutSplit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSplit.createdDate, ascending: false)]
        do {
            workoutSplits = try context.fetch(request)
        } catch {
            print("Failed to fetch workout splits: \(error)")
        }
    }

    func fetchAllMovements() throws -> [Movement] {
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Movement.name, ascending: true)]
        allMovements = try context.fetch(request)
        return allMovements
    }

    func getAllMovements() -> [Movement] {
        return allMovements
    }

    // MARK: - Managing Workout Splits

    func addWorkoutSplit(name: String, days: [(Int, String)]) -> Bool {
        let newSplit = WorkoutSplit(context: context)
        newSplit.splitId = UUID()
        newSplit.splitName = name
        newSplit.createdDate = Date()
        newSplit.lastModifiedDate = Date()
        newSplit.isActive = false

        for (dayNumber, dayName) in days {
            let newDay = SplitDay(context: context)
            newDay.splitDayId = UUID()
            newDay.dayNumber = Int16(dayNumber)
            newDay.dayName = dayName
            newDay.workoutSplit = newSplit
            newDay.isCompleted = false
        }

        return saveContext()
    }

    func deleteWorkoutSplit(_ split: WorkoutSplit) -> Bool {
        context.delete(split)
        return saveContext()
    }

    func activateWorkoutSplit(_ split: WorkoutSplit) -> Bool {
        // Deactivate all other splits
        for otherSplit in workoutSplits {
            otherSplit.isActive = false
        }
        
        // Activate the selected split
        split.isActive = true
        split.lastModifiedDate = Date()
        
        return saveContext()
    }

    func deactivateWorkoutSplit(_ split: WorkoutSplit) -> Bool {
        split.isActive = false
        split.lastModifiedDate = Date()
        return saveContext()
    }

    func getActiveWorkoutSplit() -> WorkoutSplit? {
        return workoutSplits.first { $0.isActive }
    }

    // MARK: - Managing Split Days

    func completeSplitDay(_ splitDay: SplitDay) -> Bool {
        splitDay.isCompleted = true
        splitDay.workoutSplit?.lastModifiedDate = Date()
        return saveContext()
    }

    func resetWeeklyProgress() -> Bool {
        for split in workoutSplits {
            for day in split.sortedSplitDays {
                day.isCompleted = false
            }
            split.lastModifiedDate = Date()
        }
        return saveContext()
    }

    // MARK: - Managing Movements

    func addMovementToSplitDay(_ movement: Movement, splitDay: SplitDay) -> Bool {
        // Check if the movement already exists in the split day
        if let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement>,
           splitDayMovements.contains(where: { $0.movement == movement }) {
            // Movement already exists, no need to add it again
            return true
        }

        let splitDayMovement = SplitDayMovement(context: context)
        splitDayMovement.movement = movement
        splitDayMovement.splitDay = splitDay
        splitDayMovement.order = Int16((splitDay.splitDayMovements?.count ?? 0))
        // Note: Assuming that splitDay.splitDayMovements is a to-many relationship

        splitDay.workoutSplit?.lastModifiedDate = Date()
        
        return saveContext()
    }

    func removeMovementFromSplitDay(_ movement: Movement, splitDay: SplitDay) -> Bool {
        guard let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement> else {
            return false
        }

        if let splitDayMovementToRemove = splitDayMovements.first(where: { $0.movement == movement }) {
            context.delete(splitDayMovementToRemove)
            splitDay.workoutSplit?.lastModifiedDate = Date()
            return saveContext()
        }

        return false
    }

    func updateMovementOrder(for splitDay: SplitDay, movements: [Movement]) -> Bool {
        guard let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement> else {
            return false
        }

        for (index, movement) in movements.enumerated() {
            if let splitDayMovement = splitDayMovements.first(where: { $0.movement == movement }) {
                splitDayMovement.order = Int16(index)
            }
        }

        splitDay.workoutSplit?.lastModifiedDate = Date()

        return saveContext()
    }

    // MARK: - Utility Methods

    func saveContext() -> Bool {
        do {
            try context.save()
            fetchAllWorkoutSplits()
            _ = try fetchAllMovements()
            return true
        } catch {
            print("Failed to save context: \(error)")
            return false
        }
    }
}

extension WorkoutSplit {
    var sortedSplitDays: [SplitDay] {
        let days = splitDays?.allObjects as? [SplitDay] ?? []
        return days.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    var remainingDaysThisWeek: Int {
        let completedDays = sortedSplitDays.filter { $0.isCompleted }.count
        return max(0, sortedSplitDays.count - completedDays)
    }
}
