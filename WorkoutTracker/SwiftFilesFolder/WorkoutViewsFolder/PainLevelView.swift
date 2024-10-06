import SwiftUI
import CoreData

struct PainLevelView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var workout: Workout
    @State private var painLevel: Int
    @State private var isPreWorkout: Bool
    
    init(workout: Workout, isPreWorkout: Bool) {
        self.workout = workout
        self._isPreWorkout = State(initialValue: isPreWorkout)
        self._painLevel = State(initialValue: Int(isPreWorkout ? workout.prePainLevel : workout.postPainLevel))
    }

    var body: some View {
        VStack {
            Text(isPreWorkout ? "Pre-Workout Pain Level" : "Post-Workout Pain Level")
                .font(.headline)
                .padding()

            Picker("Pain Level", selection: $painLevel) {
                ForEach(1...10, id: \.self) { level in
                    Text("\(level)")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
            .clipped()
            .onChange(of: painLevel) { _, newValue in
                if isPreWorkout {
                    workout.prePainLevel = Int16(newValue)
                } else {
                    workout.postPainLevel = Int16(newValue)
                }
                saveContext()
            }
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct PainLevelView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleWorkout = Workout(context: context)
        sampleWorkout.prePainLevel = 3
        sampleWorkout.postPainLevel = 2
        return PainLevelView(workout: sampleWorkout, isPreWorkout: true)
            .environment(\.managedObjectContext, context)
    }
}
