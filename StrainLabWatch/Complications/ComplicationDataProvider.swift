import Foundation
import ClockKit
import UIKit

/// Provides data for watch complications
class ComplicationDataProvider: ObservableObject {

    static let shared = ComplicationDataProvider()

    @Published var currentData: ComplicationData

    private let defaults = UserDefaults.standard

    private init() {
        // Load cached data
        self.currentData = ComplicationData(
            recoveryScore: defaults.double(forKey: "complication.recovery.score"),
            recoveryCategory: ComplicationRecoveryCategory(
                rawValue: defaults.string(forKey: "complication.recovery.category") ?? "moderate"
            ) ?? .moderate,
            strainScore: defaults.double(forKey: "complication.strain.score")
        )
    }

    // MARK: - Data Access

    func getCurrentData() -> ComplicationData {
        return currentData
    }

    // MARK: - Data Updates

    func updateData(
        recoveryScore: Double,
        recoveryCategory: ComplicationRecoveryCategory,
        strainScore: Double
    ) {
        let newData = ComplicationData(
            recoveryScore: recoveryScore,
            recoveryCategory: recoveryCategory,
            strainScore: strainScore
        )

        // Save to UserDefaults
        defaults.set(recoveryScore, forKey: "complication.recovery.score")
        defaults.set(recoveryCategory.rawValue, forKey: "complication.recovery.category")
        defaults.set(strainScore, forKey: "complication.strain.score")

        // Update published data
        DispatchQueue.main.async {
            self.currentData = newData
        }

        // Reload complications
        reloadComplications()
    }

    // MARK: - Complication Reload

    func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()

        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }

    func extendComplications() {
        let server = CLKComplicationServer.sharedInstance()

        for complication in server.activeComplications ?? [] {
            server.extendTimeline(for: complication)
        }
    }
}

// MARK: - Data Types

struct ComplicationData {
    let recoveryScore: Double
    let recoveryCategory: ComplicationRecoveryCategory
    let strainScore: Double
}

enum ComplicationRecoveryCategory: String {
    case optimal
    case moderate
    case poor

    var displayName: String {
        switch self {
        case .optimal: return "Optimal"
        case .moderate: return "Moderate"
        case .poor: return "Poor"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .optimal: return .systemGreen
        case .moderate: return .systemYellow
        case .poor: return .systemRed
        }
    }
}
