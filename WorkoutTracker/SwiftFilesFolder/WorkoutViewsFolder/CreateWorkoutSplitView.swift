import SwiftUI
import CoreData

struct CreateWorkoutSplitView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var splitManager: WorkoutSplitManager
    @State private var splitName: String = ""
    @State private var days: [(dayNumber: Int, dayName: String)] = []
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Split Name")) {
                    TextField("Enter split name", text: $splitName)
                }

                Section(header: Text("Days")) {
                    ForEach(0..<days.count, id: \.self) { index in
                        TextField("Day \(days[index].dayNumber) Name", text: $days[index].dayName)
                    }
                    Button(action: addDay) {
                        Label("Add Day", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Create Workout Split")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveSplit()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Save Result"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                })
            }
        }
    }

    private func addDay() {
        let nextDayNumber = (days.last?.dayNumber ?? 0) + 1
        days.append((dayNumber: nextDayNumber, dayName: ""))
    }

    private func saveSplit() {
        let saveResult = splitManager.addWorkoutSplit(name: splitName, days: days)
        if saveResult {
            alertMessage = "Workout split saved successfully"
        } else {
            alertMessage = "Failed to save workout split"
        }
        showAlert = true
    }
}
