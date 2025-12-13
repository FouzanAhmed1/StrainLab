import SwiftUI
import WatchKit
import StrainLabKit

/// Main Daily Readiness screen for Apple Watch
/// Displays recovery score, insight, and quick access to strain/sleep metrics
struct DailyReadinessView: View {
    @Environment(WatchHealthKitManager.self) private var healthKit
    @Environment(WatchScoreEngine.self) private var scoreEngine
    @EnvironmentObject private var workoutManager: WorkoutSessionManager
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager

    @State private var showingRecoveryDetail = false
    @State private var showingStrainDetail = false
    @State private var showingSleepDetail = false
    @State private var hasAnimated = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WatchTheme.paddingM) {
                    // Insight banner at top
                    WatchInsightBanner(
                        insight: scoreEngine.shortInsight,
                        confidence: scoreEngine.dailyInsight?.confidence
                    )
                    .accessibilityLabel(insightAccessibilityLabel)

                    // Hero recovery ring (tap for details)
                    Button {
                        playHaptic(.click)
                        showingRecoveryDetail = true
                    } label: {
                        WatchHeroRecoveryRing(score: scoreEngine.recoveryScore)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(hasAnimated ? 1.0 : 0.8)
                    .opacity(hasAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: hasAnimated)
                    .accessibilityLabel(recoveryAccessibilityLabel)
                    .accessibilityHint("Double tap for recovery details")

                    // Strain and Sleep compact cards side by side
                    HStack(spacing: WatchTheme.paddingS) {
                        Button {
                            playHaptic(.click)
                            showingStrainDetail = true
                        } label: {
                            WatchCompactStrainCard(
                                score: scoreEngine.strainScore,
                                targetRange: scoreEngine.strainGuidance?.recommendedRange
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(strainAccessibilityLabel)
                        .accessibilityHint("Double tap for strain details")

                        Button {
                            playHaptic(.click)
                            showingSleepDetail = true
                        } label: {
                            WatchCompactSleepCard(score: scoreEngine.sleepScore)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(sleepAccessibilityLabel)
                        .accessibilityHint("Double tap for sleep details")
                    }
                    .offset(y: hasAnimated ? 0 : 20)
                    .opacity(hasAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: hasAnimated)

                    // Active workout or start workout button
                    workoutSection
                        .offset(y: hasAnimated ? 0 : 20)
                        .opacity(hasAnimated ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAnimated)
                }
                .padding(.horizontal, WatchTheme.paddingS)
                .padding(.bottom, WatchTheme.paddingM)
            }
            .navigationTitle("StrainLab")
            .sheet(isPresented: $showingRecoveryDetail) {
                RecoveryDetailWatchView(
                    score: scoreEngine.recoveryScore,
                    history: scoreEngine.recoveryHistory
                )
            }
            .sheet(isPresented: $showingStrainDetail) {
                StrainGuidanceWatchView(
                    score: scoreEngine.strainScore,
                    guidance: scoreEngine.strainGuidance
                )
            }
            .sheet(isPresented: $showingSleepDetail) {
                SleepDetailWatchView(
                    score: scoreEngine.sleepScore,
                    history: scoreEngine.sleepHistory
                )
            }
        }
        .task {
            await loadData()
        }
        .onAppear {
            // Trigger entrance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAnimated = true
            }
        }
    }

    // MARK: - Haptic Feedback

    private func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    // MARK: - Accessibility Labels

    private var insightAccessibilityLabel: String {
        if let insight = scoreEngine.shortInsight {
            return "Today's insight: \(insight)"
        }
        return "Loading daily insight"
    }

    private var recoveryAccessibilityLabel: String {
        if let score = scoreEngine.recoveryScore {
            return "Recovery \(Int(score.score)) percent, \(score.category.displayName)"
        }
        return "Recovery score loading"
    }

    private var strainAccessibilityLabel: String {
        if let score = scoreEngine.strainScore {
            let targetInfo: String
            if let guidance = scoreEngine.strainGuidance {
                targetInfo = ", target \(guidance.formattedRange)"
            } else {
                targetInfo = ""
            }
            return "Strain \(String(format: "%.1f", score.score)) out of 21\(targetInfo)"
        }
        return "Strain score loading"
    }

    private var sleepAccessibilityLabel: String {
        if let score = scoreEngine.sleepScore {
            return "Sleep \(Int(score.score)) percent, \(score.components.formattedDuration)"
        }
        return "Sleep score loading"
    }

    // MARK: - Workout Section

    @ViewBuilder
    private var workoutSection: some View {
        if workoutManager.isWorkoutActive {
            NavigationLink {
                ActiveWorkoutView()
            } label: {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(WatchTheme.recoveryGreen)
                    Text("Active Workout")
                        .font(WatchTheme.captionFont)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(WatchTheme.textTertiary)
                }
                .padding(WatchTheme.paddingM)
                .background(WatchTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                WorkoutSelectionView()
            } label: {
                Label("Start Workout", systemImage: "plus.circle.fill")
                    .font(WatchTheme.captionFont)
            }
            .buttonStyle(.borderedProminent)
            .tint(WatchTheme.recoveryGreen)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Load cached scores
        await scoreEngine.loadCachedScores()

        // Request sync from iPhone
        connectivityManager.requestSync()
    }
}

// MARK: - Preview

#Preview("Daily Readiness") {
    DailyReadinessView()
        .environment(WatchHealthKitManager())
        .environment(WatchScoreEngine.shared)
        .environmentObject(WorkoutSessionManager())
        .environmentObject(WatchConnectivityManager.shared)
}
