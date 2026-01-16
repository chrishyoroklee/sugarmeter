import WidgetKit
import SwiftUI

struct SugaMeterEntry: TimelineEntry {
    let date: Date
    let totalGrams: Int
    let dailyLimit: Int
    let fillFraction: Double
    let progress: Double
    let statusLabel: String
    let statusColor: Color
}

struct SugaMeterProvider: TimelineProvider {
    func placeholder(in context: Context) -> SugaMeterEntry {
        makeEntry(totalGrams: 22, dailyLimit: 36)
    }

    func getSnapshot(in context: Context, completion: @escaping (SugaMeterEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SugaMeterEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> SugaMeterEntry {
        let defaults = UserDefaults(suiteName: WidgetConstants.appGroupID) ?? .standard
        let limitValue = defaults.integer(forKey: WidgetConstants.dailyLimitKey)
        let dailyLimit = limitValue > 0 ? limitValue : WidgetConstants.defaultLimit
        let logStore = WidgetLogStore(userDefaults: defaults)
        let log = logStore.log(for: Date())
        return makeEntry(totalGrams: log.grams, dailyLimit: dailyLimit)
    }

    private func makeEntry(totalGrams: Int, dailyLimit: Int) -> SugaMeterEntry {
        let maxVisual = max(dailyLimit * 5, 180)
        let fillFraction = min(Double(totalGrams) / Double(maxVisual), 1.0)
        let progress = min(Double(totalGrams) / Double(max(dailyLimit, 1)), 1.0)
        let (label, color) = status(for: totalGrams, limit: dailyLimit)

        return SugaMeterEntry(
            date: Date(),
            totalGrams: totalGrams,
            dailyLimit: dailyLimit,
            fillFraction: fillFraction,
            progress: progress,
            statusLabel: label,
            statusColor: color
        )
    }

    private func status(for grams: Int, limit: Int) -> (String, Color) {
        let l1Max = limit
        let l2Max = limit * 2
        let l3Max = limit * 4
        let l4Max = limit * 5

        if grams <= l1Max {
            return ("In target", WidgetTheme.levelGreen)
        }
        if grams <= l2Max {
            return ("Caution", WidgetTheme.levelYellow)
        }
        if grams <= l3Max {
            return ("Warning", WidgetTheme.levelOrange)
        }
        if grams <= l4Max {
            return ("High", WidgetTheme.levelRed)
        }
        return ("OMG", WidgetTheme.levelPurple)
    }
}

struct SugaMeterWidget: Widget {
    let kind: String = "SugaMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SugaMeterProvider()) { entry in
            SugaMeterWidgetView(entry: entry)
        }
        .configurationDisplayName("SugaMeter")
        .description("See today’s sugar meter at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct SugaMeterLockScreenWidget: Widget {
    let kind: String = "SugaMeterLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SugaMeterProvider()) { entry in
            SugaMeterWidgetView(entry: entry)
        }
        .configurationDisplayName("SugaMeter (Lock Screen)")
        .description("Quick sugar snapshot for your lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct SugaMeterWidgetView: View {
    let entry: SugaMeterEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .accessoryCircular:
                accessoryCircularView
            case .accessoryRectangular:
                accessoryRectangularView
            case .accessoryInline:
                accessoryInlineView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall || family == .systemMedium {
                WidgetBackground()
            } else {
                Color.clear
            }
        }
    }

    private var smallView: some View {
        VStack(spacing: 10) {
            Text("SugaMeter")
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .foregroundStyle(WidgetTheme.textPrimary)

            WidgetJarView(fillFraction: entry.fillFraction, fillColor: entry.statusColor)
                .frame(width: 70, height: 80)

            Text("\(entry.totalGrams)g / \(entry.dailyLimit)g")
                .font(.custom("AvenirNext-Medium", size: 11))
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .padding(12)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            WidgetJarView(fillFraction: entry.fillFraction, fillColor: entry.statusColor)
                .frame(width: 80, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text("SugaMeter")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(WidgetTheme.textPrimary)
                Text("\(entry.totalGrams)g logged")
                    .font(.custom("AvenirNext-Heavy", size: 18))
                    .foregroundStyle(entry.statusColor)
                Text("Goal \(entry.dailyLimit)g · \(entry.statusLabel)")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var accessoryCircularView: some View {
        Gauge(value: entry.progress) {
            Text("Sugar")
        } currentValueLabel: {
            Text("\(entry.totalGrams)g")
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.statusColor)
    }

    private var accessoryRectangularView: some View {
        HStack(spacing: 8) {
            WidgetJarView(fillFraction: entry.fillFraction, fillColor: entry.statusColor)
                .frame(width: 28, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("SugaMeter")
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                Text("\(entry.totalGrams)g · \(entry.statusLabel)")
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(entry.statusColor)
            }
        }
        .foregroundStyle(WidgetTheme.textPrimary)
    }

    private var accessoryInlineView: some View {
        Text("Sugar \(entry.totalGrams)g")
    }
}

private struct WidgetJarView: View {
    let fillFraction: Double
    let fillColor: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let corner = size.width * 0.2

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(WidgetTheme.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(Color.white.opacity(0.6))
                    )

                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                fillColor.opacity(0.95),
                                fillColor.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: max(size.height * fillFraction, 2))
                    .mask(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                    )
            }
        }
    }
}

private struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                WidgetTheme.backgroundTop,
                WidgetTheme.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum WidgetTheme {
    static let backgroundTop = Color(red: 0.98, green: 0.95, blue: 0.9)
    static let backgroundBottom = Color(red: 0.88, green: 0.9, blue: 0.96)
    static let textPrimary = Color(red: 0.2, green: 0.18, blue: 0.18)
    static let textSecondary = Color(red: 0.35, green: 0.32, blue: 0.32)
    static let border = Color(red: 0.78, green: 0.72, blue: 0.68)

    static let levelGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let levelYellow = Color(red: 0.95, green: 0.8, blue: 0.2)
    static let levelOrange = Color(red: 0.95, green: 0.55, blue: 0.2)
    static let levelRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let levelPurple = Color(red: 0.62, green: 0.28, blue: 0.84)
}

private enum WidgetConstants {
    static let appGroupID = "group.com.hyoroklee.sugarmeter"
    static let dailyLimitKey = "dailySugarLimit"
    static let logHistoryKey = "dailySugarLogs"
    static let defaultLimit = 36
}

private struct WidgetDailySugarLog: Codable {
    let grams: Int
    let count: Int
}

private struct WidgetLogStore {
    private let historyKey = WidgetConstants.logHistoryKey
    private let userDefaults: UserDefaults
    private let dateFormatter: DateFormatter

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.timeZone = .current
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    func log(for date: Date) -> WidgetDailySugarLog {
        let key = dateKey(for: date)
        return history()[key] ?? WidgetDailySugarLog(grams: 0, count: 0)
    }

    private func history() -> [String: WidgetDailySugarLog] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: WidgetDailySugarLog].self, from: data)) ?? [:]
    }

    private func dateKey(for date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

#Preview(as: .systemSmall) {
    SugaMeterWidget()
} timeline: {
    SugaMeterEntry(
        date: .now,
        totalGrams: 22,
        dailyLimit: 36,
        fillFraction: 0.25,
        progress: 0.6,
        statusLabel: "In target",
        statusColor: WidgetTheme.levelGreen
    )
}
