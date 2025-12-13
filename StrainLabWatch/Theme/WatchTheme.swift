import SwiftUI
import StrainLabKit

/// Watch-optimized theme adapted from iOS StrainLabTheme
/// Scales down sizes for the smaller display while maintaining visual consistency
public enum WatchTheme {
    // MARK: - Colors (match iOS exactly)

    public static let background = Color.black
    public static let surface = Color(white: 0.1)
    public static let surfaceElevated = Color(white: 0.15)

    public static let recoveryGreen = Color(red: 0.2, green: 0.85, blue: 0.45)
    public static let recoveryYellow = Color(red: 0.95, green: 0.75, blue: 0.2)
    public static let recoveryRed = Color(red: 0.95, green: 0.3, blue: 0.3)

    public static let strainBlue = Color(red: 0.25, green: 0.55, blue: 1.0)
    public static let sleepPurple = Color(red: 0.55, green: 0.35, blue: 1.0)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.6)
    public static let textTertiary = Color(white: 0.4)

    // MARK: - Typography (scaled for Watch)

    public static let displayFont = Font.system(size: 36, weight: .bold, design: .rounded)
    public static let titleFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let headlineFont = Font.system(size: 15, weight: .semibold, design: .default)
    public static let bodyFont = Font.system(size: 14, weight: .regular, design: .default)
    public static let captionFont = Font.system(size: 12, weight: .medium, design: .default)
    public static let labelFont = Font.system(size: 10, weight: .semibold, design: .default)
    public static let microFont = Font.system(size: 9, weight: .medium, design: .default)

    // MARK: - Spacing (compact for Watch)

    public static let paddingXS: CGFloat = 2
    public static let paddingS: CGFloat = 4
    public static let paddingM: CGFloat = 8
    public static let paddingL: CGFloat = 12
    public static let paddingXL: CGFloat = 16

    // MARK: - Corner Radii

    public static let cornerRadiusS: CGFloat = 6
    public static let cornerRadiusM: CGFloat = 10
    public static let cornerRadiusL: CGFloat = 14

    // MARK: - Ring Sizes

    public enum RingSize {
        case small
        case medium
        case large
        case hero

        public var diameter: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 50
            case .large: return 70
            case .hero: return 100
            }
        }

        public var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 5
            case .large: return 7
            case .hero: return 10
            }
        }

        public var font: Font {
            switch self {
            case .small: return .system(size: 12, weight: .bold, design: .rounded)
            case .medium: return .system(size: 16, weight: .bold, design: .rounded)
            case .large: return .system(size: 22, weight: .bold, design: .rounded)
            case .hero: return .system(size: 32, weight: .bold, design: .rounded)
            }
        }
    }

    // MARK: - Animations

    public static let standardAnimation = Animation.easeInOut(duration: 0.25)
    public static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.75)
    public static let ringAnimation = Animation.spring(response: 0.6, dampingFraction: 0.7)
}

// MARK: - Recovery Category Color Extension

public extension RecoveryScore.Category {
    var watchColor: Color {
        switch self {
        case .optimal: return WatchTheme.recoveryGreen
        case .moderate: return WatchTheme.recoveryYellow
        case .poor: return WatchTheme.recoveryRed
        }
    }
}

// MARK: - Strain Category Color Extension

public extension StrainScore.Category {
    var watchColor: Color {
        return WatchTheme.strainBlue
    }
}


// MARK: - View Modifiers

public extension View {
    /// Applies Watch card styling
    func watchCard() -> some View {
        self
            .padding(WatchTheme.paddingM)
            .background(WatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusM))
    }

    /// Applies compact Watch card styling for side-by-side layouts
    func watchCompactCard() -> some View {
        self
            .padding(WatchTheme.paddingS)
            .background(WatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: WatchTheme.cornerRadiusS))
    }

    /// Applies Watch background
    func watchBackground() -> some View {
        self
            .background(WatchTheme.background)
    }
}
