import SwiftUI
import WidgetKit

/// Sleep score complication for Apple Watch faces
struct SleepWatchComplication: Widget {
    let kind: String = "SleepWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SleepComplicationProvider()
        ) { entry in
            SleepComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Sleep")
        .description("Your sleep score and duration")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Timeline Provider

struct SleepComplicationProvider: TimelineProvider {
    typealias Entry = SleepComplicationEntry

    func placeholder(in context: Context) -> Entry {
        SleepComplicationEntry(
            date: Date(),
            sleepScore: 82,
            category: .good,
            durationHours: 7.5,
            sleepNeedHours: 8.0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = loadFromDataStore()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentEntry = loadFromDataStore()

        // Sleep data updates once per day, refresh every hour
        let refreshDate = Date().addingTimeInterval(60 * 60)

        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(refreshDate)
        )

        completion(timeline)
    }

    private func loadFromDataStore() -> Entry {
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")

        let sleepScore = defaults?.double(forKey: "watch.score.sleep.value") ?? 0
        let categoryRaw = defaults?.string(forKey: "watch.score.sleep.category") ?? "fair"
        let durationMinutes = defaults?.double(forKey: "watch.score.sleep.duration") ?? 0
        let sleepNeedMinutes = defaults?.double(forKey: "watch.score.sleep.need") ?? 480

        let category: ComplicationSleepCategory
        switch categoryRaw {
        case "excellent": category = .excellent
        case "good": category = .good
        case "poor": category = .poor
        default: category = .fair
        }

        return SleepComplicationEntry(
            date: Date(),
            sleepScore: sleepScore,
            category: category,
            durationHours: durationMinutes / 60,
            sleepNeedHours: sleepNeedMinutes / 60
        )
    }
}

// MARK: - Entry

struct SleepComplicationEntry: TimelineEntry {
    let date: Date
    let sleepScore: Double
    let category: ComplicationSleepCategory
    let durationHours: Double
    let sleepNeedHours: Double

    var formattedDuration: String {
        let hours = Int(durationHours)
        let minutes = Int((durationHours - Double(hours)) * 60)
        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(hours)h"
    }

    var shortDuration: String {
        String(format: "%.1fh", durationHours)
    }

    var durationVsNeed: Double {
        guard sleepNeedHours > 0 else { return 0 }
        return (durationHours / sleepNeedHours) * 100
    }
}

enum ComplicationSleepCategory: String {
    case excellent, good, fair, poor

    var color: Color {
        switch self {
        case .excellent: return Color(red: 0.2, green: 0.85, blue: 0.45)
        case .good: return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .fair: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .poor: return Color(red: 0.95, green: 0.3, blue: 0.3)
        }
    }

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var icon: String {
        "moon.zzz.fill"
    }
}

// MARK: - Entry View

struct SleepComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: SleepComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            SleepCircularView(entry: entry)
        case .accessoryCorner:
            SleepCornerView(entry: entry)
        case .accessoryRectangular:
            SleepRectangularView(entry: entry)
        case .accessoryInline:
            SleepInlineView(entry: entry)
        default:
            SleepCircularView(entry: entry)
        }
    }
}

// MARK: - Circular Complication

struct SleepCircularView: View {
    let entry: SleepComplicationEntry

    var body: some View {
        Gauge(value: entry.sleepScore, in: 0...100) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 10))
        } currentValueLabel: {
            Text("\(Int(entry.sleepScore))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.category.color)
    }
}

// MARK: - Corner Complication

struct SleepCornerView: View {
    let entry: SleepComplicationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(entry.category.color)
                Text("\(Int(entry.sleepScore))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .widgetLabel {
            Gauge(value: entry.sleepScore, in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(entry.category.color)
        }
    }
}

// MARK: - Rectangular Complication

struct SleepRectangularView: View {
    let entry: SleepComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            // Left: Score with moon icon
            ZStack {
                Circle()
                    .stroke(entry.category.color.opacity(0.3), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: entry.sleepScore / 100)
                    .stroke(entry.category.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 36, height: 36)

                VStack(spacing: -2) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(entry.category.color)
                    Text("\(Int(entry.sleepScore))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }

            // Right: Duration and quality
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(entry.formattedDuration)
                        .font(.system(size: 13, weight: .medium))

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(entry.category.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(entry.category.color)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inline Complication

struct SleepInlineView: View {
    let entry: SleepComplicationEntry

    var body: some View {
        Label {
            Text("\(entry.shortDuration) • \(Int(entry.sleepScore))%")
        } icon: {
            Image(systemName: "moon.zzz.fill")
        }
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    SleepWatchComplication()
} timeline: {
    SleepComplicationEntry(date: .now, sleepScore: 85, category: .good, durationHours: 7.5, sleepNeedHours: 8.0)
    SleepComplicationEntry(date: .now, sleepScore: 92, category: .excellent, durationHours: 8.2, sleepNeedHours: 8.0)
    SleepComplicationEntry(date: .now, sleepScore: 55, category: .fair, durationHours: 5.5, sleepNeedHours: 8.0)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    SleepWatchComplication()
} timeline: {
    SleepComplicationEntry(date: .now, sleepScore: 85, category: .good, durationHours: 7.5, sleepNeedHours: 8.0)
    SleepComplicationEntry(date: .now, sleepScore: 45, category: .poor, durationHours: 4.0, sleepNeedHours: 8.0)
}

#Preview("Corner", as: .accessoryCorner) {
    SleepWatchComplication()
} timeline: {
    SleepComplicationEntry(date: .now, sleepScore: 85, category: .good, durationHours: 7.5, sleepNeedHours: 8.0)
}
