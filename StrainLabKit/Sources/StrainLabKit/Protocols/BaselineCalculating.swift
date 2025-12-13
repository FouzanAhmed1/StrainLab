import Foundation

public protocol BaselineCalculating: Sendable {
    func calculateRollingAverage(values: [Double], days: Int) -> Double
    func detectOutliers(values: [Double], threshold: Double) -> [Double]
    func smoothValues(values: [Double], windowSize: Int) -> [Double]
}

public extension BaselineCalculating {
    func detectOutliers(values: [Double]) -> [Double] {
        detectOutliers(values: values, threshold: 1.5)
    }

    func smoothValues(values: [Double]) -> [Double] {
        smoothValues(values: values, windowSize: 3)
    }
}
