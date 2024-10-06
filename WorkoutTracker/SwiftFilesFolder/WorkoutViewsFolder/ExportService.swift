import Foundation
import CoreData
import PDFKit

class ExportService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func generatePDF(for exportType: ExportManagerView.ExportType, startDate: Date, endDate: Date) -> URL? {
        let pdfData: Data
        
        switch exportType {
        case .byDate:
            pdfData = generateDateRangePDF(startDate: startDate, endDate: endDate)
        case .movements:
            pdfData = generateMovementsPDF(startDate: startDate, endDate: endDate)
        case .workouts:
            pdfData = generateWorkoutsPDF(startDate: startDate, endDate: endDate)
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "export_\(Date().formatted(.iso8601)).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    private func generateDateRangePDF(startDate: Date, endDate: Date) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Workout Tracker",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Workout Data Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let titleBottom = addTitle(pageRect: pageRect, text: "Workout Data Export")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let dateRangeString = "Date Range: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            var yOffset = addText(pageRect: pageRect, text: dateRangeString, textTop: titleBottom + 20)
            
            let workouts = fetchWorkouts(startDate: startDate, endDate: endDate)
            yOffset = addWorkoutsSummary(pageRect: pageRect, workouts: workouts, yOffset: yOffset + 20)
            
            for workout in workouts {
                if yOffset > pageRect.height - 100 {
                    context.beginPage()
                    yOffset = 20
                }
                yOffset = addWorkoutDetails(pageRect: pageRect, workout: workout, yOffset: yOffset)
            }
        }
        
