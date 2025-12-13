import SwiftUI
import StrainLabKit

/// Reusable score ring component for Apple Watch
/// Displays a circular progress ring with a centered score value
struct WatchScoreRing: View {
    let score: Double
    let maxScore: Double
    let color: Color
    let size: WatchTheme.RingSize
    let showLabel: Bool
    let animated: Bool

    @State private var animatedProgress: Double = 0

    init(
        score: Double,
        maxScore: Double = 100,
        color: Color,
        size: WatchTheme.RingSize = .medium,
        showLabel: Bool = true,
        animated: Bool = true
    ) {
        self.score = score
        self.maxScore = maxScore
        self.color = color
        self.size = size
        self.showLabel = showLabel
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animated ? animatedProgress : progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center label
            if showLabel {
                Text(formattedScore)
                    .font(size.font)
                    .fontWeight(.bold)
                    .foregroundStyle(WatchTheme.textPrimary)
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .onAppear {
            if animated {
                withAnimation(WatchTheme.ringAnimation) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: score) { _, newValue in
            if animated {
                withAnimation(WatchTheme.ringAnimation) {
                    animatedProgress = newValue / maxScore
                }
            }
        }
    }

    private var progress: Double {
        min(1, max(0, score / maxScore))
    }

    private var formattedScore: String {
        if maxScore == 100 {
            return "\(Int(score))"
        } else {
            return String(format: "%.1f", score)
        }
    }
}

// MARK: - Convenience Initializers

extension WatchScoreRing {
    /// Create a recovery score ring
    static func recovery(score: RecoveryScore?, size: WatchTheme.RingSize = .medium) -> some View {
        WatchScoreRing(
            score: score?.score ?? 0,
            maxScore: 100,
            color: score?.category.watchColor ?? WatchTheme.recoveryGreen,
            size: size,
            showLabel: true
        )
    }

    /// Create a strain score ring
    static func strain(score: StrainScore?, size: WatchTheme.RingSize = .medium) -> some View {
        WatchScoreRing(
            score: score?.score ?? 0,
            maxScore: 21,
            color: WatchTheme.strainBlue,
            size: size,
            showLabel: true
        )
    }

    /// Create a sleep score ring
    static func sleep(score: SleepScore?, size: WatchTheme.RingSize = .medium) -> some View {
        WatchScoreRing(
            score: score?.score ?? 0,
            maxScore: 100,
            color: WatchTheme.sleepPurple,
            size: size,
            showLabel: true
        )
    }
}

// MARK: - Hero Recovery Ring

/// Large hero recovery ring for the main screen
struct WatchHeroRecoveryRing: View {
    let score: RecoveryScore?

    var body: some View {
        VStack(spacing: WatchTheme.paddingS) {
            WatchScoreRing.recovery(score: score, size: .hero)

            Text(score?.category.displayName ?? "Loading")
                .font(WatchTheme.captionFont)
                .foregroundStyle(score?.category.watchColor ?? WatchTheme.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Recovery Ring") {
    VStack(spacing: 20) {
        WatchScoreRing(
            score: 78,
            color: WatchTheme.recoveryGreen,
            size: .hero
        )

        HStack(spacing: 16) {
            WatchScoreRing(
                score: 12.5,
                maxScore: 21,
                color: WatchTheme.strainBlue,
                size: .medium
            )

            WatchScoreRing(
                score: 85,
                color: WatchTheme.sleepPurple,
                size: .medium
            )
        }
    }
    .watchBackground()
}
