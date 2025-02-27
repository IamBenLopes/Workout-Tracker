import SwiftUI
import CoreData

// Custom darker blue color
extension Color {
    static let darkBlue = Color(red: 0, green: 0.3, blue: 0.7)
}

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var splitManager: WorkoutSplitManager
    @State private var showWorkoutFlow = false
    @State private var selectedSplitDay: SplitDay?
    @State private var showResetAlert = false
    @State private var showResetResultAlert = false
    @State private var resetResultMessage = ""
    
    // New state variables for UI components
    @State private var achievements: [Achievement] = []
    @State private var recentWorkouts: [Workout] = []
    @State private var weeklyData: [Bool?] = Array(repeating: nil, count: 7)
    @State private var totalWorkouts: Int = 0
    @State private var totalMovements: Int = 0
    @State private var currentStreak: Int = 0
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _splitManager = StateObject(wrappedValue: WorkoutSplitManager(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Title
                    Text("Workout Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Weekly Summary View
                    WeeklySummaryView(weekData: weeklyData)
                        .padding(.horizontal)
                    
                    // Log Workout Button
                    LogWorkoutButton(action: {
                        showWorkoutFlow = true
                    })
                    .padding(.horizontal)
                    
                    // Achievements Carousel
                    AchievementsCarousel(achievements: achievements)
                    
                    // Active Split View or Empty State
                    if let activeSplit = splitManager.getActiveWorkoutSplit() {
                        activeSplitView(activeSplit)
                    } else {
                        EmptyStateView(splitManager: splitManager)
                    }
                    
                    // Recent Logs Preview
                    RecentLogsPreview(recentWorkouts: recentWorkouts)
                        .padding(.horizontal)
                        
                    // Header Stats View
                    HeaderStatsView(
                        totalWorkouts: totalWorkouts,
                        currentStreak: currentStreak,
                        totalMovements: totalMovements
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        // Load achievements
        achievements = calculateAchievements()
        
        // Load recent workouts
        recentWorkouts = fetchRecentWorkouts()
        
        // Calculate weekly data
        weeklyData = calculateWeeklyStats()
        
        // Get total workouts
        totalWorkouts = fetchTotalWorkoutCount()
        
        // Get total movements
        totalMovements = fetchTotalMovementCount()
        
        // Get current streak
        if let streak = calculateCurrentStreak() {
            currentStreak = streak
        }
    }
    
    private func fetchTotalMovementCount() -> Int {
        let request: NSFetchRequest<Movement> = Movement.fetchRequest()
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting movements: \(error)")
            return 0
        }
    }
    
    private func fetchRecentWorkouts() -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        request.fetchLimit = 3
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching recent workouts: \(error)")
            return []
        }
    }
    
    // Calculate weekly workout stats
    private func calculateWeeklyStats() -> [Bool?] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let weekStart = calendar.date(byAdding: .day, value: -(dayOfWeek - 1), to: today)!
        
        var weekStats: [Bool?] = Array(repeating: nil, count: 7)
        
        // Get workouts for this week
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", weekStart as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: true)]
        
        do {
            let workouts = try viewContext.fetch(request)
            
            // Mark days with workouts
            for workout in workouts {
                if let date = workout.date {
                    let dayIndex = calendar.component(.weekday, from: date) - 1
                    weekStats[dayIndex] = true
                }
            }
            
            // Mark past days without workouts as false
            for i in 0..<dayOfWeek {
                if weekStats[i] == nil {
                    weekStats[i] = false
                }
            }
            
            return weekStats
        } catch {
            print("Error fetching weekly workouts: \(error)")
            return weekStats
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
    var splitManager: WorkoutSplitManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                
                Text("No Active Workout Split")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create a workout split to organize your training routine and track your progress.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Getting started steps
            VStack(alignment: .leading, spacing: 16) {
                Text("Getting Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)
                        
                        Text("1")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create a Workout Split")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Define your training days and assign exercises to each day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)
                        
                        Text("2")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log Your Workouts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Record your sets, reps, and weights for each exercise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)
                        
                        Text("3")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Track Your Progress")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("View your performance over time and celebrate achievements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Create split button
            NavigationLink(destination: CreateWorkoutSplitView(splitManager: splitManager)) {
                Label("Create Workout Split", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
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
                .background(Color.darkBlue)
                .cornerRadius(16)
        }
    }
}

struct SplitDayRow: View {
    let splitDay: SplitDay
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Day indicator
            VStack {
                Text(String(splitDay.dayNumber))
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(splitDay.dayName ?? "Workout")
                    .font(.headline)
                
                if let splitDayMovements = splitDay.splitDayMovements as? Set<SplitDayMovement>, !splitDayMovements.isEmpty {
                    let movementCount = splitDayMovements.count
                    if movementCount > 0 {
                        Text("\(movementCount) movement\(movementCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            if splitDay.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Completed")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: onTap) {
                    Text("Start")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(minWidth: 80, minHeight: 32)
                        .background(Color.darkBlue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Header Stats View
struct HeaderStatsView: View {
    let totalWorkouts: Int
    let currentStreak: Int
    let totalMovements: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                StatCard(
                    value: "\(totalWorkouts)",
                    label: "Total Workouts",
                    iconName: "figure.strengthtraining.traditional"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatCard(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    iconName: "flame.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatCard(
                    value: "\(totalMovements)",
                    label: "Movements",
                    iconName: "dumbbell.fill"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievements Carousel
struct AchievementsCarousel: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !achievements.isEmpty {
                Text("Recent Achievements")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: achievement.type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.type.color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(achievement.type.color.opacity(0.2))
                    )
                
                Text(achievement.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.type.color)
            }
            
            Text(achievement.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(achievement.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Spacer()
            
            HStack {
                Text(achievement.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if achievement.relatedMovement != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 280, height: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }
}

// MARK: - Weekly Summary View
struct WeeklySummaryView: View {
    let weekData: [Bool?]
    
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    if index < weekData.count {
                        DayIndicator(
                            day: dayNames[index],
                            status: weekData[index]
                        )
                    } else {
                        DayIndicator(
                            day: dayNames[index],
                            status: nil
                        )
                    }
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text("Missed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(width: 8, height: 8)
                    Text("Upcoming")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }
}

struct DayIndicator: View {
    let day: String
    let status: Bool?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack {
                if let status = status {
                    Circle()
                        .fill(status ? Color.green : Color.red.opacity(0.6))
                        .frame(width: 32, height: 32)
                    
                    if status {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Logs Preview
struct RecentLogsPreview: View {
    let recentWorkouts: [Workout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: LogsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            
            if recentWorkouts.isEmpty {
                Text("No recent workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(recentWorkouts.prefix(3)) { workout in
                    WorkoutLogRow(workout: workout)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
    }
}

struct WorkoutLogRow: View {
    @ObservedObject var workout: Workout
    
    var body: some View {
        HStack(spacing: 16) {
            // Date circle
            VStack {
                Text(formattedDay)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(formattedDate)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutName ?? "Workout")
                    .font(.headline)
                
                HStack {
                    Label("\(movementCount) movements", systemImage: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(setCount) sets", systemImage: "number.square.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var formattedDay: String {
        guard let date = workout.date else { return "?" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var formattedDate: String {
        guard let date = workout.date else { return "?" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var movementCount: Int {
        guard let logs = workout.movementLogs as? Set<MovementLog> else { return 0 }
        return logs.count
    }
    
    private var setCount: Int {
        guard let logs = workout.movementLogs as? Set<MovementLog> else { return 0 }
        return logs.reduce(0) { count, log in
            count + (log.sets?.count ?? 0)
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let type: AchievementType
    let relatedMovement: Movement?
    let iconName: String
    
    enum AchievementType: String {
        case personalBest = "Personal Best"
        case consistency = "Consistency"
        case milestone = "Milestone"
        case newMovement = "New Movement"
        
        var iconName: String {
            switch self {
            case .personalBest: return "trophy.fill"
            case .consistency: return "flame.fill"
            case .milestone: return "star.fill"
            case .newMovement: return "plus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .personalBest: return .yellow
            case .consistency: return .orange
            case .milestone: return .purple
            case .newMovement: return .blue
            }
        }
    }
    
    init(title: String, description: String, date: Date, type: AchievementType, relatedMovement: Movement? = nil) {
        self.title = title
        self.description = description
        self.date = date
        self.type = type
        self.relatedMovement = relatedMovement
        self.iconName = type.iconName
    }
}

// MARK: - Achievement Helper Methods
extension HomeView {
    // Fetch recent movement logs
    private func fetchRecentMovementLogs(limit: Int = 20) -> [MovementLog] {
        let request: NSFetchRequest<MovementLog> = MovementLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MovementLog.date, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching recent movement logs: \(error)")
            return []
        }
    }
    
    // Calculate achievements based on workout data
    private func calculateAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Get recent logs
        let logs = fetchRecentMovementLogs()
        
        // Find personal bests (simplified implementation)
        for log in logs.prefix(10) {
            if let movement = log.movement, let sets = log.sets as? Set<SetEntity>, !sets.isEmpty {
                // Find max weight for this log
                let maxWeight = sets.reduce(0.0) { currentMax, set in
                    if set.usePrimarySplitMetrics {
                        return max(currentMax, max(set.primaryMetricValueLeft, set.primaryMetricValueRight))
                    } else {
                        return max(currentMax, set.primaryMetricValue)
                    }
                }
                
                // Check if this is a personal best (simplified)
                if maxWeight > 0 && isPersonalBest(for: movement, weight: maxWeight) {
                    achievements.append(Achievement(
                        title: "New Personal Best!",
                        description: "\(movement.name ?? "Unknown") - \(String(format: "%.1f", maxWeight)) lbs",
                        date: log.date ?? Date(),
                        type: .personalBest,
                        relatedMovement: movement
                    ))
                }
            }
        }
        
        // Add consistency achievements (simplified)
        if let streakCount = calculateCurrentStreak(), streakCount > 0 {
            achievements.append(Achievement(
                title: "Workout Streak!",
                description: "\(streakCount) workouts in a row",
                date: Date(),
                type: .consistency
            ))
        }
        
        // Add milestone achievements (simplified)
        let totalWorkouts = fetchTotalWorkoutCount()
        if totalWorkouts > 0 && totalWorkouts % 10 == 0 {
            achievements.append(Achievement(
                title: "Workout Milestone!",
                description: "Completed \(totalWorkouts) total workouts",
                date: Date(),
                type: .milestone
            ))
        }
        
        return achievements.prefix(5).map { $0 } // Limit to 5 achievements
    }
    
    // Check if a weight is a personal best for a movement (simplified)
    private func isPersonalBest(for movement: Movement, weight: Double) -> Bool {
        // In a real implementation, you would check against historical data
        // This is a simplified version that randomly returns true ~20% of the time
        return arc4random_uniform(5) == 0
    }
    
    // Calculate current workout streak based on actual data
    private func calculateCurrentStreak() -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all workouts sorted by date
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        
        do {
            let workouts = try viewContext.fetch(request)
            
            // No workouts, no streak
            if workouts.isEmpty {
                return 0
            }
            
            var streak = 0
            var currentDate = today
            
            // Check each day, starting with today
            while true {
                // Check if there's a workout on this day
                let workoutOnThisDay = workouts.contains { workout in
                    if let workoutDate = workout.date {
                        return calendar.isDate(calendar.startOfDay(for: workoutDate), inSameDayAs: currentDate)
                    }
                    return false
                }
                
                if workoutOnThisDay {
                    streak += 1
                    // Move to previous day
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    // Streak broken
                    break
                }
            }
            
            return streak
        } catch {
            print("Error calculating streak: \(error)")
            return 0
        }
    }
    
    // Fetch total workout count
    private func fetchTotalWorkoutCount() -> Int {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting workouts: \(error)")
            return 0
        }
    }
}
