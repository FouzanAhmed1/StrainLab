import SwiftUI
import WidgetKit

/// Strain guidance complication for Apple Watch faces
struct StrainWatchComplication: Widget {
    let kind: String = "StrainWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: StrainComplicationProvider()
        ) { entry in
            StrainComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Strain Target")
        .description("Your recommended strain range")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Timeline Provider

struct StrainComplicationProvider: TimelineProvider {
    typealias Entry = StrainComplicationEntry

    func placeholder(in context: Context) -> Entry {
        StrainComplicationEntry(
            date: Date(),
            currentStrain: 10.5,
            targetRange: 14...18
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = loadFromDataStore()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentEntry = loadFromDataStore()

        // Refresh every 15 minutes during the day
        let refreshDate = Date().addingTimeInterval(15 * 60)

        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(refreshDate)
        )

        completion(timeline)
    }

    private func loadFromDataStore() -> Entry {
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")

        let currentStrain = defaults?.double(forKey: "watch.score.strain.value") ?? 0
        let targetLower = defaults?.double(forKey: "watch.guidance.target.lower") ?? 10
        let targetUpper = defaults?.double(forKey: "watch.guidance.target.upper") ?? 14

        return StrainComplicationEntry(
            date: Date(),
            currentStrain: currentStrain,
            targetRange: targetLower...targetUpper
        )
    }
}

// MARK: - Entry

struct StrainComplicationEntry: TimelineEntry {
    let date: Date
    let currentStrain: Double
    let targetRange: ClosedRange<Double>

    var remainingToTarget: Double {
        max(0, targetRange.lowerBound - currentStrain)
    }

    var isInRange: Bool {
        currentStrain >= targetRange.lowerBound && currentStrain <= targetRange.upperBound
    }

    var isAboveTarget: Bool {
        currentStrain > targetRange.upperBound
    }

    var formattedTarget: String {
        "\(Int(targetRange.lowerBound))-\(Int(targetRange.upperBound))"
    }
}

// MARK: - Entry View

struct StrainComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: StrainComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            StrainCircularView(entry: entry)
        case .accessoryRectangular:
            StrainRectangularView(entry: entry)
        case .accessoryInline:
            StrainInlineView(entry: entry)
        default:
            StrainCircularView(entry: entry)
        }
    }
}

// MARK: - Circular Complication

struct StrainCircularView: View {
    let entry: StrainComplicationEntry

    private let maxStrain: Double = 21

    var body: some View {
        Gauge(value: entry.currentStrain, in: 0...maxStrain) {
            Text("S")
        } currentValueLabel: {
            Text(String(format: "%.1f", entry.currentStrain))
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(statusColor)
    }

    private var statusColor: Color {
        if entry.isInRange {
            return Color(red: 0.2, green: 0.85, blue: 0.45) // Green
        } else if entry.isAboveTarget {
            return Color(red: 0.95, green: 0.75, blue: 0.2) // Yellow
        } else {
            return Color(red: 0.25, green: 0.55, blue: 1.0) // Blue
        }
    }
}

// MARK: - Rectangular Complication

struct StrainRectangularView: View {
    let entry: StrainComplicationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Strain")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Target: \(entry.formattedTarget)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                // Current strain
                Text(String(format: "%.1f", entry.currentStrain))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 1.0))

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))

                        // Target zone
                        let startOffset = entry.targetRange.lowerBound / 21 * geometry.size.width
                        let rangeWidth = (entry.targetRange.upperBound - entry.targetRange.lowerBound) / 21 * geometry.size.width

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: rangeWidth)
                            .offset(x: startOffset)

                        // Current progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(statusColor)
                            .frame(width: min(geometry.size.width, entry.currentStrain / 21 * geometry.size.width))
                    }
                }
                .frame(height: 8)
            }

            // Status text
            Text(statusText)
                .font(.system(size: 10))
                .foregroundStyle(statusColor)
        }
    }

    private var statusColor: Color {
        if entry.isInRange {
            return Color(red: 0.2, green: 0.85, blue: 0.45)
        } else if entry.isAboveTarget {
            return Color(red: 0.95, green: 0.75, blue: 0.2)
        } else {
            return Color(red: 0.25, green: 0.55, blue: 1.0)
        }
    }

    private var statusText: String {
        if entry.isInRange {
            return "In target range"
        } else if entry.isAboveTarget {
            return "Above target"
        } else {
            return String(format: "%.1f to go", entry.remainingToTarget)
        }
    }
}

// MARK: - Inline Complication

struct StrainInlineView: View {
    let entry: StrainComplicationEntry

    var body: some View {
        if entry.isInRange {
            Text("Strain: On target")
        } else if entry.isAboveTarget {
            Text("Strain: Above target")
        } else {
            Text("Strain: \(String(format: "%.1f", entry.remainingToTarget)) to go")
        }
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    StrainWatchComplication()
} timeline: {
    StrainComplicationEntry(date: .now, currentStrain: 10.5, targetRange: 14...18)
    StrainComplicationEntry(date: .now, currentStrain: 15.2, targetRange: 14...18)
    StrainComplicationEntry(date: .now, currentStrain: 19.0, targetRange: 14...18)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    StrainWatchComplication()
} timeline: {
    StrainComplicationEntry(date: .now, currentStrain: 10.5, targetRange: 14...18)
    StrainComplicationEntry(date: .now, currentStrain: 15.2, targetRange: 14...18)
}
