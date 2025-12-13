import Foundation
import StrainLabKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var recoveryScore: RecoveryScore?
    @Published var strainScore: StrainScore?
    @Published var sleepScore: SleepScore?
    @Published var weeklyTrends: [DailyTrend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var scoreEngine: ScoreEngine?

    init() {}

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let healthKit = iOSHealthKitManager()
            try await healthKit.requestAuthorization()

            let coreData = CoreDataManager.shared
            scoreEngine = ScoreEngine(coreDataManager: coreData, healthKitManager: healthKit)

            guard let engine = scoreEngine else { return }

            async let recovery = engine.calculateTodayRecovery()
            async let strain = engine.calculateTodayStrain()
            async let sleep = engine.calculateLastNightSleep()
            async let trends = engine.fetchWeeklyTrends()

            let (rec, str, slp, trendData) = try await (recovery, strain, sleep, trends)

            recoveryScore = rec
            strainScore = str
            sleepScore = slp
            weeklyTrends = buildTrends(
                recovery: trendData.recovery,
                strain: trendData.strain,
                sleep: trendData.sleep
            )
        } catch {
            errorMessage = error.localizedDescription
            loadMockData()
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func buildTrends(
        recovery: [RecoveryScore],
        strain: [StrainScore],
        sleep: [SleepScore]
    ) -> [DailyTrend] {
        var trends: [DailyTrend] = []
        let calendar = Calendar.current

        for daysAgo in (0..<7).reversed() {
            let date = Date().daysAgo(daysAgo)
            let startOfDay = calendar.startOfDay(for: date)

            let dayRecovery = recovery.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
            let dayStrain = strain.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
            let daySleep = sleep.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }

            trends.append(DailyTrend(
                date: startOfDay,
                recoveryScore: dayRecovery?.score ?? 0,
                strainScore: dayStrain?.score ?? 0,
                sleepScore: daySleep?.score ?? 0
            ))
        }

        return trends
    }

    private func loadMockData() {
        recoveryScore = RecoveryScore(
            date: Date(),
            score: 72,
            category: .optimal,
            components: RecoveryScore.Components(
                hrvDeviation: 8.5,
                rhrDeviation: -2.1,
                sleepQuality: 78,
                hrvBaseline: 48,
                rhrBaseline: 58,
                currentHRV: 52,
                currentRHR: 57
            )
        )

        strainScore = StrainScore(
            date: Date(),
            score: 11.2,
            category: .moderate,
            components: StrainScore.Components(
                activityMinutes: 45,
                zoneMinutes: StrainScore.Components.ZoneMinutes(
                    zone1: 10, zone2: 15, zone3: 12, zone4: 6, zone5: 2
                ),
                workoutContributions: []
            )
        )

        sleepScore = SleepScore(
            date: Date(),
            score: 82,
            components: SleepScore.Components(
                durationScore: 88,
                efficiencyScore: 85,
                stageScore: 72,
                totalDurationMinutes: 432,
                sleepNeedMinutes: 450,
                efficiency: 0.91,
                deepSleepMinutes: 62,
                remSleepMinutes: 85
            )
        )

        weeklyTrends = (0..<7).reversed().map { daysAgo in
            DailyTrend(
                date: Date().daysAgo(daysAgo),
                recoveryScore: Double.random(in: 55...85),
                strainScore: Double.random(in: 8...16),
                sleepScore: Double.random(in: 60...90)
            )
        }
    }
}

struct DailyTrend: Identifiable {
    let id = UUID()
    let date: Date
    let recoveryScore: Double
    let strainScore: Double
    let sleepScore: Double
}
