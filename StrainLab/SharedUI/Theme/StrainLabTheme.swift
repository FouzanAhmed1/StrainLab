import SwiftUI
import StrainLabKit

public enum StrainLabTheme {
    public static let background = Color.black
    public static let surface = Color(white: 0.08)
    public static let surfaceElevated = Color(white: 0.12)
    public static let surfaceHighlight = Color(white: 0.16)

    public static let recoveryGreen = Color(red: 0.2, green: 0.85, blue: 0.45)
    public static let recoveryYellow = Color(red: 0.95, green: 0.75, blue: 0.2)
    public static let recoveryRed = Color(red: 0.95, green: 0.3, blue: 0.3)

    public static let strainBlue = Color(red: 0.25, green: 0.55, blue: 1.0)
    public static let sleepPurple = Color(red: 0.55, green: 0.35, blue: 1.0)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.6)
    public static let textTertiary = Color(white: 0.4)

    public static let displayFont = Font.system(size: 56, weight: .bold, design: .rounded)
    public static let displaySmallFont = Font.system(size: 44, weight: .bold, design: .rounded)
    public static let titleFont = Font.system(size: 28, weight: .semibold, design: .rounded)
    public static let headlineFont = Font.system(size: 18, weight: .semibold, design: .default)
    public static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    public static let captionFont = Font.system(size: 12, weight: .medium, design: .default)
    public static let labelFont = Font.system(size: 10, weight: .semibold, design: .default)

    public static let paddingXS: CGFloat = 4
    public static let paddingS: CGFloat = 8
    public static let paddingM: CGFloat = 16
    public static let paddingL: CGFloat = 24
    public static let paddingXL: CGFloat = 32

    public static let cornerRadiusS: CGFloat = 8
    public static let cornerRadiusM: CGFloat = 12
    public static let cornerRadiusL: CGFloat = 16
    public static let cornerRadiusXL: CGFloat = 24

    public static let standardAnimation = Animation.easeInOut(duration: 0.3)
    public static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.75)
    public static let ringAnimation = Animation.spring(response: 0.8, dampingFraction: 0.7)
}

public extension RecoveryScore.Category {
    var color: Color {
        switch self {
        case .optimal: return StrainLabTheme.recoveryGreen
        case .moderate: return StrainLabTheme.recoveryYellow
        case .poor: return StrainLabTheme.recoveryRed
        }
    }
}

public extension StrainScore.Category {
    var color: Color {
        return StrainLabTheme.strainBlue
    }
}

public extension View {
    func strainLabCard() -> some View {
        self
            .padding(StrainLabTheme.paddingM)
            .background(StrainLabTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: StrainLabTheme.cornerRadiusL))
    }

    func strainLabBackground() -> some View {
        self
            .background(StrainLabTheme.background)
            .preferredColorScheme(.dark)
    }
}
