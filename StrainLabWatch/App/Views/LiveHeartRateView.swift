import SwiftUI
import Charts
import WatchKit

/// Real-time heart rate monitoring view for Apple Watch
struct LiveHeartRateView: View {
    @Environment(WatchHealthKitManager.self) private var healthKit
    @State private var isMonitoring = false
    @State private var showingStats = false

    var body: some View {
        ScrollView {
            VStack(spacing: WatchTheme.paddingM) {
                // Live heart rate display
                liveHeartRateCard

                // Heart rate zone indicator
                zoneIndicator

                // Mini chart
                if !healthKit.heartRateHistory.isEmpty {
                    miniHeartRateChart
                }

                // Stats row
                statsRow

                // Control button
                controlButton
            }
            .padding(.horizontal, WatchTheme.paddingS)
        }
        .navigationTitle("Heart Rate")
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    // MARK: - Live Heart Rate Card

    private var liveHeartRateCard: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(healthKit.currentHeartRate))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(zoneColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: healthKit.currentHeartRate)

                Text("BPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WatchTheme.textSecondary)
            }

            // Pulsing heart animation
            if isMonitoring && healthKit.currentHeartRate > 0 {
                HeartPulseView(bpm: healthKit.currentHeartRate, color: zoneColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WatchTheme.paddingM)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    // MARK: - Zone Indicator

    private var zoneIndicator: some View {
        VStack(spacing: 4) {
            Text(healthKit.heartRateZone.description)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(zoneColor)

            // Zone bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background zones
                    HStack(spacing: 2) {
                        ForEach(HeartRateZone.allCases, id: \.self) { zone in
                            Rectangle()
                                .fill(zone == healthKit.heartRateZone ? zoneColorFor(zone) : zoneColorFor(zone).opacity(0.3))
                        }
                    }

                    // Current position indicator
                    if healthKit.currentHeartRate > 0 {
                        let percentage = min(1, healthKit.currentHeartRate / healthKit.userMaxHeartRate)
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .offset(x: geometry.size.width * percentage - 3)
                    }
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    // MARK: - Mini Chart

    private var miniHeartRateChart: some View {
        Chart {
            ForEach(healthKit.heartRateHistory.suffix(60)) { reading in
                LineMark(
                    x: .value("Time", reading.timestamp),
                    y: .value("BPM", reading.bpm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [zoneColorFor(reading.zone), zoneColorFor(reading.zone).opacity(0.5)],
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
        .frame(height: 60)
        .padding(WatchTheme.paddingS)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    private var chartYDomain: ClosedRange<Double> {
        let readings = healthKit.heartRateHistory.suffix(60)
        guard !readings.isEmpty else { return 50...150 }

        let minBPM = readings.map(\.bpm).min() ?? 50
        let maxBPM = readings.map(\.bpm).max() ?? 150

        return (minBPM - 10)...(maxBPM + 10)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: WatchTheme.paddingS) {
            StatBox(label: "AVG", value: "\(Int(healthKit.averageHeartRate))", color: .blue)
            StatBox(label: "MAX", value: "\(Int(healthKit.maxHeartRate))", color: .red)
            StatBox(label: "MIN", value: healthKit.minHeartRate == 999 ? "--" : "\(Int(healthKit.minHeartRate))", color: .green)
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
                isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                systemImage: isMonitoring ? "stop.fill" : "heart.fill"
            )
            .font(.system(size: 12, weight: .semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(isMonitoring ? .red : WatchTheme.recoveryGreen)
    }

    // MARK: - Helpers

    private var zoneColor: Color {
        zoneColorFor(healthKit.heartRateZone)
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

    private func startMonitoring() {
        isMonitoring = true
        healthKit.startContinuousHeartRateMonitoring()
    }

    private func stopMonitoring() {
        isMonitoring = false
        healthKit.stopContinuousHeartRateMonitoring()
    }
}

// MARK: - Heart Pulse Animation

struct HeartPulseView: View {
    let bpm: Double
    let color: Color

    @State private var isPulsing = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20))
            .foregroundStyle(color)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(
                .easeInOut(duration: 60 / bpm / 2)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WatchTheme.textTertiary)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
    LiveHeartRateView()
        .environment(WatchHealthKitManager())
}
