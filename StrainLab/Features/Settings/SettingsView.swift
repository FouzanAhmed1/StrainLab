import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                sleepSection
                trainingSection
                notificationSection
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.hidden)
            .background(StrainLabTheme.background)
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        Section {
            HStack {
                Label("Sleep Goal", systemImage: "moon.fill")
                    .foregroundStyle(StrainLabTheme.sleepPurple)

                Spacer()

                Stepper(
                    "\(String(format: "%.1f", settingsManager.settings.sleepNeedHours))h",
                    value: $settingsManager.settings.sleepNeedHours,
                    in: 5...10,
                    step: 0.5
                )
                .frame(width: 140)
            }
        } header: {
            Text("Sleep")
        } footer: {
            Text("Your personalized sleep need. Most adults need 7-9 hours.")
        }
    }

    // MARK: - Training Section

    private var trainingSection: some View {
        Section {
            // Age
            HStack {
                Label("Age", systemImage: "person.fill")

                Spacer()

                if let age = settingsManager.settings.age {
                    Stepper(
                        "\(age) years",
                        value: Binding(
                            get: { age },
                            set: { settingsManager.updateAge($0) }
                        ),
                        in: 16...100
                    )
                    .frame(width: 140)
                } else {
                    Button("Set Age") {
                        settingsManager.updateAge(30)
                    }
                    .foregroundStyle(StrainLabTheme.strainBlue)
                }
            }

            // Training Intensity
            Picker(selection: $settingsManager.settings.trainingIntensity) {
                ForEach(TrainingIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.rawValue).tag(intensity)
                }
            } label: {
                Label("Training Level", systemImage: "flame.fill")
                    .foregroundStyle(StrainLabTheme.strainBlue)
            }

            // Max Heart Rate
            HStack {
                Label("Max Heart Rate", systemImage: "heart.fill")
                    .foregroundStyle(StrainLabTheme.recoveryRed)

                Spacer()

                Text("\(settingsManager.maxHeartRate) bpm")
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }
        } header: {
            Text("Training")
        } footer: {
            Text("Max heart rate is calculated from your age. Training level adjusts strain recommendations.")
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            Toggle(isOn: $settingsManager.settings.notificationsEnabled) {
                Label("Morning Recovery", systemImage: "bell.fill")
            }
            .tint(StrainLabTheme.recoveryGreen)

            if settingsManager.settings.notificationsEnabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                from: settingsManager.settings.morningNotificationTime
                            ) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            settingsManager.updateNotificationTime(
                                hour: components.hour ?? 7,
                                minute: components.minute ?? 0
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            Toggle(isOn: $settingsManager.settings.weeklyNotificationEnabled) {
                Label("Weekly Summary", systemImage: "calendar")
            }
            .tint(StrainLabTheme.recoveryGreen)
            .premiumBadge(for: .weeklySummaries)
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            HStack {
                Label("Subscription", systemImage: "star.fill")
                    .foregroundStyle(.purple)

                Spacer()

                Text(premiumManager.tier.displayName)
                    .foregroundStyle(StrainLabTheme.textSecondary)

                if premiumManager.tier == .free {
                    PremiumBadge()
                }
            }

            if premiumManager.tier == .free {
                Button {
                    // Show paywall
                } label: {
                    HStack {
                        Text("Upgrade to Premium")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(StrainLabTheme.strainBlue)
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(StrainLabTheme.textSecondary)
            }

            Button {
                // Open privacy policy
            } label: {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(StrainLabTheme.textPrimary)

            Button {
                settingsManager.resetToDefaults()
            } label: {
                Text("Reset to Defaults")
                    .foregroundStyle(StrainLabTheme.recoveryRed)
            }
        } header: {
            Text("About")
        } footer: {
            Text("All data is stored locally on your device. We never share your health information.")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
