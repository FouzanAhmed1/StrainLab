import Foundation

public protocol HealthDataProvider: Sendable {
    func requestAuthorization() async throws
    func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HeartRateSample]
    func fetchHRVSamples(from startDate: Date, to endDate: Date) async throws -> [HRVSample]
    func fetchSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession]
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutSession]
    func fetchRestingHeartRate(for date: Date) async throws -> Double?
}
