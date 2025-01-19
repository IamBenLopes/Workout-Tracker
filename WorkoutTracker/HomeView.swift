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
                VStack(spacing: 24) {
                    if let activeSplit = splitManager.getActiveWorkoutSplit() {
                        activeSplitView(activeSplit)
                    } else {
                        EmptyStateView()
                    }

                    LogWorkoutButton(action: {
                        showWorkoutFlow = true
                    })
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout Tracker")
            .background(Color(.systemGroupedBackground))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(split.splitName ?? "Unnamed Split")
                .font(.title.bold())
            
            ForEach(split.sortedSplitDays, id: \.self) { splitDay in
                SplitDayRow(splitDay: splitDay) {
                    selectedSplitDay = splitDay
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(split.remainingDaysThisWeek) more day\(split.remainingDaysThisWeek == 1 ? "" : "s") to complete this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showResetAlert = true }) {
                    Label("Reset Weekly Progress", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Active Workout Split")
                .font(.headline)
            Text("Start by creating a new workout split")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct LogWorkoutButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Log New Workout", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .cornerRadius(16)
        }
    }
}

struct SplitDayRow: View {
    let splitDay: SplitDay
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(splitDay.dayName ?? "Day \(splitDay.dayNumber)")
                .font(.headline)
            Spacer()
            if splitDay.isCompleted {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onTap) {
                    Text("Start")
                        .frame(minWidth: 80, minHeight: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
    }
}
