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
    let components = RecoveryScore.Components(
        hrvDeviation: 12,
        rhrDeviation: -2,
        sleepQuality: 85,
        hrvBaseline: 48,
        rhrBaseline: 57,
        currentHRV: 54,
        currentRHR: 56
    )

    return NavigationStack {
        RecoveryDetailWatchView(
            score: RecoveryScore(
                date: Date(),
                score: 78,
                category: .optimal,
                components: components
            ),
            history: []
        )
    }
    .watchBackground()
}
