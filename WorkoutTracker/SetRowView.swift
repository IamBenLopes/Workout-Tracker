import SwiftUI

struct SetRowView: View {
    let set: SetEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text("Set \(set.setNumber)")
                .font(.headline)
            
            if let primaryType = set.primaryMetricType, primaryType != "None" {
                if set.usePrimarySplitMetrics {
                    Text("\(primaryType) Left: \(formatMetricValue(set.primaryMetricValueLeft)) \(set.primaryMetricUnit ?? "")")
                    Text("\(primaryType) Right: \(formatMetricValue(set.primaryMetricValueRight)) \(set.primaryMetricUnit ?? "")")
                } else {
                    Text("\(primaryType): \(formatMetricValue(set.primaryMetricValue)) \(set.primaryMetricUnit ?? "")")
                }
            }
            
            if let secondaryType = set.secondaryMetricType, secondaryType != "None" {
                if set.useSecondarySplitMetrics {
                    Text("\(secondaryType) Left: \(formatMetricValue(set.secondaryMetricValueLeft)) \(set.secondaryMetricUnit ?? "")")
                    Text("\(secondaryType) Right: \(formatMetricValue(set.secondaryMetricValueRight)) \(set.secondaryMetricUnit ?? "")")
                } else {
                    Text("\(secondaryType): \(formatMetricValue(set.secondaryMetricValue)) \(set.secondaryMetricUnit ?? "")")
                }
            }
            
            if let notes = set.notes, !notes.isEmpty {
                Text("Notes: \(notes)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private func formatMetricValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}
