import ClockKit
import SwiftUI

/// Provides complication data for Apple Watch faces
class ComplicationController: NSObject, CLKComplicationDataSource {

    private let dataProvider = ComplicationDataProvider.shared

    // MARK: - Timeline Configuration

    func getComplicationDescriptors(
        handler: @escaping ([CLKComplicationDescriptor]) -> Void
    ) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "RecoveryComplication",
                displayName: "Recovery",
                supportedFamilies: [
                    .circularSmall,
                    .graphicCircular,
                    .graphicCorner,
                    .modularSmall,
                    .utilitarianSmall,
                    .graphicRectangular
                ]
            )
        ]
        handler(descriptors)
    }

    func getPrivacyBehavior(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void
    ) {
        handler(.hideOnLockScreen)
    }

    // MARK: - Timeline Population

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let data = dataProvider.getCurrentData()
        let template = makeTemplate(for: complication.family, data: data)

        if let template = template {
            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: template
            )
            handler(entry)
        } else {
            handler(nil)
        }
    }

    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // No future entries - data updates when app runs
        handler(nil)
    }

    func getTimelineEndDate(
        for complication: CLKComplication,
        withHandler handler: @escaping (Date?) -> Void
    ) {
        // No end date - always show current data
        handler(nil)
    }

    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        let sampleData = ComplicationData(
            recoveryScore: 75,
            recoveryCategory: .optimal,
            strainScore: 12.5
        )
        let template = makeTemplate(for: complication.family, data: sampleData)
        handler(template)
    }

    // MARK: - Template Creation

    private func makeTemplate(
        for family: CLKComplicationFamily,
        data: ComplicationData
    ) -> CLKComplicationTemplate? {
        switch family {
        case .circularSmall:
            return makeCircularSmallTemplate(data: data)
        case .graphicCircular:
            return makeGraphicCircularTemplate(data: data)
        case .graphicCorner:
            return makeGraphicCornerTemplate(data: data)
        case .modularSmall:
            return makeModularSmallTemplate(data: data)
        case .utilitarianSmall:
            return makeUtilitarianSmallTemplate(data: data)
        case .graphicRectangular:
            return makeGraphicRectangularTemplate(data: data)
        default:
            return nil
        }
    }

    private func makeCircularSmallTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallRingText(
            textProvider: CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))"),
            fillFraction: Float(data.recoveryScore / 100),
            ringStyle: .closed
        )
        template.tintColor = data.recoveryCategory.uiColor
        return template
    }

    private func makeGraphicCircularTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let gaugeProvider = CLKSimpleGaugeProvider(
            style: .ring,
            gaugeColor: data.recoveryCategory.uiColor,
            fillFraction: Float(data.recoveryScore / 100)
        )

        return CLKComplicationTemplateGraphicCircularClosedGaugeText(
            gaugeProvider: gaugeProvider,
            centerTextProvider: CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))")
        )
    }

    private func makeGraphicCornerTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let gaugeProvider = CLKSimpleGaugeProvider(
            style: .fill,
            gaugeColor: data.recoveryCategory.uiColor,
            fillFraction: Float(data.recoveryScore / 100)
        )

        return CLKComplicationTemplateGraphicCornerGaugeText(
            gaugeProvider: gaugeProvider,
            outerTextProvider: CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))%")
        )
    }

    private func makeModularSmallTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallRingText(
            textProvider: CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))"),
            fillFraction: Float(data.recoveryScore / 100),
            ringStyle: .closed
        )
        template.tintColor = data.recoveryCategory.uiColor
        return template
    }

    private func makeUtilitarianSmallTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallRingText(
            textProvider: CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))"),
            fillFraction: Float(data.recoveryScore / 100),
            ringStyle: .closed
        )
        template.tintColor = data.recoveryCategory.uiColor
        return template
    }

    private func makeGraphicRectangularTemplate(data: ComplicationData) -> CLKComplicationTemplate {
        let headerText = CLKSimpleTextProvider(text: "RECOVERY")
        let bodyText = CLKSimpleTextProvider(text: "\(Int(data.recoveryScore))% \(data.recoveryCategory.displayName)")

        let gaugeProvider = CLKSimpleGaugeProvider(
            style: .fill,
            gaugeColor: data.recoveryCategory.uiColor,
            fillFraction: Float(data.recoveryScore / 100)
        )

        return CLKComplicationTemplateGraphicRectangularTextGauge(
            headerTextProvider: headerText,
            body1TextProvider: bodyText,
            gaugeProvider: gaugeProvider
        )
    }
}
