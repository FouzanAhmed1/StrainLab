import SwiftUI
import Charts
import WatchKit

/// Real-time recovery monitoring view using HRV
struct LiveRecoveryView: View {
    @Environment(WatchHealthKitManager.self) private var healthKit
    @Environment(WatchScoreEngine.self) private var scoreEngine
    @State private var isMonitoring = false
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var breathingProgress: Double = 0
    @State private var breathingTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingM) {
                // Live HRV display
                liveHRVCard

                // Recovery status
                recoveryStatusCard

                // Stress level
                stressLevelCard

                // Guided breathing section
                if isMonitoring {
                    guidedBreathingCard
                }

                // Control button
                controlButton
            }
            .padding(.horizontal, WatchTheme.paddingS)
        }
        .navigationTitle("Recovery")
        .onDisappear {
            stopMonitoring()
        }
    }

    // MARK: - Live HRV Card

    private var liveHRVCard: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 16))
                    .foregroundStyle(WatchTheme.recoveryGreen)

                Text("\(Int(healthKit.currentHRV))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.recoveryGreen)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: healthKit.currentHRV)

                Text("ms")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WatchTheme.textSecondary)
            }

            // HRV trend indicator
            HStack(spacing: 4) {
                Image(systemName: healthKit.hrvTrend.icon)
                    .font(.system(size: 12))
                Text(healthKit.hrvTrend.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(trendColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(trendColor.opacity(0.2))
            .clipShape(Capsule())

            Text("Heart Rate Variability")
                .font(.system(size: 10))
                .foregroundStyle(WatchTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    // MARK: - Recovery Status Card

    private var recoveryStatusCard: some View {
        let status = healthKit.getCurrentRecoveryStatus()

        return VStack(spacing: 4) {
            Text("Recovery Status")
                .font(.system(size: 10))
                .foregroundStyle(WatchTheme.textTertiary)

            Text(status.rawValue)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(recoveryStatusColor(status))

            // Recovery bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(recoveryStatusColor(status))
                        .frame(width: geometry.size.width * recoveryPercentage(status))
                }
            }
            .frame(height: 6)
        }
        .padding(WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    // MARK: - Stress Level Card

    private var stressLevelCard: some View {
        let stress = healthKit.detectStressLevel()

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stress Level")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchTheme.textTertiary)

                Text(stress.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(stressColor(stress))
            }

            Spacer()

            // Stress indicator circles
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < stressLevel(stress) ? stressColor(stress) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    // MARK: - Guided Breathing Card

    private var guidedBreathingCard: some View {
        VStack(spacing: 8) {
            Text("Breathe")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WatchTheme.textSecondary)

            ZStack {
                Circle()
                    .stroke(WatchTheme.recoveryGreen.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(WatchTheme.recoveryGreen.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(breathingPhase == .inhale ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 4), value: breathingPhase)

                Text(breathingPhase.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchTheme.recoveryGreen)
            }
        }
        .padding(WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
        .onAppear {
            startBreathingAnimation()
        }
    }

    // MARK: - Control Button

    private var controlButton: some View {
        Button {
            WKInterfaceDevice.current().play(.click)
            if isMonitoring {
                stopMonitoring()
            } else {
                startMonitoring()
            }
        } label: {
            Label(
                isMonitoring ? "Stop Session" : "Start Recovery Session",
                systemImage: isMonitoring ? "stop.fill" : "leaf.fill"
            )
            .font(.system(size: 12, weight: .semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(isMonitoring ? .red : WatchTheme.recoveryGreen)
    }

    // MARK: - Helpers

    private var trendColor: Color {
        switch healthKit.hrvTrend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }

    private func recoveryStatusColor(_ status: RecoveryStatus) -> Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }

    private func recoveryPercentage(_ status: RecoveryStatus) -> Double {
        switch status {
        case .excellent: return 1.0
        case .good: return 0.75
        case .moderate: return 0.5
        case .poor: return 0.25
        case .unknown: return 0.0
        }
    }

    private func stressColor(_ stress: StressLevel) -> Color {
        switch stress {
        case .minimal: return .green
        case .low: return .blue
        case .moderate: return .yellow
        case .high: return .red
        case .unknown: return .gray
        }
    }

    private func stressLevel(_ stress: StressLevel) -> Int {
        switch stress {
        case .minimal: return 1
        case .low: return 2
        case .moderate: return 3
        case .high: return 4
        case .unknown: return 0
        }
    }

    private func startMonitoring() {
        isMonitoring = true
        healthKit.startContinuousHRVMonitoring()
        healthKit.startContinuousHeartRateMonitoring()
    }

    private func stopMonitoring() {
        isMonitoring = false
        breathingTimer?.invalidate()
        breathingTimer = nil
        healthKit.stopContinuousHRVMonitoring()
        healthKit.stopContinuousHeartRateMonitoring()
    }

    private func startBreathingAnimation() {
        breathingTimer?.invalidate()
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    breathingPhase = breathingPhase == .inhale ? .exhale : .inhale
                }
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Inhale"
    case exhale = "Exhale"
}

// MARK: - Preview

#Preview {
    LiveRecoveryView()
        .environment(WatchHealthKitManager())
        .environment(WatchScoreEngine.shared)
}
