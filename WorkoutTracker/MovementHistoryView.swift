import SwiftUI
import CoreData

struct MovementHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var movement: Movement
    @State private var movementLogs: [MovementLog] = []
    @State private var showingEditView = false
    
    var body: some View {
        List {
            Section(header: Text("Movement Details")) {
                Text("Name: \(movement.name ?? "Unknown")")
                Text("Class: \(movement.movementClass ?? "Unknown")")
                if let description = movement.movementDescription, !description.isEmpty {
                    Text("Description: \(description)")
                }
            }
            
            Section(header: Text("Movement Logs")) {
                ForEach(movementLogs, id: \.self) { log in
                    NavigationLink(destination: MovementLogDetailView(movementLog: log)) {
                        VStack(alignment: .leading) {
                            Text(log.formattedDate)
                            if let workout = log.workout {
                                Text("Workout: \(workout.displayName)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteMovementLogs)
            }
        }
        .navigationTitle(movement.name ?? "Movement History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            MovementEditView(movement: movement)
        }
        .onAppear {
            fetchMovementLogs()
        }
    }
    
    private func fetchMovementLogs() {
        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.predicate = NSPredicate(format: "movement == %@", movement)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.date, ascending: false)]
        
        do {
            movementLogs = try viewContext.fetch(request)
        } catch {
            print("Error fetching movement logs: \(error)")
        }
    }
    
    private func deleteMovementLogs(at offsets: IndexSet) {
        for index in offsets {
            let logToDelete = movementLogs[index]
            viewContext.delete(logToDelete)
        }
        
        do {
            try viewContext.save()
            fetchMovementLogs()
        } catch {
            print("Error deleting movement log: \(error)")
        }
    }
}
