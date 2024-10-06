import SwiftUI
import CoreData

struct MovementLogEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var movementLog: MovementLog
    @State private var showSetEntry = false
    @State private var showDeleteConfirmation = false
    @State private var setToDelete: SetEntity?

    var body: some View {
        Form {
            Section(header: Text("Movement Details")) {
                Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
                Text("Date: \(formattedDate)")
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
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error saving movement log: \(error)")
            }
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
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error deleting set: \(error)")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var formattedDate: String {
        movementLog.date?.formatted(date: .long, time: .shortened) ?? "Unknown Date"
    }
}
