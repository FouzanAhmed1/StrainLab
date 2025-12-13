// StrainLabKit
// Shared domain models and protocols for StrainLab iOS and watchOS apps

@_exported import Foundation

// Models
public typealias HR = HeartRateSample
public typealias HRV = HRVSample

// Version
public enum StrainLabKit {
    public static let version = "1.0.0"
    public static let minimumDataDaysForBaseline = 7
}
