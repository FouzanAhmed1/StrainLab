import WatchKit
import WidgetKit

/// App delegate for handling watchOS lifecycle events and background tasks
class WatchAppDelegate: NSObject, WKApplicationDelegate {

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching() {
        // Register for background refresh
        WatchBackgroundManager.shared.registerBackgroundTasks()

        // Schedule initial background refresh
        WatchBackgroundManager.shared.scheduleNextRefresh()

        print("WatchAppDelegate: App launched, background tasks registered")
    }

    func applicationDidBecomeActive() {
        // Reload complications when app becomes active
        WidgetCenter.shared.reloadAllTimelines()
    }

    func applicationWillResignActive() {
        // Schedule background refresh when going to background
        WatchBackgroundManager.shared.scheduleNextRefresh()
    }

    // MARK: - Background Task Handling

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                // Handle background app refresh
                Task {
                    await WatchBackgroundManager.shared.handleBackgroundRefresh(refreshTask)
                }

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Handle snapshot refresh (for dock)
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date.distantFuture,
                    userInfo: nil
                )

            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Handle Watch Connectivity background transfers
                // The WCSessionDelegate will handle the actual data
                connectivityTask.setTaskCompletedWithSnapshot(false)

            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Handle URL session background transfers if needed
                urlSessionTask.setTaskCompletedWithSnapshot(false)

            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Handle Siri shortcut refresh if needed
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)

            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Handle Siri intent completion
                intentDidRunTask.setTaskCompletedWithSnapshot(false)

            default:
                // Unknown task type
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
