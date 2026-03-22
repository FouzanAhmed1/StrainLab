import SwiftUI
import Charts
import WatchKit
import StrainLabKit

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutManager: WorkoutSessionManager
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @State private var showingEndConfirmation = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Main metrics view
            mainMetricsView
                .tag(0)

            // Heart rate detail view
            heartRateDetailView
                .tag(1)

            // Strain & Zones view
            strainZonesView
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "End Workout?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Main Metrics View

    private var mainMetricsView: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingM) {
                // Duration
                VStack(spacing: 4) {
                    Text(workoutManager.formattedElapsedTime)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("Duration")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchTheme.textTertiary)
                }

                // Live Heart Rate with zone color
                liveHeartRateDisplay

                // Live Strain Score
                liveStrainDisplay

                // Quick Stats Row
                HStack(spacing: WatchTheme.paddingS) {
                    QuickStatBox(
                        icon: "flame.fill",
                        value: "\(Int(workoutManager.activeCalories))",
                        label: "CAL",
                        color: .orange
                    )

                    if workoutManager.distance > 0 {
                        QuickStatBox(
                            icon: "arrow.forward",
                            value: String(format: "%.2f", workoutManager.distance / 1000),
                            label: "KM",
                            color: .blue
                        )
                    }
                }

                // Control Buttons
                controlButtons
            }
            .padding(.horizontal, WatchTheme.paddingS)
            .padding(.bottom, WatchTheme.paddingM)
        }
    }

    // MARK: - Live Heart Rate Display

    private var liveHeartRateDisplay: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                // Pulsing heart
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(zoneColor)
                    .symbolEffect(.pulse, options: .repeating)

                Text("\(Int(workoutManager.currentHeartRate))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(zoneColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: workoutManager.currentHeartRate)

                Text("BPM")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WatchTheme.textSecondary)
            }

            // Zone indicator
            Text(workoutManager.currentZone.description)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(zoneColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(zoneColor.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    // MARK: - Live Strain Display

    private var liveStrainDisplay: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(WatchTheme.strainBlue)

                Text(workoutManager.formattedStrain)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.strainBlue)
                    .contentTransition(.numericText())

                Text("/ 21")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WatchTheme.textTertiary)
            }

            // Strain progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(WatchTheme.strainBlue.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(WatchTheme.strainBlue)
                        .frame(width: geometry.size.width * min(1, workoutManager.liveStrain / 21))
                }
            }
            .frame(height: 6)

            Text("Live Strain")
                .font(.system(size: 10))
                .foregroundStyle(WatchTheme.textTertiary)
        }
        .padding(WatchTheme.paddingS)
        .frame(maxWidth: .infinity)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    // MARK: - Heart Rate Detail View

    private var heartRateDetailView: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingM) {
                // Mini live chart
                if !workoutManager.heartRateHistory.isEmpty {
                    liveHeartRateChart
                }

                // Heart rate stats
                HStack(spacing: WatchTheme.paddingS) {
                    StatCard(label: "AVG", value: workoutManager.formattedAverageHR, color: .blue)
                    StatCard(label: "MAX", value: workoutManager.formattedMaxHR, color: .red)
                    StatCard(label: "MIN", value: workoutManager.minHeartRate == 999 ? "--" : "\(Int(workoutManager.minHeartRate))", color: .green)
                }

                // Current zone detail
                VStack(spacing: 4) {
                    Text("Current Zone")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchTheme.textTertiary)

                    Text(workoutManager.currentZone.description)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(zoneColor)

                    Text("\(workoutManager.currentZone.percentageRange.lowerBound)-\(workoutManager.currentZone.percentageRange.upperBound)% Max HR")
                        .font(.system(size: 9))
                        .foregroundStyle(WatchTheme.textSecondary)
                }
                .padding(WatchTheme.paddingS)
                .frame(maxWidth: .infinity)
                .background(WatchTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
            }
            .padding(.horizontal, WatchTheme.paddingS)
        }
    }

    private var liveHeartRateChart: some View {
        Chart {
            ForEach(workoutManager.heartRateHistory.suffix(60)) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("BPM", point.bpm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [zoneColorFor(point.zone), zoneColorFor(point.zone).opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisValueLabel {
                    if let bpm = value.as(Double.self) {
                        Text("\(Int(bpm))")
                            .font(.system(size: 8))
                    }
                }
            }
        }
        .chartYScale(domain: chartYDomain)
        .frame(height: 80)
        .padding(WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    private var chartYDomain: ClosedRange<Double> {
        let readings = workoutManager.heartRateHistory.suffix(60)
        guard !readings.isEmpty else { return 60...180 }

        let minBPM = readings.map(\.bpm).min() ?? 60
        let maxBPM = readings.map(\.bpm).max() ?? 180

        return (minBPM - 10)...(maxBPM + 10)
    }

    // MARK: - Strain & Zones View

    private var strainZonesView: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingM) {
                // Large strain display
                VStack(spacing: 8) {
                    Text(workoutManager.formattedStrain)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(WatchTheme.strainBlue)

                    Text("Workout Strain")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchTheme.textSecondary)
                }

                // Zone distribution
                zoneDistributionChart

                // Zone legend
                zoneLegend
            }
            .padding(.horizontal, WatchTheme.paddingS)
        }
    }

    private var zoneDistributionChart: some View {
        VStack(spacing: 4) {
            Text("Time in Zones")
                .font(.system(size: 10))
                .foregroundStyle(WatchTheme.textTertiary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(HeartRateZone.allCases.filter { $0 != .rest }, id: \.self) { zone in
                        let percentage = workoutManager.zonePercentages[zone] ?? 0
                        let width = max(2, geometry.size.width * (percentage / 100))

                        Rectangle()
                            .fill(zoneColorFor(zone))
                            .frame(width: width)
                    }
                }
            }
            .frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    private var zoneLegend: some View {
        VStack(spacing: 4) {
            ForEach(HeartRateZone.allCases.filter { $0 != .rest }, id: \.self) { zone in
                let percentage = workoutManager.zonePercentages[zone] ?? 0
                let time = workoutManager.zoneTimeDistribution[zone] ?? 0

                HStack {
                    Circle()
                        .fill(zoneColorFor(zone))
                        .frame(width: 8, height: 8)

                    Text(zone.description)
                        .font(.system(size: 10))
                        .foregroundStyle(WatchTheme.textSecondary)

                    Spacer()

                    Text(formatZoneTime(time))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(WatchTheme.textPrimary)

                    Text("(\(Int(percentage))%)")
                        .font(.system(size: 9))
                        .foregroundStyle(WatchTheme.textTertiary)
                }
            }
        }
        .padding(WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: WatchTheme.paddingM) {
            // Pause/Resume button
            Button {
                WKInterfaceDevice.current().play(.click)
                if workoutManager.isPaused {
                    workoutManager.resumeWorkout()
                } else {
                    workoutManager.pauseWorkout()
                }
            } label: {
                Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .tint(.yellow)

            // End button
            Button {
                WKInterfaceDevice.current().play(.click)
                showingEndConfirmation = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Helpers

    private var zoneColor: Color {
        zoneColorFor(workoutManager.currentZone)
    }

    private func zoneColorFor(_ zone: HeartRateZone) -> Color {
        switch zone {
        case .rest: return .gray
        case .zone1: return .blue
        case .zone2: return .green
        case .zone3: return .yellow
        case .zone4: return .orange
        case .zone5: return .red
        }
    }

    private func formatZoneTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func endWorkout() {
        Task {
            do {
                WKInterfaceDevice.current().play(.success)
                let session = try await workoutManager.endWorkout()
                connectivityManager.sendWorkoutSession(session)
                dismiss()
            } catch {
                print("Failed to end workout: \(error)")
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(WatchTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(WatchTheme.textTertiary)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveWorkoutView()
            .environmentObject(WorkoutSessionManager())
            .environmentObject(WatchConnectivityManager.shared)
    }
}
