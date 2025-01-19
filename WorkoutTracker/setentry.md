1. Overview
SetEntryView is a SwiftUI view designed to:

Log sets for a particular movement within a workout.
Allow the user to input metrics (primary, secondary, split, time-based, etc.).
Store these metrics in Core Data (SetEntity) related to a particular MovementLog.
Provide navigation between sets, viewing/editing movement info, and a timer for time-based metrics.
2. Data & State Management
2.1 Environment and Observed Objects
swift
Copy
@Environment(\.managedObjectContext) private var viewContext
Provides Core Data’s managed object context for saving/fetching SetEntity objects.
swift
Copy
@Environment(\.presentationMode) var presentationMode
Allows dismissing the current view when the user finishes or saves.
swift
Copy
@ObservedObject var movementLog: MovementLog
Observed object holding the relationship to the current MovementLog. Contains references to Movement and Workout data.
2.2 Local State Variables
All of these @State variables track user-input state or dynamic runtime values.

Current Set Control

swift
Copy
@State private var currentSetNumber: Int16 = 1
@State private var currentSets: [SetEntity] = []
@State private var previousWorkoutSets: [SetEntity] = []
@State private var currentSetIndex: Int = 0
@State private var highestSetNumber: Int16 = 1
@State private var currentSet: SetEntity?
Manages which set the user is currently editing, all sets for the current MovementLog, and any sets from the previous workout.
Metric Input Fields

swift
Copy
@State private var primaryMetricValue = ""
@State private var secondaryMetricValue = ""
@State private var notes = ""
@State private var selectedPrimaryMetricType = "Weight"
@State private var selectedSecondaryMetricType = "Reps"
@State private var selectedPrimaryMetricUnit = "lbs"
@State private var selectedSecondaryMetricUnit = "count"
@State private var usePrimaryMetric = true
@State private var useSecondaryMetric = true
@State private var primaryMetricValueLeft = ""
@State private var primaryMetricValueRight = ""
@State private var secondaryMetricValueLeft = ""
@State private var secondaryMetricValueRight = ""
@State private var usePrimarySplitMetrics = false
@State private var useSecondarySplitMetrics = false
These govern which metric types/units are chosen, whether to use split metrics, and any text the user enters for those metrics or for notes.
Movement Info

swift
Copy
@State private var movementDescription: String = ""
@State private var movementImage: UIImage?
@State private var showImagePicker = false
@State private var isEditingDescription = false
Stores the movement’s description and photo (pulled from Movement via movementLog), plus whether the user is editing the description or showing the image picker.
Timer Logic

swift
Copy
@State private var timerValue: TimeInterval = 0
@State private var isTimerRunning = false
@State private var timer: Timer?
@State private var selectedMinutes: Int = 0
@State private var selectedSeconds: Int = 0
@State private var countdownSeconds: Int = 0
@State private var audioPlayer: AVAudioPlayer?
Stores the countdown for time-based metrics, the timer’s running state, and an AVAudioPlayer for playing a sound when the timer ends.
Focus Management

swift
Copy
@FocusState private var focusedField: Field?
Tracks which text field (or TextEditor) currently has focus. Uses the Field enum for identifying which field is active.
2.3 Constants & Enums
swift
Copy
let metricTypes = ["Weight", "Time", "Distance", "Reps", "Steps", "None"]
let units = ["lbs", "kg", "minutes", "seconds", "miles", "km", "count", "steps"]
Predefined arrays to populate pickers for metric type and units.
swift
Copy
enum Field: Hashable {
    case primaryMetricValue
    case primaryMetricValueLeft
    case primaryMetricValueRight
    case secondaryMetricValue
    case secondaryMetricValueLeft
    case secondaryMetricValueRight
    case notes
}
Enumerates each possible text field (or text editor) for focus management.
swift
Copy
let isNewSet: Bool
Determines if the user is creating a brand-new set versus editing an existing one.
3. Initialization Logic
swift
Copy
init(movementLog: MovementLog, currentSetIndex: Int = 0, isNewSet: Bool = false)
Print statements for debugging:
Logs the requested set index and whether it’s a new set.
Set property values based on parameters.
Fetch existing sets from Core Data for the given movementLog.
Sort them by setNumber.
If isNewSet:
Initialize currentSetNumber to (sets.count + 1).
Also sets _highestSetNumber to the same.
Else if editing existing:
Load the set at the current index (currentSetIndex) into state.
Load stored metric values, types, units, notes, and split metrics flags from the fetched SetEntity.
4. View Layout (Body)
swift
Copy
var body: some View {
    ScrollView {
        VStack(spacing: 20) {
            ...
        }
        .padding()
    }
    .navigationTitle("Log Sets")
    .onAppear {
        fetchCurrentSets()
        fetchPreviousWorkoutSets()
        loadMovementInfo()
        focusedField = .primaryMetricValue
    }
}
Major Sections Within body
Top-Level ScrollView

