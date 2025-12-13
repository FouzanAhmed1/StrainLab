import SwiftUI
import Charts
import StrainLabKit

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: TimePeriod = .today

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: StrainLabTheme.paddingL) {
                    periodPicker

                    if selectedPeriod == .today {
                        todayView
                    } else {
                        weekView
                    }
                }
                .padding(.horizontal, StrainLabTheme.paddingM)
                .padding(.bottom, StrainLabTheme.paddingXL)
            }
            .strainLabBackground()
            .navigationTitle("StrainLab")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Today View (Daily Readiness Dashboard)

    private var todayView: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            // Natural language insight at top
            if let insight = viewModel.dailyInsight {
                InsightCardView(insight: insight)
            }

            // Hero Recovery Card (primary metric)
            NavigationLink {
                RecoveryDetailView(score: viewModel.recoveryScore)
            } label: {
                HeroRecoveryCard(score: viewModel.recoveryScore) {}
            }
            .buttonStyle(.plain)

            // Secondary metrics: Strain and Sleep side by side
            HStack(spacing: StrainLabTheme.paddingM) {
                NavigationLink {
                    StrainDetailView(score: viewModel.strainScore)
                } label: {
                    CompactStrainCard(score: viewModel.strainScore)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SleepDetailView(score: viewModel.sleepScore)
                } label: {
                    CompactSleepCard(score: viewModel.sleepScore)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Week View (Trends)

    private var weekView: some View {
        VStack(spacing: StrainLabTheme.paddingL) {
            // Score cards in original layout for week view
            scoreCardsSection

            sleepSection

            if !viewModel.weeklyTrends.isEmpty {
                TrendChart(data: viewModel.weeklyTrends)
            }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var scoreCardsSection: some View {
        HStack(spacing: StrainLabTheme.paddingM) {
            NavigationLink {
                RecoveryDetailView(score: viewModel.recoveryScore)
            } label: {
                RecoveryCard(score: viewModel.recoveryScore)
            }
            .buttonStyle(.plain)

            NavigationLink {
                StrainDetailView(score: viewModel.strainScore)
            } label: {
                StrainCard(score: viewModel.strainScore)
            }
            .buttonStyle(.plain)
        }
    }

    private var sleepSection: some View {
        NavigationLink {
            SleepDetailView(score: viewModel.sleepScore)
        } label: {
            SleepCard(score: viewModel.sleepScore)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Cards for Today View

struct CompactStrainCard: View {
    let score: StrainScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            HStack {
                Text("STRAIN")
                    .font(StrainLabTheme.labelFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
                Spacer()
            }

            if let score = score {
                HStack(spacing: StrainLabTheme.paddingS) {
                    StrainRing(score: score.score)
                        .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(score.category.displayName)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.strainBlue)

                        Text("\(Int(score.components.activityMinutes)) min")
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textSecondary)
                    }

                    Spacer()
                }
            } else {
                HStack {
                    ProgressView()
                        .frame(width: 60, height: 60)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

struct CompactSleepCard: View {
    let score: SleepScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            HStack {
                Text("SLEEP")
                    .font(StrainLabTheme.labelFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
                Spacer()
            }

            if let score = score {
                HStack(spacing: StrainLabTheme.paddingS) {
                    ScoreRing(
                        score: score.score,
                        color: StrainLabTheme.sleepPurple,
                        lineWidth: 6,
                        showLabel: true
                    )
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(score.components.formattedDuration)
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.sleepPurple)

                        Text("\(Int(score.components.efficiency * 100))% eff")
                            .font(StrainLabTheme.captionFont)
                            .foregroundStyle(StrainLabTheme.textSecondary)
                    }

                    Spacer()
                }
            } else {
                HStack {
                    ProgressView()
                        .frame(width: 60, height: 60)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

// MARK: - Original Cards (kept for Week view)

struct RecoveryCard: View {
    let score: RecoveryScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            Text("RECOVERY")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            if let score = score {
                ScoreRing(
                    score: score.score,
                    color: score.category.color,
                    lineWidth: 10,
                    showLabel: true
                )
                .frame(width: 110, height: 110)

                Text(score.category.displayName)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(score.category.color)
            } else {
                ProgressView()
                    .frame(width: 110, height: 110)
                Text("Loading")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

struct StrainCard: View {
    let score: StrainScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            Text("STRAIN")
                .font(StrainLabTheme.labelFont)
                .foregroundStyle(StrainLabTheme.textTertiary)

            if let score = score {
                StrainRing(score: score.score)
                    .frame(width: 110, height: 110)

                Text(score.category.displayName)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.strainBlue)
            } else {
                ProgressView()
                    .frame(width: 110, height: 110)
                Text("Loading")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .strainLabCard()
    }
}

struct SleepCard: View {
    let score: SleepScore?

    var body: some View {
        VStack(spacing: StrainLabTheme.paddingS) {
            if let score = score {
                SleepBar(
                    score: score.score,
                    duration: score.components.formattedDuration
                )
            } else {
                HStack {
                    Text("SLEEP")
                        .font(StrainLabTheme.labelFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Spacer()
                    ProgressView()
                }
            }
        }
        .strainLabCard()
    }
}

enum TimePeriod: String, CaseIterable {
    case today
    case week

    var title: String {
        switch self {
        case .today: return "Today"
        case .week: return "7 Days"
        }
    }
}

#Preview {
    DashboardView()
}
