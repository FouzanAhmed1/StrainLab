import Foundation
import StrainLabKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var recoveryScore: RecoveryScore?
    @Published var strainScore: StrainScore?
    @Published var sleepScore: SleepScore?
    @Published var previousDayStrain: StrainScore?
    @Published var dailyInsight: DailyInsight?
    @Published var weeklyTrends: [DailyTrend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var scoreEngine: ScoreEngine?
    private let insightGenerator = InsightGenerator()

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

            // Get previous day strain for insight generation
            previousDayStrain = trendData.strain.first {
                Calendar.current.isDate($0.date, inSameDayAs: Date().daysAgo(1))
            }

            // Generate daily insight
            dailyInsight = await insightGenerator.generateInsight(
                recovery: rec,
                strain: str,
                sleep: slp,
                previousDayStrain: previousDayStrain
            )
        } catch {
            errorMessage = error.localizedDescription
            // Show no data insight when there's an error
            dailyInsight = .noData
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
}

struct DailyTrend: Identifiable {
    let id = UUID()
    let date: Date
    let recoveryScore: Double
    let strainScore: Double
    let sleepScore: Double
}
