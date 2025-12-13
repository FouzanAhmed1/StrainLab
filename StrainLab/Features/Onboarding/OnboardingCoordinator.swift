import Foundation
import SwiftUI

/// Coordinates the onboarding flow and tracks completion state
@MainActor
public final class OnboardingCoordinator: ObservableObject {

    public static let shared = OnboardingCoordinator()

    @Published public var currentStep: OnboardingStep = .welcome
    @Published public var isOnboardingComplete: Bool

    private let defaults = UserDefaults.standard
    private let completionKey = "onboarding.complete"

    private init() {
        self.isOnboardingComplete = defaults.bool(forKey: completionKey)
    }

    // MARK: - Navigation

    public func nextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            completeOnboarding()
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
    }

    public func previousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }

    public func skipToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    // MARK: - Completion

    public func completeOnboarding() {
        defaults.set(true, forKey: completionKey)
        withAnimation(.easeInOut(duration: 0.3)) {
            isOnboardingComplete = true
        }
    }

    public func resetOnboarding() {
        defaults.set(false, forKey: completionKey)
        currentStep = .welcome
        isOnboardingComplete = false
    }

    // MARK: - Progress

    public var progress: Double {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep) else {
            return 0
        }
        return Double(currentIndex + 1) / Double(OnboardingStep.allCases.count)
    }

    public var canGoBack: Bool {
        currentStep != .welcome
    }
}

// MARK: - Onboarding Steps

public enum OnboardingStep: String, CaseIterable {
    case welcome
    case whatIsStrainLab
    case whatItIsNot
    case howItWorks
    case healthKitPermission
    case notificationPermission
    case sleepGoal
    case done

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .whatIsStrainLab: return "What is StrainLab?"
        case .whatItIsNot: return "What it's NOT"
        case .howItWorks: return "How it Works"
        case .healthKitPermission: return "Health Data"
        case .notificationPermission: return "Notifications"
        case .sleepGoal: return "Sleep Goal"
        case .done: return "You're Ready"
        }
    }
}
