import Foundation

public extension Array where Element == Double {
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    var standardDeviation: Double {
        guard count > 1 else { return 0 }
        let avg = mean
        let squaredDiffs = map { pow($0 - avg, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(count - 1)
        return sqrt(variance)
    }

    var median: Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let middle = count / 2
        if count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        } else {
            return sorted[middle]
        }
    }

    var quartiles: (q1: Double, q2: Double, q3: Double) {
        guard count >= 4 else { return (0, median, 0) }
        let sorted = self.sorted()
        let q1Index = count / 4
        let q3Index = (count * 3) / 4
        return (sorted[q1Index], median, sorted[q3Index])
    }

    var interquartileRange: Double {
        let q = quartiles
        return q.q3 - q.q1
    }

    func percentile(_ p: Double) -> Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let index = (p / 100.0) * Double(count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        if lower == upper {
            return sorted[lower]
        }
        let weight = index - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    func movingAverage(windowSize: Int) -> [Double] {
        guard windowSize > 0 && !isEmpty else { return self }
        return indices.map { i in
            let start = Swift.max(0, i - windowSize / 2)
            let end = Swift.min(count, i + windowSize / 2 + 1)
            let window = Array(self[start..<end])
            return window.mean
        }
    }

    func removeOutliers(threshold: Double = 1.5) -> [Double] {
        guard count >= 4 else { return self }
        let q = quartiles
        let iqr = q.q3 - q.q1
        let lowerBound = q.q1 - (threshold * iqr)
        let upperBound = q.q3 + (threshold * iqr)
        return filter { $0 >= lowerBound && $0 <= upperBound }
    }
}
