import SwiftUI
import CoreData

struct ExportManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private let exportService: ExportService
    @State private var exportType: ExportType = .byDate
    @State private var startDate = Date().addingTimeInterval(-30*24*60*60) // 30 days ago
    @State private var endDate = Date()
    @State private var selectedMonth: Date = Date()
    @State private var showingDatePicker = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(context: NSManagedObjectContext) {
        self.exportService = ExportService(context: context)
    }
    
    enum ExportType: String, CaseIterable {
        case byDate = "Export by Date"
        case movements = "Export Movements"
        case workouts = "Export Workouts"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Type")) {
                    Picker("Export Type", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if exportType == .byDate {
                    Section(header: Text("Date Range")) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                } else {
                    Section(header: Text("Select Month")) {
                        DatePicker("Month", selection: $selectedMonth, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button(action: buttonAction) {
                        Text("Generate Export")
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Manager")
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ActivityViewController(activityItems: [url])
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Export Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .overlay(
                Group {
                    if isExporting {
                        VStack {
                            ProgressView()
                            Text("Exporting...")
                        }
                        .padding()
                        .background(Color.secondary)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    }
                }
            )

        }
    }
    
    private func buttonAction() {
        generateExport()
    }
    
    private func generateExport() {
        isExporting = true
        
        let exportStartDate: Date
        let exportEndDate: Date
        
        if exportType == .byDate {
            exportStartDate = startDate
            exportEndDate = endDate
        } else {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: selectedMonth)
            exportStartDate = calendar.date(from: components)!
            exportEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: exportStartDate)!
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfURL = exportService.generatePDF(for: exportType, startDate: exportStartDate, endDate: exportEndDate) {
                DispatchQueue.main.async {
                    exportedFileURL = pdfURL
                    showShareSheet = true
                    isExporting = false
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to generate export. Please try again."
                    showAlert = true
                    isExporting = false
                }
            }
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