Ensures all controls can scroll if the screen is small.
VStack(spacing: 20):

Movement Name (Text(movementLog.movement?.name ?? "Movement"))
Navigation Controls (next/previous set, set number display).
Metric Input Section (toggles, pickers, text fields, timer).
Save Buttons (Save Set, Finish Movement).
Previous Workout Section (if data is available).
Movement Info Section (description, photo).
.onAppear:

Calls helper methods:
fetchCurrentSets()
fetchPreviousWorkoutSets()
loadMovementInfo()
Initially focuses the primary metric value field.
5. Sub-Views / Computed Properties
5.1 navigationControls
swift
Copy
var navigationControls: some View { ... }
A HStack containing:
A left arrow button (previousSet()).
A text label showing the current set number.
A right arrow button (nextSet()).
Disables buttons if the user is at the first set or cannot move forward.
5.2 metricInputSection
swift
Copy
var metricInputSection: some View { ... }
A VStack with spacing for toggles and metric input groups:
Toggle for Primary Metric (usePrimaryMetric).
Toggle for Split Primary Metric (usePrimarySplitMetrics).
If usePrimarySplitMetrics == true, shows two input groups for left/right.
Otherwise, shows a single input group.
Toggle for Secondary Metric (useSecondaryMetric).
Toggle for Split Secondary Metric (useSecondarySplitMetrics).
Same logic as primary, but for secondary metrics.
Timer View if the primary metric type is "Time".
Notes TextEditor with a focus binding (.focused).
5.2.1 metricInputGroup(...)
A helper sub-view that draws:

A label, e.g. "Primary Metric (Left)"
A Picker for metric type.
If the metric type is "Time":
Shows minutes/seconds pickers as wheels.
Else:
A TextField for numeric input and a Picker for the metric unit (unless "None").
5.3 previousWorkoutSection
swift
Copy
var previousWorkoutSection: some View { ... }
Displays the previous workout’s sets if any exist.
Iterates previousWorkoutSets and shows each set’s metrics/notes.
5.4 movementInfoSection
swift
Copy
var movementInfoSection: some View { ... }
Shows Movement Description (either plain text or TextEditor if editing).
Button to toggle editing mode or save the description.
Shows Movement Photo if available or a placeholder text otherwise.
A button to change the photo, triggering the image picker (showImagePicker).
5.5 timerView
swift
Copy
var timerView: some View { ... }
Displays the countdown in MM:SS format.
Buttons to start/stop and reset the timer.
Background view style for clarity.
6. Core Functionality & Methods
6.1 Set Management
saveSet()

Logs debug info.
Determines if we’re creating a new SetEntity or updating an existing one.
Calls updateSet(_:) to fill the entity with the current state.
Saves to viewContext.
After save:
Refreshes currentSets from Core Data.
Clears out the text fields for a new input cycle.
If not a new set, moves to the next set index if possible or increments the set counter.
Sets focus to the correct primary metric field (split vs. non-split).
updateSet(_ set: SetEntity)

Assigns all relevant fields to the SetEntity, including:
setNumber
primaryMetricType, primaryMetricUnit, primaryMetricValue (or split)
secondaryMetricType, secondaryMetricUnit, secondaryMetricValue (or split)
notes, movementLog
Booleans for usePrimarySplitMetrics and useSecondarySplitMetrics
Special logic for time-based metrics (if selectedPrimaryMetricType == "Time"):
Converts selectedMinutes/selectedSeconds into the appropriate numeric value (seconds or minutes).
Debug print statements show the data being assigned.
nextSet() and previousSet()

