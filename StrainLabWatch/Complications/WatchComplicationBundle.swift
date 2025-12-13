import SwiftUI
import WidgetKit

/// WidgetKit bundle for Apple Watch complications
/// This will be the entry point when complications are built as a separate widget extension
/// Currently kept without @main to avoid conflict with StrainLabWatchApp
struct WatchComplicationBundle: WidgetBundle {
    var body: some Widget {
        RecoveryWatchComplication()
        StrainWatchComplication()
    }
}
