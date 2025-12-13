import SwiftUI
import StrainLabKit

/// Sleep detail screen showing consistency and breakdown
struct SleepDetailWatchView: View {
    let score: SleepScore?
    let history: [SleepScore]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingL) {
                // Header with score and duration
                headerSection

                // 7-day consistency trend
                if !history.isEmpty {
                    consistencySection
                }

                // Sleep breakdown
                if let score = score {
                    breakdownSection(score: score)
                }
            }
            .padding(.horizontal, WatchTheme.paddingS)
            .padding(.bottom, WatchTheme.paddingL)
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: WatchTheme.paddingS) {
            WatchScoreRing.sleep(score: score, size: .large)

            VStack(spacing: 2) {
                Text(score?.components.formattedDuration ?? "---")
                    .font(WatchTheme.headlineFont)
                    .foregroundStyle(WatchTheme.sleepPurple)

                Text(score?.category.displayName ?? "Loading")
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.textSecondary)
            }
        }
    }

    // MARK: - Consistency Trend

    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.paddingS) {
            Text("7-Day Consistency")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            WatchTrendChart(
                data: history.map { $0.score },
                color: WatchTheme.sleepPurple
            )
            .frame(height: 50)

            // Average duration
            if let avgDuration = averageDuration {
                HStack {
                    Text("Avg Duration")
                        .font(WatchTheme.microFont)
                        .foregroundStyle(WatchTheme.textTertiary)
                    Spacer()
                    Text(avgDuration)
                        .font(WatchTheme.microFont)
                        .foregroundStyle(WatchTheme.textSecondary)
                }
            }
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    private var averageDuration: String? {
        guard !history.isEmpty else { return nil }
        let avgMinutes = history.map { $0.components.totalDurationMinutes }.reduce(0, +) / Double(history.count)
        let hours = Int(avgMinutes) / 60
        let minutes = Int(avgMinutes) % 60
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Breakdown

    private func breakdownSection(score: SleepScore) -> some View {
        VStack(spacing: WatchTheme.paddingS) {
            WatchMetricRow(
                label: "Efficiency",
                value: "\(Int(score.components.efficiency * 100))%",
                trend: nil
            )

            Divider()
                .background(WatchTheme.textTertiary.opacity(0.3))

            WatchMetricRow(
                label: "Deep Sleep",
                value: formatMinutes(score.components.deepSleepMinutes),
                trend: nil
            )

            Divider()
                .background(WatchTheme.textTertiary.opacity(0.3))

            WatchMetricRow(
                label: "REM Sleep",
                value: formatMinutes(score.components.remSleepMinutes),
                trend: nil
            )
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Preview

#Preview("Sleep Detail") {
    NavigationStack {
        SleepDetailWatchView(
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
            ),
            history: [
                SleepScore(score: 70, category: .good, date: Date().addingTimeInterval(-6*24*60*60), components: .init(durationScore: 75, efficiencyScore: 70, stageScore: 65, totalDurationMinutes: 390, sleepNeedMinutes: 450, efficiency: 0.88, deepSleepMinutes: 60, remSleepMinutes: 80)),
                SleepScore(score: 82, category: .good, date: Date().addingTimeInterval(-5*24*60*60), components: .init(durationScore: 85, efficiencyScore: 82, stageScore: 79, totalDurationMinutes: 420, sleepNeedMinutes: 450, efficiency: 0.90, deepSleepMinutes: 75, remSleepMinutes: 95)),
                SleepScore(score: 75, category: .good, date: Date().addingTimeInterval(-4*24*60*60), components: .init(durationScore: 78, efficiencyScore: 75, stageScore: 72, totalDurationMinutes: 400, sleepNeedMinutes: 450, efficiency: 0.87, deepSleepMinutes: 65, remSleepMinutes: 85)),
                SleepScore(score: 88, category: .excellent, date: Date().addingTimeInterval(-3*24*60*60), components: .init(durationScore: 92, efficiencyScore: 88, stageScore: 84, totalDurationMinutes: 450, sleepNeedMinutes: 450, efficiency: 0.93, deepSleepMinutes: 85, remSleepMinutes: 105)),
                SleepScore(score: 78, category: .good, date: Date().addingTimeInterval(-2*24*60*60), components: .init(durationScore: 80, efficiencyScore: 78, stageScore: 76, totalDurationMinutes: 410, sleepNeedMinutes: 450, efficiency: 0.89, deepSleepMinutes: 70, remSleepMinutes: 90)),
                SleepScore(score: 90, category: .excellent, date: Date().addingTimeInterval(-1*24*60*60), components: .init(durationScore: 95, efficiencyScore: 90, stageScore: 85, totalDurationMinutes: 460, sleepNeedMinutes: 450, efficiency: 0.94, deepSleepMinutes: 90, remSleepMinutes: 110)),
                SleepScore(score: 85, category: .excellent, date: Date(), components: .init(durationScore: 90, efficiencyScore: 85, stageScore: 80, totalDurationMinutes: 440, sleepNeedMinutes: 450, efficiency: 0.92, deepSleepMinutes: 80, remSleepMinutes: 100))
            ]
        )
    }
    .watchBackground()
}