Navigates between existing set entries in currentSets, adjusting currentSetIndex.
If the user goes beyond the last set, preps the UI to create a new one (currentSetNumber = currentSets.count + 1).
Calls loadSet(at:) to refresh the UI with the loaded set’s data.
loadSet(at:)

Loads a given SetEntity from currentSets by index into all associated states:
currentSetNumber, metric type/unit, notes, flags for split metrics, etc.
Resets or populates the text fields accordingly.
resetFields()

Clears text fields while preserving the user’s choices for split vs. non-split metrics.
Resets focus to the first metric field.
fetchCurrentSets()

Fetches all sets belonging to the current movementLog (sorted by setNumber).
Stores them in currentSets and updates currentSetIndex, currentSetNumber, and highestSetNumber.
fetchPreviousWorkoutSets()

Fetches the most recent MovementLog that occurred before the current workout’s date.
Loads all sets for that previous log into previousWorkoutSets.
hasChanges()

Checks if the user’s current fields differ from the saved SetEntity values (for the set at currentSetIndex).
Enables/disables the Save Set button accordingly.
6.2 Movement Info
loadMovementInfo()
Loads the movement’s description and photo from movementLog.movement.
saveMovementDescription()
Persists the updated movementDescription back into the Movement entity.
saveMovementImage()
Converts the chosen UIImage to Data and saves it into Movement.movementPhoto.
6.3 Timer Logic
startTimer() / stopTimer() / resetTimer()

Handles the Swift Timer object to decrement countdownSeconds.
When the countdown hits 0, stops the timer and plays a sound.
resetTimer() reverts countdownSeconds to the original timerValue.
playTimerEndSound()

Attempts to play an MP3 resource named timer_end.mp3.
If unavailable, falls back to a system sound.
onPrimaryMetricTypeChange()

Called when the user picks "Time" in the primary metric type.
Adjusts selectedPrimaryMetricUnit to "minutes".
Converts existing numeric value to minutes/seconds if the field already had a number.
updateTimerFromPickers()

Re-calculates timerValue from the user’s minute/second picks.
Updates primaryMetricValue with the correct representation (seconds if < 60, otherwise minutes).
6.4 Focus Management
moveToNextField(from:)
Moves keyboard focus from the current field to the next logical field in the form:
From primary → secondary → notes, etc.
Accounts for split vs. non-split toggles.
7. User Interaction Flow
Select a set with the navigation arrows (previousSet, nextSet).
Toggle primary/secondary metrics on/off.
If on, choose metric type (Weight, Time, Distance, Reps, Steps, None).
If "Time" is chosen, use minute/second pickers.
Otherwise, enter numeric values in text fields.
Optionally split those metrics (Left/Right).
Add notes in the TextEditor.
Save either the current set or Finish Movement to dismiss.
(Optional) Check previous workout sets in the “Previous Workout” section for reference.
Movement Info can be updated (description, photo).
Timer can be started, stopped, or reset if the user is timing a set.
8. Key Points & Best Practices
Core Data Integration:
Each set is linked to a MovementLog (which links to a Movement), stored via SetEntity.
Split vs. Combined Metrics:
The code accommodates both a single metric value or separate left/right values.
Time Conversion:
If primary metric is “Time,” the code automatically adjusts to minutes/seconds.
Navigation:
The user can iterate through sets or create new ones easily.
Focus Management:
Each text field is assigned a case in an enum to handle @FocusState.
Timer:
A simple countdown mechanism is included, playing a sound at the end.
Movement Editing:
The user can edit the movement’s description or change its photo.
9. Summary
SetEntryView is a comprehensive SwiftUI view for logging sets of a workout movement. It provides:

Stateful input fields for metrics (split or combined).
Core Data saving logic via SetEntity.
Navigation between sets.
Dynamic time-based metric entry and a countdown timer.
Previous workout data reference for continuity.
Movement details editing (description/photo).