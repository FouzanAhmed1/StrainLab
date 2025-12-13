import SwiftUI
import StrainLabKit

/// Strain guidance screen showing target range and current progress
struct StrainGuidanceWatchView: View {
    let score: StrainScore?
    let guidance: StrainGuidance?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingL) {
                // Target range header
                targetHeader

                // Current progress gauge
                progressSection

                // Weekly load status
                if let guidance = guidance {
                    loadStatusSection(guidance: guidance)
                }
            }
            .padding(.horizontal, WatchTheme.paddingS)
            .padding(.bottom, WatchTheme.paddingL)
        }
        .navigationTitle("Strain")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Target Header

    private var targetHeader: some View {
        VStack(spacing: WatchTheme.paddingXS) {
            Text("Today's Target")
                .font(WatchTheme.captionFont)
                .foregroundStyle(WatchTheme.textSecondary)

            Text(guidance?.formattedRange ?? "--")
                .font(WatchTheme.displayFont)
                .foregroundStyle(WatchTheme.strainBlue)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: WatchTheme.paddingM) {
            // Current score ring
            WatchScoreRing.strain(score: score, size: .medium)

            // Progress gauge
            if let guidance = guidance {
                VStack(spacing: WatchTheme.paddingS) {
                    WatchStrainGauge(
                        current: score?.score ?? 0,
                        targetRange: guidance.recommendedRange
                    )

                    // Progress text
                    progressText(guidance: guidance)
                }
            }
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    @ViewBuilder
    private func progressText(guidance: StrainGuidance) -> some View {
        let current = score?.score ?? 0
        let remaining = guidance.remainingToTarget(currentStrain: current)
        let over = guidance.overTarget(currentStrain: current)

        if remaining > 0 {
            HStack(spacing: 4) {
                Text(String(format: "%.1f", remaining))
                    .font(WatchTheme.headlineFont)
                    .foregroundStyle(WatchTheme.strainBlue)
                Text("more to target")
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.textSecondary)
            }
        } else if over > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(WatchTheme.recoveryYellow)
                Text("Above target")
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.recoveryYellow)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(WatchTheme.recoveryGreen)
                Text("In target range")
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.recoveryGreen)
            }
        }
    }

    // MARK: - Load Status Section

    private func loadStatusSection(guidance: StrainGuidance) -> some View {
        VStack(alignment: .leading, spacing: WatchTheme.paddingS) {
            HStack {
                Text("Weekly Status")
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(WatchTheme.textSecondary)
                Spacer()
                Text(guidance.weeklyLoadStatus.displayName)
                    .font(WatchTheme.captionFont)
                    .foregroundStyle(statusColor(guidance.weeklyLoadStatus))
            }

            Text(guidance.weeklyLoadStatus.shortDescription)
                .font(WatchTheme.microFont)
                .foregroundStyle(WatchTheme.textTertiary)
        }
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    private func statusColor(_ status: WeeklyLoadStatus) -> Color {
        switch status {
        case .optimal, .building:
            return WatchTheme.recoveryGreen
        case .underLoaded, .deloading:
            return WatchTheme.recoveryYellow
        case .peaking:
            return WatchTheme.strainBlue
        case .overReaching:
            return WatchTheme.recoveryRed
        case .unknown:
            return WatchTheme.textSecondary
        }
    }
}

// MARK: - Preview

#Preview("Strain Guidance") {
    NavigationStack {
        StrainGuidanceWatchView(
            score: StrainScore(
                date: Date(),
                score: 10.5,
                category: .moderate,
                components: StrainScore.Components(
                    activityMinutes: 35,
                    zoneMinutes: StrainScore.Components.ZoneMinutes(zone1: 10, zone2: 12, zone3: 8, zone4: 3, zone5: 1),
                    workoutContributions: []
                )
            ),
            guidance: StrainGuidance(
                recommendedRange: 14...18,
                weeklyLoadStatus: .building,
                rationale: "Your recovery is strong — you're progressively building fitness"
            )
        )
    }
    .watchBackground()
}
