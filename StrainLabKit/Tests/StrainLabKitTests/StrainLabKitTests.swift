import XCTest
@testable import StrainLabKit

final class StrainLabKitTests: XCTestCase {

    func testHeartRateSampleCreation() {
        let sample = HeartRateSample(
            timestamp: Date(),
            beatsPerMinute: 72,
            source: .watch
        )
        XCTAssertEqual(sample.beatsPerMinute, 72)
        XCTAssertEqual(sample.source, .watch)
    }

    func testHRVSampleCreation() {
        let sample = HRVSample(
            timestamp: Date(),
            sdnnMilliseconds: 45.5,
            rrIntervalsMs: [800, 810, 795]
        )
        XCTAssertEqual(sample.sdnnMilliseconds, 45.5)
        XCTAssertEqual(sample.rrIntervalsMs?.count, 3)
    }

    func testRecoveryCategoryFromScore() {
        XCTAssertEqual(RecoveryScore.Category.from(score: 80), .optimal)
        XCTAssertEqual(RecoveryScore.Category.from(score: 50), .moderate)
        XCTAssertEqual(RecoveryScore.Category.from(score: 20), .poor)
    }

    func testStrainCategoryFromScore() {
        XCTAssertEqual(StrainScore.Category.from(score: 19), .allOut)
        XCTAssertEqual(StrainScore.Category.from(score: 15), .high)
        XCTAssertEqual(StrainScore.Category.from(score: 11), .moderate)
        XCTAssertEqual(StrainScore.Category.from(score: 5), .light)
    }

    func testSleepSessionEfficiency() {
        let now = Date()
        let stages = [
            SleepSession.SleepStage(type: .deep, startDate: now, endDate: now.addingTimeInterval(3600)),
            SleepSession.SleepStage(type: .awake, startDate: now.addingTimeInterval(3600), endDate: now.addingTimeInterval(4200)),
            SleepSession.SleepStage(type: .rem, startDate: now.addingTimeInterval(4200), endDate: now.addingTimeInterval(7200))
        ]
        let session = SleepSession(
            startDate: now,
            endDate: now.addingTimeInterval(7200),
            stages: stages
        )

        let efficiency = session.sleepEfficiency
        XCTAssertGreaterThan(efficiency, 0.9)
        XCTAssertLessThan(efficiency, 1.0)
    }

    func testArrayMean() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        XCTAssertEqual(values.mean, 3.0)
    }

    func testArrayMedian() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        XCTAssertEqual(values.median, 3.0)
    }

    func testArrayStandardDeviation() {
        let values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let stdDev = values.standardDeviation
        XCTAssertEqual(stdDev, 2.14, accuracy: 0.1)
    }

    func testDateExtensions() {
        let date = Date()
        XCTAssertTrue(date.isToday)
        XCTAssertFalse(date.daysAgo(1).isToday)
        XCTAssertTrue(date.daysAgo(1).isYesterday)
    }
}
