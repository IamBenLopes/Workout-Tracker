import SwiftUI
import CoreData

struct ExportManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private let exportService: ExportService
    @State private var startDate = Date().addingTimeInterval(-30*24*60*60)
    @State private var endDate = Date()
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(context: NSManagedObjectContext) {
        self.exportService = ExportService(context: context)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button(action: generateExport) {
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
                        .background(Color.secondary.colorInvert())
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    }
                }
            )
        }
    }
    
    private func generateExport() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let pdfURL = exportService.generatePDF(startDate: startDate, endDate: endDate) {
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
