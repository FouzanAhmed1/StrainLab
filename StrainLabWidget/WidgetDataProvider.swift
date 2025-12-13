import Foundation
import WidgetKit

/// Provides data to widgets from the main app
/// Call from main app to update widget data
public struct WidgetDataProvider {

    private static let suiteName = "group.com.strainlab.shared"

    public static func updateWidgetData(
        recoveryScore: Double,
        recoveryCategory: String,
        strainScore: Double,
        sleepHours: Double
    ) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        defaults.set(recoveryScore, forKey: "widget.recovery.score")
        defaults.set(recoveryCategory, forKey: "widget.recovery.category")
        defaults.set(strainScore, forKey: "widget.strain.score")
        defaults.set(sleepHours, forKey: "widget.sleep.hours")
        defaults.set(Date(), forKey: "widget.lastUpdate")

        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "RecoveryWidget")
    }

    public static func clearWidgetData() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        defaults.removeObject(forKey: "widget.recovery.score")
        defaults.removeObject(forKey: "widget.recovery.category")
        defaults.removeObject(forKey: "widget.strain.score")
        defaults.removeObject(forKey: "widget.sleep.hours")
        defaults.removeObject(forKey: "widget.lastUpdate")

        WidgetCenter.shared.reloadTimelines(ofKind: "RecoveryWidget")
    }
}
