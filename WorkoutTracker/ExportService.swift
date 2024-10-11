import Foundation
import CoreData
import PDFKit

class ExportService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func generatePDF(startDate: Date, endDate: Date) -> URL? {
        let pdfData = generateMovementsPDF(startDate: startDate, endDate: endDate)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "export_\(Date().formatted(.iso8601)).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            print("PDF file saved successfully at: \(fileURL.path)")
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    private func generateMovementsPDF(startDate: Date, endDate: Date) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Workout Tracker",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Movement Data Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            var currentPageNumber = 1
            context.beginPage()
            var yOffset = addHeader(pageRect: pageRect)
            yOffset = addTitle(pageRect: pageRect, text: "Movement Data Export", yOffset: yOffset)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let dateRangeString = "Date Range: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            yOffset = addText(pageRect: pageRect, text: dateRangeString, yOffset: yOffset, fontSize: 12)
            
            let workouts = fetchWorkouts(startDate: startDate, endDate: endDate)
            print("Number of workouts fetched: \(workouts.count)")
            
            for (index, workout) in workouts.enumerated() {
                print("Processing workout \(index + 1) of \(workouts.count)")
                
                if yOffset > pageRect.height - 100 {
                    addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
                    context.beginPage()
                    currentPageNumber += 1
                    yOffset = addHeader(pageRect: pageRect)
                }
                yOffset = addWorkoutDetails(pageRect: pageRect, workout: workout, yOffset: yOffset, context: context, currentPageNumber: &currentPageNumber)
            }
            addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
        }
        
        return data
    }
    
    private func addHeader(pageRect: CGRect) -> CGFloat {
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray
        ]
        let headerText = "Workout Tracker"
        let headerRect = CGRect(x: 36, y: 36, width: pageRect.width - 72, height: 20)
        headerText.draw(in: headerRect, withAttributes: headerAttributes)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 36, y: 60))
        path.addLine(to: CGPoint(x: pageRect.width - 36, y: 60))
        UIColor.lightGray.setStroke()
        path.stroke()
        
        return 70
    }
    
    private func addTitle(pageRect: CGRect, text: String, yOffset: CGFloat) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        let titleSize = text.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2, y: yOffset, width: titleSize.width, height: titleSize.height)
        text.draw(in: titleRect, withAttributes: titleAttributes)
        return yOffset + titleSize.height + 10
    }
    
    private func addText(pageRect: CGRect, text: String, yOffset: CGFloat, fontSize: CGFloat = 12, color: UIColor = .black, alignment: NSTextAlignment = .left) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let textRect = CGRect(x: 36, y: yOffset, width: pageRect.width - 72, height: CGFloat.greatestFiniteMagnitude)
        let textSize = text.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.greatestFiniteMagnitude),
                                         options: .usesLineFragmentOrigin,
                                         attributes: attributes,
                                         context: nil)
        text.draw(in: CGRect(x: textRect.minX, y: yOffset, width: textRect.width, height: textSize.height), withAttributes: attributes)
        return yOffset + textSize.height + 5
    }
    
    private func addWorkoutDetails(pageRect: CGRect, workout: Workout, yOffset: CGFloat, context: UIGraphicsPDFRendererContext, currentPageNumber: inout Int) -> CGFloat {
        var currentYOffset = yOffset
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        if currentYOffset + 50 > pageRect.height - 50 {
            addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
            context.beginPage()
            currentPageNumber += 1
            currentYOffset = addHeader(pageRect: pageRect)
        }
        
        currentYOffset = addText(pageRect: pageRect, text: "Workout on \(dateFormatter.string(from: workout.date ?? Date()))", yOffset: currentYOffset, fontSize: 16, color: .blue)
        
        // Workout details table
        let detailsItems: [(String, String)] = [
            ("Name", workout.workoutName ?? "N/A"),
            ("Focus", workout.workoutFocus ?? "N/A"),
            ("Pre-workout Pain", "\(workout.prePainLevel)"),
            ("Post-workout Pain", "\(workout.postPainLevel)"),
            ("Notes", workout.postNotes ?? "")
        ]

        
        currentYOffset = addDetailsTable(pageRect: pageRect, headers: ["Detail", "Value"], rows: detailsItems, yOffset: currentYOffset + 10, context: context, currentPageNumber: &currentPageNumber)
        
        if let movementLogs = workout.movementLogs as? Set<MovementLog> {
            for movementLog in movementLogs {
                if currentYOffset + 30 > pageRect.height - 50 {
                    addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
                    context.beginPage()
                    currentPageNumber += 1
                    currentYOffset = addHeader(pageRect: pageRect)
                }
                currentYOffset = addText(pageRect: pageRect, text: "\(movementLog.movement?.name ?? "Unknown")", yOffset: currentYOffset + 10, fontSize: 14, color: .darkGray)
                
                if let sets = movementLog.sets as? Set<SetEntity> {
                    let sortedSets = sets.sorted(by: { $0.setNumber < $1.setNumber })
                    guard let firstSet = sortedSets.first else { continue }
                    
                    let primaryMetricType = firstSet.primaryMetricType ?? "Metric 1"
                    let secondaryMetricType = firstSet.secondaryMetricType ?? "Metric 2"
                    
                    let headers = ["Set", primaryMetricType, secondaryMetricType, "Notes"]
                    let setRows: [[String]] = sortedSets.map { set in
                        return [
                            "\(set.setNumber)",
                            "\(set.primaryMetricValue) \(set.primaryMetricUnit ?? "")",
                            "\(set.secondaryMetricValue) \(set.secondaryMetricUnit ?? "")",
                            set.notes ?? ""
                        ]
                    }
                    currentYOffset = addTable(pageRect: pageRect, headers: headers, rows: setRows, yOffset: currentYOffset + 10, context: context, currentPageNumber: &currentPageNumber)
                }
            }
        }
        
        return currentYOffset + 20
    }
    
    private func addDetailsTable(pageRect: CGRect, headers: [String], rows: [(String, String)], yOffset: CGFloat, context: UIGraphicsPDFRendererContext, currentPageNumber: inout Int) -> CGFloat {
        var currentYOffset = yOffset
        let maxTableWidth = pageRect.width - 72
        let columnCount = headers.count
        let columnWidth = maxTableWidth / CGFloat(columnCount)
        
        // Draw headers
        let headerHeights = headers.map { header -> CGFloat in
            return heightForText(text: header, width: columnWidth - 4, font: UIFont.boldSystemFont(ofSize: 10))
        }
        let headerHeight = headerHeights.max() ?? 20
        
        for (index, header) in headers.enumerated() {
            let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: headerHeight)
            drawTableCell(text: header, in: rect, isHeader: true)
        }
        currentYOffset += headerHeight
        
        // Draw rows
        for row in rows {
            let texts = [row.0, row.1]
            let cellHeights = texts.enumerated().map { (index, text) -> CGFloat in
                return heightForText(text: text, width: columnWidth - 4, font: UIFont.systemFont(ofSize: 10))
            }
            let maxCellHeight = cellHeights.max() ?? 20
            
            if currentYOffset + maxCellHeight > pageRect.height - 50 {
                addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
                context.beginPage()
                currentPageNumber += 1
                currentYOffset = addHeader(pageRect: pageRect)
                
                // Redraw headers on new page
                for (index, header) in headers.enumerated() {
                    let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: headerHeight)
                    drawTableCell(text: header, in: rect, isHeader: true)
                }
                currentYOffset += headerHeight
            }
            
            for (index, text) in texts.enumerated() {
                let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: maxCellHeight)
                drawTableCell(text: text, in: rect, isHeader: false)
            }
            currentYOffset += maxCellHeight
        }
        
        return currentYOffset
    }
    
    private func addTable(pageRect: CGRect, headers: [String], rows: [[String]], yOffset: CGFloat, context: UIGraphicsPDFRendererContext, currentPageNumber: inout Int) -> CGFloat {
        var currentYOffset = yOffset
        let maxTableWidth = pageRect.width - 72
        let columnCount = headers.count
        let columnWidth = maxTableWidth / CGFloat(columnCount)
        
        let rowHeights: [CGFloat] = rows.map { row in
            let cellHeights = row.enumerated().map { (index, text) -> CGFloat in
                return heightForText(text: text, width: columnWidth - 4, font: UIFont.systemFont(ofSize: 10))
            }
            return cellHeights.max() ?? 20
        }
        
        let headerHeights = headers.map { header -> CGFloat in
            return heightForText(text: header, width: columnWidth - 4, font: UIFont.boldSystemFont(ofSize: 10))
        }
        let headerHeight = headerHeights.max() ?? 20
        
        // Draw headers
        for (index, header) in headers.enumerated() {
            let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: headerHeight)
            drawTableCell(text: header, in: rect, isHeader: true)
        }
        currentYOffset += headerHeight
        
        // Draw rows
        for (rowIndex, row) in rows.enumerated() {
            let maxCellHeight = rowHeights[rowIndex]
            
            if currentYOffset + maxCellHeight > pageRect.height - 50 {
                addFooter(pageRect: pageRect, pageNumber: currentPageNumber)
                context.beginPage()
                currentPageNumber += 1
                currentYOffset = addHeader(pageRect: pageRect)
                
                // Redraw headers on new page
                for (index, header) in headers.enumerated() {
                    let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: headerHeight)
                    drawTableCell(text: header, in: rect, isHeader: true)
                }
                currentYOffset += headerHeight
            }
            
            for (index, text) in row.enumerated() {
                let rect = CGRect(x: 36 + CGFloat(index) * columnWidth, y: currentYOffset, width: columnWidth, height: maxCellHeight)
                drawTableCell(text: text, in: rect, isHeader: false)
            }
            currentYOffset += maxCellHeight
        }
        
        return currentYOffset
    }
    
    private func drawTableCell(text: String, in rect: CGRect, isHeader: Bool) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(0.5)
        context?.stroke(rect)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: isHeader ? UIFont.boldSystemFont(ofSize: 10) : UIFont.systemFont(ofSize: 10),
            .paragraphStyle: paragraphStyle
        ]
        
        let insetRect = rect.insetBy(dx: 2, dy: 2)
        (text as NSString).draw(in: insetRect, withAttributes: attributes)
    }
    
    private func heightForText(text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: NSMutableParagraphStyle()
        ]
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let textSize = text.boundingRect(with: maxSize,
                                         options: .usesLineFragmentOrigin,
                                         attributes: attributes,
                                         context: nil).size
        return ceil(textSize.height) + 4
    }
    
    private func addFooter(pageRect: CGRect, pageNumber: Int) {
        let footer = "Page \(pageNumber)"
        let font = UIFont.systemFont(ofSize: 10)
        let attributes = [NSAttributedString.Key.font: font]
        let footerSize = footer.size(withAttributes: attributes)
        let footerRect = CGRect(x: (pageRect.width - footerSize.width) / 2,
                                y: pageRect.height - 36,
                                width: footerSize.width,
                                height: footerSize.height)
        footer.draw(in: footerRect, withAttributes: attributes)
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
}
