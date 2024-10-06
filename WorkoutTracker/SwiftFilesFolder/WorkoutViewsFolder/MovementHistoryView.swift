import SwiftUI
import CoreData

struct MovementHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Movement.movementClass, ascending: true),
            NSSortDescriptor(keyPath: \Movement.name, ascending: true)
        ],
        animation: .default)
    private var movements: FetchedResults<Movement>

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedMovementClasses, id: \.self) { movementClass in
                    Section(header: Text(movementClass)) {
                        ForEach(movementsByClass[movementClass] ?? [], id: \.objectID) { movement in
                            NavigationLink(destination: MovementDetailView(movement: movement)) {
                                Text(movement.name ?? "Unknown Movement")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Movements History")
        }
    }

    private var movementsByClass: [String: [Movement]] {
        Dictionary(grouping: movements) { $0.movementClass ?? "Unknown" }
    }

    private var sortedMovementClasses: [String] {
        movementsByClass.keys.sorted()
    }
}

struct MovementDetailView: View {
    @ObservedObject var movement: Movement
    @State private var showingEditView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(movement.name ?? "Unknown Movement")
                    .font(.title)
                
                Text("Class: \(movement.movementClass ?? "Unknown")")
                    .font(.subheadline)
                
                if let description = movement.movementDescription, !description.isEmpty {
                    Text("Description:")
                        .font(.headline)
                    Text(description)
                }
                
                if let imageData = movement.movementPhoto, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                Text("History:")
                    .font(.headline)
                
                MovementHistoryList(movement: movement)
            }
            .padding()
        }
        .navigationBarItems(trailing: Button("Edit") {
            showingEditView = true
        })
        .sheet(isPresented: $showingEditView) {
            MovementEditView(movement: movement)
        }
    }
}

struct MovementHistoryList: View {
    @ObservedObject var movement: Movement
    @State private var movementLogs: [MovementLog] = []
    
    var body: some View {
        List {
            ForEach(movementLogs, id: \.self) { log in
                NavigationLink(destination: MovementLogDetailView(movementLog: log)) {
                    Text(log.formattedDate)
                }
            }
        }
        .onAppear(perform: loadMovementLogs)
    }
    
    private func loadMovementLogs() {
        let fetchRequest: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "movement == %@", movement)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.date, ascending: false)]
        
        do {
            movementLogs = try movement.managedObjectContext?.fetch(fetchRequest) ?? []
        } catch {
            print("Error fetching movement logs: \(error)")
        }
    }
}

extension MovementLog {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date ?? Date())
    }
}
