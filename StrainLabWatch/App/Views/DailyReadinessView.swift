import SwiftUI
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: WatchTheme.paddingM) {
                    // Insight banner at top
                    WatchInsightBanner(
                        insight: scoreEngine.shortInsight,
                        confidence: scoreEngine.dailyInsight?.confidence
                    )

                    // Hero recovery ring (tap for details)
                    Button {
                        showingRecoveryDetail = true
                    } label: {
                        WatchHeroRecoveryRing(score: scoreEngine.recoveryScore)
                    }
                    .buttonStyle(.plain)

                    // Strain and Sleep compact cards side by side
                    HStack(spacing: WatchTheme.paddingS) {
                        Button {
                            showingStrainDetail = true
                        } label: {
                            WatchCompactStrainCard(
                                score: scoreEngine.strainScore,
                                targetRange: scoreEngine.strainGuidance?.recommendedRange
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingSleepDetail = true
                        } label: {
                            WatchCompactSleepCard(score: scoreEngine.sleepScore)
                        }
                        .buttonStyle(.plain)
                    }

                    // Active workout or start workout button
                    workoutSection
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
