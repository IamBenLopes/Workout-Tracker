import SwiftUI
import CoreData

struct MovementLogEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var movementLog: MovementLog
    @State private var showSetEntry = false
    @State private var showDeleteConfirmation = false
    @State private var setToDelete: SetEntity?
    @State private var logDate: Date

    init(movementLog: MovementLog) {
        self.movementLog = movementLog
        _logDate = State(initialValue: movementLog.date ?? Date())
    }

    var body: some View {
        Form {
            Section(header: Text("Movement Details")) {
                Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
                DatePicker("Date", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: logDate) { oldValue, newValue in
                        movementLog.date = newValue
                        saveContext()
                    }
            }

            Section(header: Text("Sets")) {
                ForEach(movementLog.setsArray) { set in
                    NavigationLink(destination: SetEditView(set: set)) {
                        SetRowView(set: set)
                    }
                }
                .onDelete(perform: { indices in
                    if let index = indices.first {
                        setToDelete = movementLog.setsArray[index]
                        showDeleteConfirmation = true
                    }
                })

                Button(action: {
                    showSetEntry = true
                }) {
                    Label("Add Set", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Edit Movement Log")
        .navigationBarItems(trailing: Button("Save") {
            saveContext()
            presentationMode.wrappedValue.dismiss()
        })
        .sheet(isPresented: $showSetEntry) {
            SetEntryView(movementLog: movementLog)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Set"),
                message: Text("Are you sure you want to delete this set?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let set = setToDelete {
                        viewContext.delete(set)
                        saveContext()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
