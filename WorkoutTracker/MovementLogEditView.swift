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
    @State private var selectedSet: SetEntity?

    init(movementLog: MovementLog) {
        self.movementLog = movementLog
        _logDate = State(initialValue: movementLog.date ?? Date())
    }

    var body: some View {
        Form {
            movementDetailsSection
            setsSection
        }
        .navigationTitle("Edit Movement Log")
        .navigationBarItems(trailing: Button("Save") {
            saveContext()
            presentationMode.wrappedValue.dismiss()
        })
        .sheet(isPresented: $showSetEntry) {
            SetEntryView(movementLog: movementLog, 
                        currentSetIndex: movementLog.setsArray.count,
                        isNewSet: true)
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
    
    private var movementDetailsSection: some View {
        Section(header: Text("Movement Details")) {
            Text("Movement: \(movementLog.movement?.name ?? "Unknown")")
            DatePicker("Date", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: logDate) { oldValue, newValue in
                    movementLog.date = newValue
                    saveContext()
                }
        }
    }
    
    private var setsSection: some View {
        Section(header: Text("Sets")) {
            ForEach(movementLog.setsArray) { set in
                NavigationLink {
                    SetEntryView(movementLog: movementLog, 
                                currentSetIndex: movementLog.setsArray.firstIndex(of: set) ?? 0,
                                isNewSet: false)
                        .id(set.objectID)
                } label: {
                    SetRowView(set: set)
                }
            }
            .onDelete(perform: deleteSet)

            Button(action: {
                showSetEntry = true
            }) {
                Label("Add Set", systemImage: "plus")
            }
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    private func deleteSet(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let setToDelete = movementLog.setsArray[index]
                viewContext.delete(setToDelete)
                
                // Update set numbers for remaining sets
                for (newIndex, set) in movementLog.setsArray.enumerated() where set.setNumber > setToDelete.setNumber {
                    set.setNumber = Int16(newIndex + 1)
                }
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting set: \(error)")
            }
        }
    }
}
