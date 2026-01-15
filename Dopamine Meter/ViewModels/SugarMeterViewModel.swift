import SwiftUI

final class SugarMeterViewModel: ObservableObject {
    @Published private(set) var totalSugarGrams: Int = 0
    @Published private(set) var logCount: Int = 0
    @Published private(set) var dailyLimit: Int
    @Published var levelMessage: LevelMessage?
    @Published private(set) var thresholdMultipliers: ThresholdMultipliers
    @Published private(set) var displayedItems: [SugarItem]
    let items: [SugarItem]
    let visualCapacityMultiplier: Double
    private let logStore = DailySugarLogStore()
    private let minimumVisualCapacityGrams = 180
    private let lastResetKey = "lastResetDate"
    private static let recentItemsKey = "recentSugarItems"
    private var resetTimer: Timer?
    private var lastNotifiedLevel: SugarLevel = .l1
    private var recentItemNames: [String]

    init(
        dailyLimit: Int = 36,
        items: [SugarItem] = SugarMeterViewModel.defaultItems,
        visualCapacityMultiplier: Double = 5.0,
        thresholdMultipliers: ThresholdMultipliers = .default
    ) {
        self.dailyLimit = max(dailyLimit, 1)
        self.items = items
        self.visualCapacityMultiplier = max(visualCapacityMultiplier, 1)
        self.thresholdMultipliers = thresholdMultipliers.normalized()
        self.recentItemNames = Self.loadRecentItems()
        self.displayedItems = Self.orderItems(items: items, recentNames: self.recentItemNames)
        let storedLog = logStore.log(for: Date())
        self.totalSugarGrams = storedLog.grams
        self.logCount = storedLog.count
    }

    var visualFillLevel: Double {
        let capacity = maxVisualGrams
        guard capacity > 0 else { return 0 }
        return min(Double(totalSugarGrams) / Double(capacity), 1.0)
    }

    var limitProgress: Double {
        guard dailyLimit > 0 else { return 0 }
        return Double(totalSugarGrams) / Double(dailyLimit)
    }

    var recommendedLevel: Double {
        let capacity = maxVisualGrams
        guard capacity > 0 else { return 0 }
        return Double(dailyLimit) / Double(capacity)
    }

    private var maxVisualGrams: Int {
        let thresholdMultiplier = thresholdMultipliers.normalized().l5
        let baseMultiplier = max(visualCapacityMultiplier, thresholdMultiplier)
        return max(Int(Double(dailyLimit) * baseMultiplier), minimumVisualCapacityGrams)
    }

    var currentLevel: SugarLevel {
        SugarLevel.level(for: totalSugarGrams, dailyLimit: dailyLimit, multipliers: thresholdMultipliers)
    }

    var liquidPalette: LiquidPalette {
        currentLevel.liquidPalette
    }

    var ringLines: [RingLine] {
        let capacity = Double(maxVisualGrams)
        guard capacity > 0 else { return [] }
        let recommended = Double(dailyLimit) / capacity
        let lines = SugarLevel.thresholds(for: dailyLimit, multipliers: thresholdMultipliers).map { threshold in
            RingLine(
                fraction: min(Double(threshold.grams) / capacity, 1.0),
                color: threshold.level.color,
                isDashed: threshold.isDashed
            )
        }
        return lines.filter { abs($0.fraction - recommended) > 0.01 }
    }

    func logSugar(_ item: SugarItem) {
        logSugar(item, size: .medium)
    }

    func logSugar(_ item: SugarItem, size: SugarItemSize) {
        ensureDailyReset()
        updateRecents(with: item)
        withAnimation(.easeInOut(duration: 0.6)) {
            totalSugarGrams += grams(for: item, size: size)
            logCount += 1
        }
        persistCurrentLog()
        notifyLevelIfNeeded()
    }

    func reset() {
        withAnimation(.easeInOut(duration: 0.4)) {
            totalSugarGrams = 0
            logCount = 0
        }
        lastNotifiedLevel = .l1
        persistCurrentLog()
    }

    func updateDailyLimit(_ newLimit: Int) {
        dailyLimit = max(newLimit, 1)
    }

