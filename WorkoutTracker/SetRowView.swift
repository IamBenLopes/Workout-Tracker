import SwiftUI

struct SetRowView: View {
    let set: SetEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text("Set \(set.setNumber)")
                .font(.headline)
            if let primaryType = set.primaryMetricType, primaryType != "None" {
                Text("\(primaryType): \(formatMetricValue(set.primaryMetricValue)) \(set.primaryMetricUnit ?? "")")
            }
            if let secondaryType = set.secondaryMetricType, secondaryType != "None" {
                Text("\(secondaryType): \(formatMetricValue(set.secondaryMetricValue)) \(set.secondaryMetricUnit ?? "")")
            }
            if let notes = set.notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatMetricValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}
