import SwiftUI
import WidgetKit

struct RecoveryWidget: Widget {
    let kind: String = "RecoveryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecoveryTimelineProvider()) { entry in
            RecoveryWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Recovery")
        .description("See your daily recovery score at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct RecoveryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecoveryEntry {
        RecoveryEntry(
            date: Date(),
            recoveryScore: 75,
            category: .optimal,
            strainScore: 12.5,
            sleepHours: 7.5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecoveryEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecoveryEntry>) -> Void) {
        let entry = loadCurrentEntry()

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadCurrentEntry() -> RecoveryEntry {
        // Load from shared App Group UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.strainlab.shared")

        let recoveryScore = defaults?.double(forKey: "widget.recovery.score") ?? 0
        let categoryRaw = defaults?.string(forKey: "widget.recovery.category") ?? "moderate"
        let strainScore = defaults?.double(forKey: "widget.strain.score") ?? 0
        let sleepHours = defaults?.double(forKey: "widget.sleep.hours") ?? 0

        let category: RecoveryCategory
        switch categoryRaw {
        case "optimal": category = .optimal
        case "poor": category = .poor
        default: category = .moderate
        }

        return RecoveryEntry(
            date: Date(),
            recoveryScore: recoveryScore,
            category: category,
            strainScore: strainScore,
            sleepHours: sleepHours
        )
    }
}

// MARK: - Entry

struct RecoveryEntry: TimelineEntry {
    let date: Date
    let recoveryScore: Double
    let category: RecoveryCategory
    let strainScore: Double
    let sleepHours: Double
}

enum RecoveryCategory: String {
    case optimal, moderate, poor

    var color: Color {
        switch self {
        case .optimal: return .green
        case .moderate: return .yellow
        case .poor: return .red
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

// MARK: - Widget Views

struct RecoveryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: RecoveryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallRecoveryWidget(entry: entry)
        case .systemMedium:
            MediumRecoveryWidget(entry: entry)
        case .accessoryCircular:
            CircularRecoveryWidget(entry: entry)
        case .accessoryRectangular:
            RectangularRecoveryWidget(entry: entry)
        default:
            SmallRecoveryWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallRecoveryWidget: View {
    let entry: RecoveryEntry

    var body: some View {
        VStack(spacing: 8) {
            Text("RECOVERY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.recoveryScore / 100)
                    .stroke(
                        entry.category.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(Int(entry.recoveryScore))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 80, height: 80)

            Text(entry.category.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(entry.category.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget

struct MediumRecoveryWidget: View {
    let entry: RecoveryEntry

    var body: some View {
        HStack(spacing: 16) {
            // Recovery Ring
            VStack(spacing: 4) {
                Text("RECOVERY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: entry.recoveryScore / 100)
                        .stroke(
                            entry.category.color,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.recoveryScore))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 70, height: 70)

                Text(entry.category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(entry.category.color)
            }

            // Strain & Sleep
            VStack(alignment: .leading, spacing: 12) {
                MetricRow(
                    label: "STRAIN",
                    value: String(format: "%.1f", entry.strainScore),
                    color: .blue
                )

                MetricRow(
                    label: "SLEEP",
                    value: String(format: "%.1fh", entry.sleepHours),
                    color: .purple
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Accessory Widgets (Lock Screen)

struct CircularRecoveryWidget: View {
    let entry: RecoveryEntry

    var body: some View {
        Gauge(value: entry.recoveryScore, in: 0...100) {
            Text("R")
        } currentValueLabel: {
            Text("\(Int(entry.recoveryScore))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.category.color)
    }
}

struct RectangularRecoveryWidget: View {
    let entry: RecoveryEntry

    var body: some View {
        HStack(spacing: 8) {
            Gauge(value: entry.recoveryScore, in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(entry.category.color)

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(Int(entry.recoveryScore))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))

                Text("Recovery")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    RecoveryWidget()
} timeline: {
    RecoveryEntry(date: .now, recoveryScore: 85, category: .optimal, strainScore: 12.5, sleepHours: 7.5)
    RecoveryEntry(date: .now, recoveryScore: 55, category: .moderate, strainScore: 8.2, sleepHours: 6.0)
    RecoveryEntry(date: .now, recoveryScore: 28, category: .poor, strainScore: 16.0, sleepHours: 4.5)
}

#Preview("Medium", as: .systemMedium) {
    RecoveryWidget()
} timeline: {
    RecoveryEntry(date: .now, recoveryScore: 75, category: .optimal, strainScore: 12.5, sleepHours: 7.5)
}
