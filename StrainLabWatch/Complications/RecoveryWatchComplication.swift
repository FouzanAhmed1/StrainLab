import SwiftUI
import WidgetKit

/// Recovery score complication for Apple Watch faces
struct RecoveryWatchComplication: Widget {
    let kind: String = "RecoveryWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: RecoveryComplicationProvider()
        ) { entry in
            RecoveryComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Recovery")
        .description("Your daily recovery score")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Timeline Provider

struct RecoveryComplicationProvider: TimelineProvider {
    typealias Entry = RecoveryComplicationEntry

    func placeholder(in context: Context) -> Entry {
        RecoveryComplicationEntry(
            date: Date(),
            recoveryScore: 75,
            category: .optimal,
            shortInsight: "Ready to push"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = loadFromDataStore()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentEntry = loadFromDataStore()

        // Calculate next refresh based on time of day
        let refreshDate = calculateNextRefreshDate()

        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(refreshDate)
        )

        completion(timeline)
    }

    private func loadFromDataStore() -> Entry {
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")

        let recoveryScore = defaults?.double(forKey: "watch.score.recovery.value") ?? 0
        let categoryRaw = defaults?.string(forKey: "watch.score.recovery.category") ?? "moderate"
        let shortInsight = defaults?.string(forKey: "watch.insight.short")

        let category: ComplicationRecoveryCategory
        switch categoryRaw {
        case "optimal": category = .optimal
        case "poor": category = .poor
        default: category = .moderate
        }

        return RecoveryComplicationEntry(
            date: Date(),
            recoveryScore: recoveryScore,
            category: category,
            shortInsight: shortInsight
        )
    }

    private func calculateNextRefreshDate() -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // More frequent updates in the morning (6-8 AM)
        // Standard updates during the day
        // Less frequent at night
        let interval: TimeInterval
        if hour >= 6 && hour < 8 {
            interval = 5 * 60 // 5 minutes
        } else if hour >= 8 && hour < 22 {
            interval = 30 * 60 // 30 minutes
        } else {
            interval = 2 * 60 * 60 // 2 hours
        }

        return Date().addingTimeInterval(interval)
    }
}

// MARK: - Entry

struct RecoveryComplicationEntry: TimelineEntry {
    let date: Date
    let recoveryScore: Double
    let category: ComplicationRecoveryCategory
    let shortInsight: String?
}

enum ComplicationRecoveryCategory: String {
    case optimal, moderate, poor

    var color: Color {
        switch self {
        case .optimal: return Color(red: 0.2, green: 0.85, blue: 0.45)
        case .moderate: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .poor: return Color(red: 0.95, green: 0.3, blue: 0.3)
        }
    }

    var displayName: String {
        switch self {
        case .optimal: return "Optimal"
        case .moderate: return "Moderate"
        case .poor: return "Poor"
        }
    }
}

// MARK: - Entry View

struct RecoveryComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: RecoveryComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryCorner:
            CornerView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            CircularView(entry: entry)
        }
    }
}

// MARK: - Circular Complication

struct CircularView: View {
    let entry: RecoveryComplicationEntry

    var body: some View {
        Gauge(value: entry.recoveryScore, in: 0...100) {
            Text("R")
        } currentValueLabel: {
            Text("\(Int(entry.recoveryScore))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.category.color)
    }
}

// MARK: - Corner Complication

struct CornerView: View {
    let entry: RecoveryComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Text("\(Int(entry.recoveryScore))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetLabel {
            Gauge(value: entry.recoveryScore, in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(entry.category.color)
        }
    }
}

// MARK: - Rectangular Complication

struct RectangularView: View {
    let entry: RecoveryComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            // Left: Score ring
            ZStack {
                Circle()
                    .stroke(entry.category.color.opacity(0.3), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: entry.recoveryScore / 100)
                    .stroke(entry.category.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 36, height: 36)

                Text("\(Int(entry.recoveryScore))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            // Right: Text content
            VStack(alignment: .leading, spacing: 2) {
                Text("Recovery")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(entry.shortInsight ?? entry.category.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inline Complication

struct InlineView: View {
    let entry: RecoveryComplicationEntry

    var body: some View {
        Text("\(Int(entry.recoveryScore))% \(entry.category.displayName)")
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    RecoveryWatchComplication()
} timeline: {
    RecoveryComplicationEntry(date: .now, recoveryScore: 78, category: .optimal, shortInsight: "Ready to push")
    RecoveryComplicationEntry(date: .now, recoveryScore: 55, category: .moderate, shortInsight: "Take it easy")
    RecoveryComplicationEntry(date: .now, recoveryScore: 28, category: .poor, shortInsight: "Rest today")
}

#Preview("Rectangular", as: .accessoryRectangular) {
    RecoveryWatchComplication()
} timeline: {
    RecoveryComplicationEntry(date: .now, recoveryScore: 78, category: .optimal, shortInsight: "Ready to push")
}
