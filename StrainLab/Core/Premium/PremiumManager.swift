import Foundation
import SwiftUI

/// Manages premium subscription state and feature access
@MainActor
public final class PremiumManager: ObservableObject {
    @Published public private(set) var tier: UserTier = .free
    @Published public private(set) var hasTrialAvailable: Bool = true
    @Published public private(set) var trialDaysRemaining: Int = 7

    // UserDefaults keys
    private let tierKey = "strainlab.premium.tier"
    private let trialStartKey = "strainlab.premium.trialStart"

    public static let shared = PremiumManager()

    private init() {
        loadSavedState()
    }

    // MARK: - User Tier

    public enum UserTier: String, Codable {
        case free
        case premium

        public var displayName: String {
            switch self {
            case .free: return "Free"
            case .premium: return "Premium"
            }
        }
    }

    // MARK: - Feature Access

    public var canAccessLongTermTrends: Bool {
        tier == .premium
    }

    public var canAccessSleepDebt: Bool {
        tier == .premium
    }

    public var canAccessStrainGuidance: Bool {
        tier == .premium
    }

    public var canAccessDeepTransparency: Bool {
        tier == .premium
    }

    public var canAccessWeeklySummaries: Bool {
        tier == .premium
    }

    public var canAccessAdvancedInsights: Bool {
        tier == .premium
    }

    public var canExportData: Bool {
        tier == .premium
    }

    // MARK: - State Management

    private func loadSavedState() {
        if let savedTier = UserDefaults.standard.string(forKey: tierKey),
           let tier = UserTier(rawValue: savedTier) {
            self.tier = tier
        }

        // Check trial status
        if let trialStart = UserDefaults.standard.object(forKey: trialStartKey) as? Date {
            let daysSinceStart = Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0
            trialDaysRemaining = max(0, 7 - daysSinceStart)
            hasTrialAvailable = trialDaysRemaining > 0
        }
    }

    public func upgradeToPremium() {
        tier = .premium
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey)
    }

    public func downgradeToFree() {
        tier = .free
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey)
    }

    public func startTrial() {
        guard hasTrialAvailable else { return }
        UserDefaults.standard.set(Date(), forKey: trialStartKey)
        upgradeToPremium()
    }

    // MARK: - Feature Check Helper

    public func requiresPremium(for feature: PremiumFeature) -> Bool {
        switch feature {
        case .longTermTrends:
            return !canAccessLongTermTrends
        case .sleepDebt:
            return !canAccessSleepDebt
        case .strainGuidance:
            return !canAccessStrainGuidance
        case .deepTransparency:
            return !canAccessDeepTransparency
        case .weeklySummaries:
            return !canAccessWeeklySummaries
        case .advancedInsights:
            return !canAccessAdvancedInsights
        case .dataExport:
            return !canExportData
        }
    }
}

// MARK: - Premium Feature Enum

public enum PremiumFeature: String, CaseIterable {
    case longTermTrends = "Long-term Trends"
    case sleepDebt = "Sleep Debt Tracking"
    case strainGuidance = "Strain Guidance"
    case deepTransparency = "Deep Transparency"
    case weeklySummaries = "Weekly Summaries"
    case advancedInsights = "Advanced Insights"
    case dataExport = "Data Export"

    public var description: String {
        switch self {
        case .longTermTrends:
            return "View 14, 28, and 90 day trends"
        case .sleepDebt:
            return "Track accumulated sleep debt over time"
        case .strainGuidance:
            return "Get personalized daily strain recommendations"
        case .deepTransparency:
            return "Interactive calculation breakdowns"
        case .weeklySummaries:
            return "Detailed weekly progress reports"
        case .advancedInsights:
            return "AI-powered recovery insights"
        case .dataExport:
            return "Export your health data"
        }
    }

    public var iconName: String {
        switch self {
        case .longTermTrends:
            return "chart.line.uptrend.xyaxis"
        case .sleepDebt:
            return "moon.zzz"
        case .strainGuidance:
            return "figure.run"
        case .deepTransparency:
            return "magnifyingglass"
        case .weeklySummaries:
            return "calendar"
        case .advancedInsights:
            return "brain"
        case .dataExport:
            return "square.and.arrow.up"
        }
    }
}
