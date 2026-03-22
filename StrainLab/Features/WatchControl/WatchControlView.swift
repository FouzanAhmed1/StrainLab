import SwiftUI
import Charts
import StrainLabKit

/// View to monitor and control Apple Watch workouts from iPhone
struct WatchControlView: View {
    @StateObject private var viewModel = WatchControlViewModel()
    @State private var showingWorkoutPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: StrainLabTheme.paddingL) {
                // Connection status
                connectionStatusCard

                // Live heart rate display
                if viewModel.isReceivingLiveData {
                    liveHeartRateCard
                }

                // Active workout card (if workout running)
                if viewModel.isWorkoutActive {
                    activeWorkoutCard
                } else {
                    startWorkoutCard
                }

                // Heart rate history chart
                if !viewModel.heartRateHistory.isEmpty {
                    heartRateChartCard
                }

                // Recent workout summary
                if let lastWorkout = viewModel.lastWorkoutSummary {
                    lastWorkoutCard(lastWorkout)
                }
            }
            .padding()
        }
        .navigationTitle("Watch Control")
        .background(StrainLabTheme.background)
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutTypePicker { activityType in
                viewModel.startWorkoutOnWatch(activityType: activityType)
                showingWorkoutPicker = false
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Connection Status

    private var connectionStatusCard: some View {
        HStack {
            Circle()
                .fill(viewModel.isWatchReachable ? StrainLabTheme.recoveryGreen : .red)
                .frame(width: 10, height: 10)

            Text(viewModel.isWatchReachable ? "Watch Connected" : "Watch Not Reachable")
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)

            Spacer()

            if viewModel.isWatchReachable {
                Image(systemName: "applewatch")
                    .foregroundStyle(StrainLabTheme.strainBlue)
            }
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Live Heart Rate

    private var liveHeartRateCard: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Live Heart Rate")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                Text("From Watch")
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(viewModel.liveHeartRate))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(zoneColor(viewModel.currentZone))
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(StrainLabTheme.bodyFont)
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            // Zone indicator
            Text(viewModel.currentZone)
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(zoneColor(viewModel.currentZone))
                .clipShape(Capsule())
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Active Workout Card

    private var activeWorkoutCard: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(StrainLabTheme.recoveryGreen)

                Text("Active Workout")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                // Live indicator
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(.red.opacity(0.5), lineWidth: 2)
                            .scaleEffect(1.5)
                    )
            }

            // Duration
            Text(viewModel.formattedDuration)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(StrainLabTheme.textPrimary)

            // Stats row
            HStack(spacing: StrainLabTheme.paddingL) {
                WorkoutStatView(
                    icon: "bolt.fill",
                    value: String(format: "%.1f", viewModel.liveStrain),
                    label: "Strain",
                    color: StrainLabTheme.strainBlue
                )

                WorkoutStatView(
                    icon: "flame.fill",
                    value: "\(Int(viewModel.liveCalories))",
                    label: "Calories",
                    color: .orange
                )

                WorkoutStatView(
                    icon: "heart.fill",
                    value: "\(Int(viewModel.liveHeartRate))",
                    label: "BPM",
                    color: .red
                )
            }

            // Control buttons
            HStack(spacing: StrainLabTheme.paddingM) {
                Button {
                    if viewModel.isWorkoutPaused {
                        viewModel.resumeWorkoutOnWatch()
                    } else {
                        viewModel.pauseWorkoutOnWatch()
                    }
                } label: {
                    Image(systemName: viewModel.isWorkoutPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 60, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.yellow)

                Button {
                    viewModel.stopWorkoutOnWatch()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 60, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Start Workout Card

    private var startWorkoutCard: some View {
        VStack(spacing: StrainLabTheme.paddingM) {
            Image(systemName: "applewatch")
                .font(.system(size: 40))
                .foregroundStyle(StrainLabTheme.strainBlue)

            Text("Start Workout on Watch")
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Text("Control your Apple Watch workout from your iPhone")
                .font(StrainLabTheme.captionFont)
                .foregroundStyle(StrainLabTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingWorkoutPicker = true
            } label: {
                Label("Start Workout", systemImage: "play.fill")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(StrainLabTheme.recoveryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
            }
            .disabled(!viewModel.isWatchReachable)
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Heart Rate Chart

    private var heartRateChartCard: some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            Text("Heart Rate History")
                .font(StrainLabTheme.headlineFont)
                .foregroundStyle(StrainLabTheme.textPrimary)

            Chart {
                ForEach(viewModel.heartRateHistory) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("BPM", reading.bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing)
            }
            .frame(height: 150)
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Last Workout Card

    private func lastWorkoutCard(_ workout: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: StrainLabTheme.paddingS) {
            HStack {
                Text("Last Workout")
                    .font(StrainLabTheme.headlineFont)
                    .foregroundStyle(StrainLabTheme.textPrimary)

                Spacer()

                Text(workout.date, style: .relative)
                    .font(StrainLabTheme.captionFont)
                    .foregroundStyle(StrainLabTheme.textTertiary)
            }

            HStack(spacing: StrainLabTheme.paddingL) {
                VStack(alignment: .leading) {
                    Text("Strain")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Text(String(format: "%.1f", workout.strain))
                        .font(.title2.bold())
                        .foregroundStyle(StrainLabTheme.strainBlue)
                }

                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Text(formatDuration(workout.duration))
                        .font(.title2.bold())
                        .foregroundStyle(StrainLabTheme.textPrimary)
                }

                VStack(alignment: .leading) {
                    Text("Avg HR")
                        .font(StrainLabTheme.captionFont)
                        .foregroundStyle(StrainLabTheme.textTertiary)
                    Text("\(Int(workout.avgHeartRate))")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(StrainLabTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusM))
    }

    // MARK: - Helpers

    private func zoneColor(_ zone: String) -> Color {
        switch zone {
        case "Zone 1": return .blue
        case "Zone 2": return .green
        case "Zone 3": return .yellow
        case "Zone 4": return .orange
        case "Zone 5": return .red
        default: return .gray
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct WorkoutStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(StrainLabTheme.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(StrainLabTheme.textTertiary)
        }
    }
}

struct WorkoutTypePicker: View {
    let onSelect: (String) -> Void

    private let workoutTypes = [
        ("Running", "figure.run"),
        ("Walking", "figure.walk"),
        ("Cycling", "figure.outdoor.cycle"),
        ("HIIT", "flame.fill"),
        ("Strength", "dumbbell.fill"),
        ("Yoga", "figure.yoga"),
        ("Swimming", "figure.pool.swim"),
        ("Other", "figure.mixed.cardio")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(workoutTypes, id: \.0) { type in
                    Button {
                        onSelect(type.0)
                    } label: {
                        Label(type.0, systemImage: type.1)
                    }
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - View Model

@MainActor
class WatchControlViewModel: ObservableObject {
    @Published var isWatchReachable = false
    @Published var isReceivingLiveData = false
    @Published var isWorkoutActive = false
    @Published var isWorkoutPaused = false

    @Published var liveHeartRate: Double = 0
    @Published var liveStrain: Double = 0
    @Published var liveCalories: Double = 0
    @Published var liveDuration: TimeInterval = 0
    @Published var currentZone: String = "Rest"

    @Published var heartRateHistory: [HeartRatePoint] = []
    @Published var lastWorkoutSummary: WorkoutSummary?

    private let connectivityManager = iOSConnectivityManager.shared

    var formattedDuration: String {
        let minutes = Int(liveDuration) / 60
        let seconds = Int(liveDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startListening() {
        // Set up callbacks for live data
        connectivityManager.onLiveHeartRateReceived = { [weak self] heartRate, zone in
            Task { @MainActor in
                self?.liveHeartRate = heartRate
                self?.currentZone = zone
                self?.isReceivingLiveData = true

                // Add to history
                self?.heartRateHistory.append(HeartRatePoint(timestamp: Date(), bpm: heartRate))
                if (self?.heartRateHistory.count ?? 0) > 300 {
                    self?.heartRateHistory.removeFirst()
                }
            }
        }

        connectivityManager.onLiveWorkoutStatsReceived = { [weak self] stats in
            Task { @MainActor in
                self?.liveHeartRate = stats.heartRate
                self?.liveStrain = stats.strain
                self?.liveCalories = stats.calories
                self?.liveDuration = stats.duration
                self?.currentZone = stats.zone
                self?.isWorkoutActive = true
            }
        }

        connectivityManager.onWorkoutStarted = { [weak self] in
            Task { @MainActor in
                self?.isWorkoutActive = true
                self?.isWorkoutPaused = false
            }
        }

        connectivityManager.onWorkoutEnded = { [weak self] summary in
            Task { @MainActor in
                self?.isWorkoutActive = false
                self?.lastWorkoutSummary = summary
            }
        }

        // Check reachability
        isWatchReachable = connectivityManager.isReachable
    }

    func stopListening() {
        connectivityManager.onLiveHeartRateReceived = nil
        connectivityManager.onLiveWorkoutStatsReceived = nil
    }

    func startWorkoutOnWatch(activityType: String) {
        connectivityManager.sendWorkoutCommand(.start(activityType: activityType))
    }

    func pauseWorkoutOnWatch() {
        connectivityManager.sendWorkoutCommand(.pause)
        isWorkoutPaused = true
    }

    func resumeWorkoutOnWatch() {
        connectivityManager.sendWorkoutCommand(.resume)
        isWorkoutPaused = false
    }

    func stopWorkoutOnWatch() {
        connectivityManager.sendWorkoutCommand(.stop)
    }
}

// MARK: - Models

struct HeartRatePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let bpm: Double
}

public struct WorkoutSummary {
    let date: Date
    let strain: Double
    let duration: TimeInterval
    let calories: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
}

public struct LiveWorkoutStats {
    let heartRate: Double
    let strain: Double
    let calories: Double
    let duration: TimeInterval
    let zone: String
}

public enum WorkoutCommand {
    case start(activityType: String)
    case pause
    case resume
    case stop
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchControlView()
    }
}
