import SwiftUI
import CoreData

struct WorkoutNavigationFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var splitManager: WorkoutSplitManager

    init() {
        let context = PersistenceController.shared.container.viewContext
        _splitManager = StateObject(wrappedValue: WorkoutSplitManager(context: context))
    }

    var body: some View {
        NavigationStack {
            WorkoutDateView(splitManager: splitManager)
        }
    }
}

struct WorkoutNavigationFlow_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutNavigationFlow()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
