import SwiftUI
import StrainLabKit

/// Recovery detail screen showing trends and component breakdown
struct RecoveryDetailWatchView: View {
    let score: RecoveryScore?
    let history: [RecoveryScore]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingL) {
                // Header with score
                headerSection

                // 7-day trend
                if !history.isEmpty {
                    trendSection
                }

                // Component breakdown
                if let score = score {
                    componentsSection(score: score)
                }
            }
            .padding(.horizontal, WatchTheme.paddingS)
            .padding(.bottom, WatchTheme.paddingL)
        }
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: WatchTheme.paddingS) {
            WatchScoreRing.recovery(score: score, size: .large)

            Text(score?.category.displayName ?? "Loading")
                .font(WatchTheme.headlineFont)
                .foregroundStyle(score?.category.watchColor ?? WatchTheme.textSecondary)
        }
    }

    // MARK: - Trend

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: WatchTheme.paddingS) {
            Text("7-Day Trend")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            WatchTrendChart(
                data: history.map { $0.score },
                color: WatchTheme.recoveryGreen
            )
            .frame(height: 50)
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    // MARK: - Components

    private func componentsSection(score: RecoveryScore) -> some View {
        VStack(spacing: WatchTheme.paddingS) {
            WatchMetricRow(
                label: "HRV",
                value: "\(Int(score.components.currentHRV))ms",
                trend: score.components.hrvDeviation
            )

            Divider()
                .background(WatchTheme.textTertiary.opacity(0.3))

            WatchMetricRow(
                label: "RHR",
                value: "\(Int(score.components.currentRHR))bpm",
                trend: -score.components.rhrDeviation, // Inverted: lower is better
                trendColor: score.components.rhrDeviation > 0 ? WatchTheme.recoveryRed : WatchTheme.recoveryGreen
            )

            Divider()
                .background(WatchTheme.textTertiary.opacity(0.3))

            WatchMetricRow(
                label: "Sleep",
                value: "\(Int(score.components.sleepQuality))%",
                trend: nil
            )
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }
}

// MARK: - Preview

#Preview("Recovery Detail") {
    NavigationStack {
        RecoveryDetailWatchView(
            score: RecoveryScore(
                score: 78,
                category: .optimal,
                date: Date(),
                components: RecoveryScore.Components(
                    hrvDeviation: 12,
                    rhrDeviation: -2,
                    sleepQuality: 85,
                    currentHRV: 54,
                    currentRHR: 56,
                    baselineHRV: 48,
                    baselineRHR: 57
                )
            ),
            history: [
                RecoveryScore(score: 65, category: .moderate, date: Date().addingTimeInterval(-6*24*60*60), components: .init(hrvDeviation: 0, rhrDeviation: 0, sleepQuality: 70, currentHRV: 48, currentRHR: 57, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 72, category: .optimal, date: Date().addingTimeInterval(-5*24*60*60), components: .init(hrvDeviation: 5, rhrDeviation: -1, sleepQuality: 75, currentHRV: 50, currentRHR: 56, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 68, category: .optimal, date: Date().addingTimeInterval(-4*24*60*60), components: .init(hrvDeviation: 3, rhrDeviation: 2, sleepQuality: 70, currentHRV: 49, currentRHR: 58, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 75, category: .optimal, date: Date().addingTimeInterval(-3*24*60*60), components: .init(hrvDeviation: 8, rhrDeviation: -3, sleepQuality: 80, currentHRV: 52, currentRHR: 55, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 70, category: .optimal, date: Date().addingTimeInterval(-2*24*60*60), components: .init(hrvDeviation: 4, rhrDeviation: 1, sleepQuality: 72, currentHRV: 50, currentRHR: 58, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 82, category: .optimal, date: Date().addingTimeInterval(-1*24*60*60), components: .init(hrvDeviation: 15, rhrDeviation: -5, sleepQuality: 90, currentHRV: 55, currentRHR: 54, baselineHRV: 48, baselineRHR: 57)),
                RecoveryScore(score: 78, category: .optimal, date: Date(), components: .init(hrvDeviation: 12, rhrDeviation: -2, sleepQuality: 85, currentHRV: 54, currentRHR: 56, baselineHRV: 48, baselineRHR: 57))
            ]
        )
    }
    .watchBackground()
}
