import Foundation
import SwiftUI

/// Manages user settings persistence and access
@MainActor
public final class SettingsManager: ObservableObject {
    @Published public var settings: UserSettings {
        didSet {
            saveSettings()
        }
    }

    private let settingsKey = "strainlab.userSettings"

    public static let shared = SettingsManager()

    private init() {
        self.settings = Self.loadSettings()
    }

    // MARK: - Persistence

    private static func loadSettings() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: "strainlab.userSettings"),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Quick Access

    public var sleepNeedMinutes: Double {
        settings.sleepNeedMinutes
    }

    public var maxHeartRate: Int {
        settings.calculatedMaxHeartRate
    }

    public var trainingIntensity: TrainingIntensity {
        settings.trainingIntensity
    }

    public var notificationsEnabled: Bool {
        settings.notificationsEnabled
    }

    // MARK: - Update Methods

    public func updateSleepNeed(hours: Double) {
        settings.sleepNeedHours = hours
    }

    public func updateAge(_ age: Int) {
        settings.age = age
    }

    public func updateMaxHeartRate(_ maxHR: Int?) {
        settings.maxHeartRate = maxHR
    }

    public func updateTrainingIntensity(_ intensity: TrainingIntensity) {
        settings.trainingIntensity = intensity
    }

    public func updateNotificationTime(hour: Int, minute: Int) {
        settings.morningNotificationHour = hour
        settings.morningNotificationMinute = minute
    }

    public func toggleNotifications(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
    }

    // MARK: - Reset

    public func resetToDefaults() {
        settings = UserSettings()
    }
}
