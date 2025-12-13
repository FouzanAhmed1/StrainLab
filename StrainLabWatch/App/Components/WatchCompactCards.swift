import SwiftUI
import StrainLabKit

// MARK: - Compact Strain Card

/// Compact strain display for side-by-side layout
struct WatchCompactStrainCard: View {
    let score: StrainScore?
    let targetRange: ClosedRange<Double>?

    init(score: StrainScore?, targetRange: ClosedRange<Double>? = nil) {
        self.score = score
        self.targetRange = targetRange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WatchTheme.paddingXS) {
            // Header
            Text("STRAIN")
                .font(WatchTheme.microFont)
                .foregroundStyle(WatchTheme.textTertiary)

            HStack(spacing: WatchTheme.paddingS) {
                // Score ring
                WatchScoreRing(
                    score: score?.score ?? 0,
                    maxScore: 21,
                    color: WatchTheme.strainBlue,
                    size: .small,
                    showLabel: true
                )

                VStack(alignment: .leading, spacing: 2) {
                    // Category
                    Text(score?.category.displayName ?? "---")
                        .font(WatchTheme.microFont)
                        .foregroundStyle(WatchTheme.strainBlue)

                    // Target or activity minutes
                    if let range = targetRange {
                        Text("Target: \(Int(range.lowerBound))-\(Int(range.upperBound))")
                            .font(WatchTheme.microFont)
                            .foregroundStyle(WatchTheme.textTertiary)
                    } else if let minutes = score?.components.activityMinutes {
                        Text("\(Int(minutes)) min")
                            .font(WatchTheme.microFont)
                            .foregroundStyle(WatchTheme.textTertiary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .watchCompactCard()
    }
}

// MARK: - Compact Sleep Card

/// Compact sleep display for side-by-side layout
struct WatchCompactSleepCard: View {
    let score: SleepScore?

    var body: some View {
        VStack(alignment: .leading, spacing: WatchTheme.paddingXS) {
            // Header
            Text("SLEEP")
                .font(WatchTheme.microFont)
                .foregroundStyle(WatchTheme.textTertiary)

            HStack(spacing: WatchTheme.paddingS) {
                // Score ring
                WatchScoreRing(
                    score: score?.score ?? 0,
                    maxScore: 100,
                    color: WatchTheme.sleepPurple,
                    size: .small,
                    showLabel: true
                )

                VStack(alignment: .leading, spacing: 2) {
                    // Duration
                    Text(score?.components.formattedDuration ?? "---")
                        .font(WatchTheme.microFont)
                        .foregroundStyle(WatchTheme.sleepPurple)

                    // Efficiency
                    if let efficiency = score?.components.efficiency {
                        Text("\(Int(efficiency * 100))% eff")
                            .font(WatchTheme.microFont)
                            .foregroundStyle(WatchTheme.textTertiary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .watchCompactCard()
    }
}

// MARK: - Metric Row

/// Simple metric display row for detail screens
struct WatchMetricRow: View {
    let label: String
    let value: String
    let trend: Double?
    let trendColor: Color?

    init(label: String, value: String, trend: Double? = nil, trendColor: Color? = nil) {
        self.label = label
        self.value = value
        self.trend = trend
        self.trendColor = trendColor
    }

    var body: some View {
        HStack {
            Text(label)
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.textPrimary)

                if let trend = trend {
                    trendIndicator(trend)
                }
            }
        }
    }

    @ViewBuilder
    private func trendIndicator(_ trend: Double) -> some View {
        let color = trendColor ?? (trend > 0 ? WatchTheme.recoveryGreen : trend < 0 ? WatchTheme.recoveryRed : WatchTheme.textTertiary)

        HStack(spacing: 2) {
            Image(systemName: trend > 0 ? "arrow.up" : trend < 0 ? "arrow.down" : "minus")
                .font(.system(size: 8, weight: .bold))

            Text("\(Int(abs(trend)))%")
                .font(WatchTheme.microFont)
        }
        .foregroundStyle(color)
    }
}

// MARK: - Preview

#Preview("Compact Cards") {
    ScrollView {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                WatchCompactStrainCard(
                    score: StrainScore(
                        score: 12.5,
                        category: .moderate,
                        date: Date(),
                        components: StrainScore.Components(
                            activityMinutes: 45,
                            zoneMinutes: StrainScore.ZoneMinutes(zone1: 10, zone2: 15, zone3: 10, zone4: 5, zone5: 2),
                            workoutContributions: []
                        )
                    ),
                    targetRange: 14...18
                )

                WatchCompactSleepCard(
                    score: SleepScore(
                        score: 85,
                        category: .excellent,
                        date: Date(),
                        components: SleepScore.Components(
                            durationScore: 90,
                            efficiencyScore: 85,
                            stageScore: 80,
                            totalDurationMinutes: 440,
                            sleepNeedMinutes: 450,
                            efficiency: 0.92,
                            deepSleepMinutes: 80,
                            remSleepMinutes: 100
                        )
                    )
                )
            }

            VStack(spacing: 8) {
                WatchMetricRow(label: "HRV", value: "54ms", trend: 12)
                WatchMetricRow(label: "RHR", value: "56bpm", trend: -2)
            }
            .padding()
            .background(WatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
        }
        .padding()
    }
    .watchBackground()
}