    func updateThresholdMultipliers(_ multipliers: ThresholdMultipliers) {
        thresholdMultipliers = multipliers.normalized()
        lastNotifiedLevel = currentLevel
    }

    private func grams(for item: SugarItem, size: SugarItemSize) -> Int {
        Int((Double(item.sugarGrams) * size.multiplier).rounded())
    }

    func clearLevelMessage() {
        levelMessage = nil
    }

    private func persistCurrentLog() {
        logStore.saveLog(grams: totalSugarGrams, count: logCount, for: Date())
    }

    func ensureDailyReset() {
        let now = Date()
        guard let lastReset = loadLastResetDate() else {
            updateLastResetDate(now)
            return
        }
        if !Calendar.current.isDate(lastReset, inSameDayAs: now) {
            reset()
            updateLastResetDate(now)
        }
    }

    func startDailyResetTimer() {
        resetTimer?.invalidate()
        scheduleNextMidnightReset()
    }

    private func notifyLevelIfNeeded() {
        let level = SugarLevel.level(for: totalSugarGrams, dailyLimit: dailyLimit, multipliers: thresholdMultipliers)
        guard level.rawValue > lastNotifiedLevel.rawValue else { return }
        lastNotifiedLevel = level
        if let message = level.message(dailyLimit: dailyLimit, multipliers: thresholdMultipliers) {
            levelMessage = message
        }
    }

    private func scheduleNextMidnightReset() {
        let calendar = Calendar.current
        let now = Date()
        guard let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else {
            return
        }
        let interval = nextMidnight.timeIntervalSince(now)
        resetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.reset()
            self?.updateLastResetDate(Date())
            self?.scheduleNextMidnightReset()
        }
    }

    private func loadLastResetDate() -> Date? {
        UserDefaults.standard.object(forKey: lastResetKey) as? Date
    }

    private func updateLastResetDate(_ date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        UserDefaults.standard.set(startOfDay, forKey: lastResetKey)
    }

    private func updateRecents(with item: SugarItem) {
        recentItemNames.removeAll { $0 == item.storageKey }
        recentItemNames.insert(item.storageKey, at: 0)
        let validNames = Set(items.map { $0.storageKey })
        recentItemNames = recentItemNames.filter { validNames.contains($0) }
        saveRecentItems(recentItemNames)
        displayedItems = Self.orderItems(items: items, recentNames: recentItemNames)
    }

    private static func orderItems(items: [SugarItem], recentNames: [String]) -> [SugarItem] {
        var remaining = items
        var ordered: [SugarItem] = []

        for name in recentNames {
            if let index = remaining.firstIndex(where: { $0.storageKey == name }) {
                ordered.append(remaining.remove(at: index))
            }
        }

        ordered.append(contentsOf: remaining)
        return ordered
    }

    private static func loadRecentItems() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentItemsKey) ?? []
    }

    private func saveRecentItems(_ names: [String]) {
        UserDefaults.standard.set(names, forKey: Self.recentItemsKey)
    }

    deinit {
        resetTimer?.invalidate()
    }
}

extension SugarMeterViewModel {
    static let defaultItems: [SugarItem] = [
        SugarItem(name: "Donut", sugarGrams: 22, imageName: "donut"),
        SugarItem(name: "Can of Soda", sugarGrams: 39, imageName: "soda"),
        SugarItem(name: "Chocolate Bar", sugarGrams: 24, imageName: "chocolate-bar"),
        SugarItem(name: "Ice Cream Scoop", sugarGrams: 15, imageName: "ice-cream"),
        SugarItem(name: "Cookie", sugarGrams: 12, imageName: "cookie"),
        SugarItem(name: "Energy Drink", sugarGrams: 27, imageName: "energy-drink"),
        SugarItem(name: "Bowl of Cereal", sugarGrams: 20, imageName: "cereal"),
        SugarItem(name: "Frappuccino", sugarGrams: 45, imageName: "frappucino"),
        SugarItem(name: "Candy Pack", sugarGrams: 30, imageName: "candy"),
        SugarItem(name: "Juice Box", sugarGrams: 18, imageName: "juice-box")
    ]
}