        return data
    }
    
    private func generateMovementsPDF(startDate: Date, endDate: Date) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Workout Tracker",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Movements Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let titleBottom = addTitle(pageRect: pageRect, text: "Movements Export")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let dateRangeString = "Date Range: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            var yOffset = addText(pageRect: pageRect, text: dateRangeString, textTop: titleBottom + 20)
            
            let movements = fetchMovements(startDate: startDate, endDate: endDate)
            for movement in movements {
                if yOffset > pageRect.height - 100 {
                    context.beginPage()
                    yOffset = 20
                }
                yOffset = addMovementDetails(pageRect: pageRect, movement: movement, startDate: startDate, endDate: endDate, yOffset: yOffset)
            }
        }
        
        return data
    }
    
    private func generateWorkoutsPDF(startDate: Date, endDate: Date) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Workout Tracker",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Workouts Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let titleBottom = addTitle(pageRect: pageRect, text: "Workouts Export")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let dateRangeString = "Date Range: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            var yOffset = addText(pageRect: pageRect, text: dateRangeString, textTop: titleBottom + 20)
            
            let workouts = fetchWorkouts(startDate: startDate, endDate: endDate)
            yOffset = addWorkoutsSummary(pageRect: pageRect, workouts: workouts, yOffset: yOffset + 20)
            
            for workout in workouts {
                if yOffset > pageRect.height - 100 {
                    context.beginPage()
                    yOffset = 20
                }
                yOffset = addWorkoutDetails(pageRect: pageRect, workout: workout, yOffset: yOffset)
            }
        }
        
        return data
    }
    
    private func fetchWorkouts(startDate: Date, endDate: Date) -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching workouts: \(error)")
            return []
        }
    }
    
    private func fetchMovements(startDate: Date, endDate: Date) -> [Movement] {
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        request.predicate = NSPredicate(format: "ANY movementLogs.workout.date >= %@ AND ANY movementLogs.workout.date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Movement.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching movements: \(error)")
            return []
        }
    }
    
    private func addTitle(pageRect: CGRect, text: String) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 18.0)
        let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: titleFont]
        let attributedTitle = NSAttributedString(string: text, attributes: titleAttributes)
        let titleStringSize = attributedTitle.size()
        let titleStringRect = CGRect(x: (pageRect.width - titleStringSize.width) / 2.0,
                                     y: 36,
                                     width: titleStringSize.width,
                                     height: titleStringSize.height)
        attributedTitle.draw(in: titleStringRect)
        return titleStringRect.origin.y + titleStringRect.size.height
    }
    
    private func addText(pageRect: CGRect, text: String, textTop: CGFloat) -> CGFloat {
        let textFont = UIFont.systemFont(ofSize: 12.0)
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: textFont]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        let textRect = CGRect(x: 10, y: textTop, width: pageRect.width - 20, height: pageRect.height - textTop - 10)
        attributedText.draw(in: textRect)
        return textTop + attributedText.size().height
    }
    
    private func addWorkoutsSummary(pageRect: CGRect, workouts: [Workout], yOffset: CGFloat) -> CGFloat {
        var currentYOffset = yOffset
        
        let totalWorkouts = workouts.count
        
        var totalMovements = 0
        var totalSets = 0
        
        for workout in workouts {
            if let movementLogs = workout.movementLogs as? Set<MovementLog> {
                totalMovements += movementLogs.count
                for movementLog in movementLogs {
                    if let sets = movementLog.sets as? Set<SetEntity> {
                        totalSets += sets.count
                    }
                }
            }
        }
        
        currentYOffset = addText(pageRect: pageRect, text: "Total Workouts: \(totalWorkouts)", textTop: currentYOffset + 10)
        currentYOffset = addText(pageRect: pageRect, text: "Total Movements: \(totalMovements)", textTop: currentYOffset + 5)
        currentYOffset = addText(pageRect: pageRect, text: "Total Sets: \(totalSets)", textTop: currentYOffset + 5)
        
        return currentYOffset
    }
    
    private func addWorkoutDetails(pageRect: CGRect, workout: Workout, yOffset: CGFloat) -> CGFloat {
        var currentYOffset = yOffset
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        currentYOffset = addText(pageRect: pageRect, text: "Workout Date: \(dateFormatter.string(from: workout.date ?? Date()))", textTop: currentYOffset + 20)
        currentYOffset = addText(pageRect: pageRect, text: "Focus: \(workout.workoutFocus ?? "N/A")", textTop: currentYOffset + 5)
        currentYOffset = addText(pageRect: pageRect, text: "Pre-workout Pain: \(workout.prePainLevel)", textTop: currentYOffset + 5)
        currentYOffset = addText(pageRect: pageRect, text: "Post-workout Pain: \(workout.postPainLevel)", textTop: currentYOffset + 5)
        
        if let movementLogs = workout.movementLogs as? Set<MovementLog> {
            for movementLog in movementLogs {
                currentYOffset = addText(pageRect: pageRect, text: "Movement: \(movementLog.movement?.name ?? "Unknown")", textTop: currentYOffset + 10)
                if let sets = movementLog.sets as? Set<SetEntity> {
                    for set in sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                        currentYOffset = addText(pageRect: pageRect, text: "  Set \(set.setNumber): \(set.primaryMetricValue) \(set.primaryMetricUnit ?? "") \(set.primaryMetricType ?? ""), \(set.secondaryMetricValue) \(set.secondaryMetricUnit ?? "") \(set.secondaryMetricType ?? "")", textTop: currentYOffset + 5)
                    }
                }
            }
        }
        
        return currentYOffset
    }
    
    private func addMovementDetails(pageRect: CGRect, movement: Movement, startDate: Date, endDate: Date, yOffset: CGFloat) -> CGFloat {
        var currentYOffset = yOffset
        
        currentYOffset = addText(pageRect: pageRect, text: "Movement: \(movement.name ?? "Unknown")", textTop: currentYOffset + 20)
        currentYOffset = addText(pageRect: pageRect, text: "Type: \(movement.movementClass ?? "Unknown")", textTop: currentYOffset + 5)
        
        let movementLogs = fetchMovementLogs(for: movement, startDate: startDate, endDate: endDate)
        
        for movementLog in movementLogs {
            if let workout = movementLog.workout, let date = workout.date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                currentYOffset = addText(pageRect: pageRect, text: "Date: \(dateFormatter.string(from: date))", textTop: currentYOffset + 10)
                
                if let sets = movementLog.sets as? Set<SetEntity> {
                    for set in sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                        currentYOffset = addText(pageRect: pageRect, text: "  Set \(set.setNumber): \(set.primaryMetricValue) \(set.primaryMetricUnit ?? "") \(set.primaryMetricType ?? ""), \(set.secondaryMetricValue) \(set.secondaryMetricUnit ?? "") \(set.secondaryMetricType ?? "")", textTop: currentYOffset + 5)
                    }
                }
            }
        }
        
        return currentYOffset
    }
    
    private func fetchMovementLogs(for movement: Movement, startDate: Date, endDate: Date) -> [MovementLog] {
        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.predicate = NSPredicate(format: "movement == %@ AND workout.date >= %@ AND workout.date <= %@", movement, startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.workout?.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching movement logs: \(error)")
            return []
        }
    }
}
