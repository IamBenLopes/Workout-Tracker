import SwiftUI
import CoreData

struct MoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var splitManager: WorkoutSplitManager
    @State private var showingCreateSplit = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingExportManager = false

    init() {
        let context = PersistenceController.shared.container.viewContext
        _splitManager = StateObject(wrappedValue: WorkoutSplitManager(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Workout Plans")) {
                    ForEach(splitManager.workoutSplits, id: \.splitId) { split in
                        HStack {
                            NavigationLink(destination: WorkoutSplitDetailView(workoutSplit: split, splitManager: splitManager)) {
                                WorkoutSplitRow(workoutSplit: split)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { split.isActive },
                                set: { newValue in
                                    if newValue {
                                        _ = splitManager.activateWorkoutSplit(split)
                                    } else {
                                        _ = splitManager.deactivateWorkoutSplit(split)
                                    }
                                }
                            ))
                            .toggleStyle(CustomToggleStyle())
                        }
                    }
                    .onDelete(perform: deleteSplits)
                    
                    Button(action: { showingCreateSplit = true }) {
                        Label("Add Split", systemImage: "plus")
                    }
                }
                
                Section(header: Text("Goals")) {
                    NavigationLink(destination: GoalsView()) {
                        Label("View Goals", systemImage: "flag")
                    }
                }
                
                Section(header: Text("Pain Level")) {
                    NavigationLink(destination: BackPainView()) {
                        Label("Pain Level Tracking", systemImage: "waveform.path.ecg")
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: { showingExportManager = true }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showingCreateSplit) {
                CreateWorkoutSplitView(splitManager: splitManager)
            }
            .sheet(isPresented: $showingExportManager) {
                ExportManagerView(context: viewContext)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Action Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func deleteSplits(at offsets: IndexSet) {
        for index in offsets {
            let splitToDelete = splitManager.workoutSplits[index]
            if splitManager.deleteWorkoutSplit(splitToDelete) {
                // Deletion successful
            } else {
                alertMessage = "Failed to delete workout split"
                showAlert = true
                return
            }
        }
    }
}

struct WorkoutSplitRow: View {
    let workoutSplit: WorkoutSplit

    var body: some View {
        VStack(alignment: .leading) {
            Text(workoutSplit.splitName ?? "Unnamed Split")
                .font(.headline)
            Text("Created: \(workoutSplit.createdDate?.formatted() ?? "Unknown")")
                .font(.subheadline)
            Text("Days: \((workoutSplit.splitDays?.count ?? 0))")
                .font(.subheadline)
        }
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(configuration.isOn ? Color.green : Color.gray)
                .frame(width: 50, height: 29)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 1)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                .onTapGesture {
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
