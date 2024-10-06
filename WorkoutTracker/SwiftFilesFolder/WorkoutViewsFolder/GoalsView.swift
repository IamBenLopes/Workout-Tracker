import SwiftUI
import CoreData

struct GoalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var strengthGoal = ""
    @State private var cardioGoal = ""
    @State private var flexibilityGoal = ""
    @State private var weightGoal = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Strength")) {
                    TextEditor(text: $strengthGoal)
                        .frame(height: 100)
                }
                
                Section(header: Text("Cardio")) {
                    TextEditor(text: $cardioGoal)
                        .frame(height: 100)
                }
                
                Section(header: Text("Flexibility")) {
                    TextEditor(text: $flexibilityGoal)
                        .frame(height: 100)
                }
                
                Section(header: Text("Weight")) {
                    TextEditor(text: $weightGoal)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoals()
                    }
                }
            }
        }
        .onAppear(perform: loadGoals)
    }
    
    private func saveGoals() {
        let goals = Goals(context: viewContext)
        goals.strength = strengthGoal
        goals.cardio = cardioGoal
        goals.flexibility = flexibilityGoal
        goals.weight = weightGoal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func loadGoals() {
        let request: NSFetchRequest<Goals> = Goals.fetchRequest()
        do {
            let goals = try viewContext.fetch(request)
            if let latestGoals = goals.last {
                strengthGoal = latestGoals.strength ?? ""
                cardioGoal = latestGoals.cardio ?? ""
                flexibilityGoal = latestGoals.flexibility ?? ""
                weightGoal = latestGoals.weight ?? ""
            }
        } catch {
            print("Error loading goals: \(error)")
        }
    }
}

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
