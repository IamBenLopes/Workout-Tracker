import Foundation

struct MetricsData {
    // Primary Metric
    var primaryType = "Weight"
    var primaryValue = ""
    var primaryLeftValue = ""
    var primaryRightValue = ""
    var primaryUnit = "lbs"
    var usePrimarySplit = false
    
    // Secondary Metric
    var secondaryType = "Reps"
    var secondaryValue = ""
    var secondaryLeftValue = ""
    var secondaryRightValue = ""
    var secondaryUnit = "count"
    var useSecondarySplit = false
    
    // Additional Data
    var notes = ""
    var timerMinutes = 0
    var timerSeconds = 0
    
    init() {}
} 