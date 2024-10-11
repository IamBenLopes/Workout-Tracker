import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var splitManager: WorkoutSplitManager
    @State private var showWorkoutFlow = false
    @State private var selectedSplitDay: SplitDay?
    @State private var showResetAlert = false
    @State private var showResetResultAlert = false
    @State private var resetResultMessage = ""
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _splitManager = StateObject(wrappedValue: WorkoutSplitManager(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Workout Tracker")
                        .font(.largeTitle)
                        .padding(.top, 40)

                    if let activeSplit = splitManager.getActiveWorkoutSplit() {
                        activeSplitView(activeSplit)
                    } else {
                        Text("No active workout split")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    }

                    Button(action: {
                        showWorkoutFlow = true
                    }) {
                        Text("Log New Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Text("Your Progress Graphs Will Appear Here")
                        .padding()
                }
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showWorkoutFlow) {
                NavigationStack {
                    WorkoutDateView(splitManager: splitManager)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(item: $selectedSplitDay) { splitDay in
                NavigationStack {
                    WorkoutDateView(splitDay: splitDay, splitManager: splitManager)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .alert("Reset Weekly Progress", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    let success = splitManager.resetWeeklyProgress()
                    resetResultMessage = success ? "Weekly progress reset successfully." : "Failed to reset weekly progress. Please try again."
                    showResetResultAlert = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to reset your weekly progress?")
            }
            .alert("Reset Result", isPresented: $showResetResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetResultMessage)
            }
        }
    }
    
    @ViewBuilder
    func activeSplitView(_ split: WorkoutSplit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(split.splitName ?? "Unnamed Split")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(split.sortedSplitDays, id: \.self) { splitDay in
                HStack {
                    Text(splitDay.dayName ?? "Day \(splitDay.dayNumber)")
                        .font(.headline)
                    Spacer()
                    if splitDay.isCompleted {
                        Text("Completed 💪")
                            .foregroundColor(.green)
                    } else {
                        Button("Start") {
                            selectedSplitDay = splitDay
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
            
            let remainingDays = split.remainingDaysThisWeek
            Text("\(remainingDays) more day\(remainingDays == 1 ? "" : "s") to complete split this week")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 5)
            
            Button("Reset Weekly Progress") {
                showResetAlert = true
            }
            .font(.footnote)
            .foregroundColor(.blue)
            .padding(.top, 5)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
