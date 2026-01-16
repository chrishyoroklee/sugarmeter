import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

final class SugarMeterViewModel: ObservableObject {
    @Published private(set) var totalSugarGrams: Int = 0
    @Published private(set) var logCount: Int = 0
    @Published private(set) var dailyLimit: Int
    @Published var levelMessage: LevelMessage?
    @Published private(set) var thresholdMultipliers: ThresholdMultipliers
    @Published private(set) var displayedItems: [SugarItem]
    @Published private(set) var libraryItems: [SugarItem]
    let visualCapacityMultiplier: Double
    private let logStore = DailySugarLogStore()
    private let minimumVisualCapacityGrams = 180
    private let lastResetKey = "lastResetDate"
    private static let recentItemsKey = "recentSugarItems"
    private static let featuredItemCount = 10
    private static let customItemsKey = "customSugarItems"
    private var resetTimer: Timer?
    private var lastNotifiedLevel: SugarLevel = .l1
    private var featuredItemNames: [String]
    private let mainBaseItems: [SugarItem]
    private let libraryBaseItems: [SugarItem]
    private var customItems: [CustomSugarItem]

    init(
        dailyLimit: Int = 36,
        items: [SugarItem] = SugarMeterViewModel.defaultItems,
        libraryItems: [SugarItem] = SugarMeterViewModel.defaultLibraryItems,
        visualCapacityMultiplier: Double = 5.0,
        thresholdMultipliers: ThresholdMultipliers = .default
    ) {
        let baseItems = items
        let libraryBaseItems = libraryItems
        let customItems = Self.loadCustomItems()
        let customSugarItems = customItems.map { $0.asSugarItem() }
        let combinedLibraryItems = libraryBaseItems + customSugarItems
        let storedFeaturedNames = Self.loadRecentItems()
        let normalizedFeaturedNames = Self.normalizeFeaturedNames(
            storedFeaturedNames,
            defaultItems: baseItems,
            libraryItems: combinedLibraryItems
        )
        let featuredItems = Self.items(from: normalizedFeaturedNames, in: combinedLibraryItems)
        let displayedItems = featuredItems + customSugarItems

        self.dailyLimit = max(dailyLimit, 1)
        self.mainBaseItems = baseItems
        self.libraryBaseItems = libraryBaseItems
        self.customItems = customItems
        self.libraryItems = combinedLibraryItems
        self.visualCapacityMultiplier = max(visualCapacityMultiplier, 1)
        self.thresholdMultipliers = thresholdMultipliers.normalized()
        self.featuredItemNames = normalizedFeaturedNames
        self.displayedItems = displayedItems
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
        updateFeaturedItems(with: item)
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
        reloadWidgets()
    }

    func updateThresholdMultipliers(_ multipliers: ThresholdMultipliers) {
        thresholdMultipliers = multipliers.normalized()
        lastNotifiedLevel = currentLevel
    }

    func addCustomItem(name: String, grams: Int, category: SugarItemCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, grams > 0 else { return }
        let lowercased = trimmed.lowercased()
        guard !libraryItems.contains(where: { $0.storageKey.lowercased() == lowercased }) else { return }

        let customItem = CustomSugarItem(name: trimmed, grams: grams, category: category)
        customItems.append(customItem)
        saveCustomItems(customItems)
        refreshItems()
    }

    func removeCustomItem(_ item: SugarItem) {
        guard item.isCustom else { return }
        let lowercased = item.storageKey.lowercased()
        customItems.removeAll { $0.name.lowercased() == lowercased }
        saveCustomItems(customItems)
        refreshItems()
    }

    private func grams(for item: SugarItem, size: SugarItemSize) -> Int {
        Int((Double(item.sugarGrams) * size.multiplier).rounded())
    }

    func clearLevelMessage() {
        levelMessage = nil
    }

    private func persistCurrentLog() {
        logStore.saveLog(grams: totalSugarGrams, count: logCount, for: Date())
        reloadWidgets()
    }

    private func reloadWidgets() {
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
#endif
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

    private func updateFeaturedItems(with item: SugarItem) {
        guard !item.isCustom else { return }
        let name = item.storageKey

        featuredItemNames.removeAll { $0 == name }
        featuredItemNames.insert(name, at: 0)

        if featuredItemNames.count > Self.featuredItemCount {
            featuredItemNames = Array(featuredItemNames.prefix(Self.featuredItemCount))
        }

        refreshDisplayedItems()
    }

    private func refreshDisplayedItems() {
        let nonCustomLibraryItems = libraryItems.filter { !$0.isCustom }
        let validNames = Set(nonCustomLibraryItems.map { $0.storageKey })

        featuredItemNames = featuredItemNames.filter { validNames.contains($0) }

        if featuredItemNames.count < Self.featuredItemCount {
            let fillItems = mainBaseItems.map { $0.storageKey }
            for name in fillItems where !featuredItemNames.contains(name) {
                featuredItemNames.append(name)
                if featuredItemNames.count == Self.featuredItemCount {
                    break
                }
            }
        }

        saveRecentItems(featuredItemNames)

        let featuredItems = Self.items(from: featuredItemNames, in: nonCustomLibraryItems)
        let customSugarItems = customItems.map { $0.asSugarItem() }
        displayedItems = featuredItems + customSugarItems
    }

    private func refreshItems() {
        let customSugarItems = customItems.map { $0.asSugarItem() }
        libraryItems = libraryBaseItems + customSugarItems
        refreshDisplayedItems()
    }

    private static func loadRecentItems() -> [String] {
        UserDefaults.standard.stringArray(forKey: recentItemsKey) ?? []
    }

    private func saveRecentItems(_ names: [String]) {
        UserDefaults.standard.set(names, forKey: Self.recentItemsKey)
    }

    private static func normalizeFeaturedNames(
        _ stored: [String],
        defaultItems: [SugarItem],
        libraryItems: [SugarItem]
    ) -> [String] {
        let validNames = Set(libraryItems.filter { !$0.isCustom }.map { $0.storageKey })
        var names = stored.filter { validNames.contains($0) }

        if names.isEmpty {
            names = defaultItems.map { $0.storageKey }
        }

        if names.count < featuredItemCount {
            for name in defaultItems.map({ $0.storageKey }) where !names.contains(name) {
                names.append(name)
                if names.count == featuredItemCount {
                    break
                }
            }
        }

        if names.count > featuredItemCount {
            names = Array(names.prefix(featuredItemCount))
        }

        return names
    }

    private static func items(from names: [String], in items: [SugarItem]) -> [SugarItem] {
        var remaining = items
        var ordered: [SugarItem] = []

        for name in names {
            if let index = remaining.firstIndex(where: { $0.storageKey == name }) {
                ordered.append(remaining.remove(at: index))
            }
        }

        return ordered
    }

    private static func loadCustomItems() -> [CustomSugarItem] {
        guard let data = UserDefaults.standard.data(forKey: customItemsKey) else { return [] }
        return (try? JSONDecoder().decode([CustomSugarItem].self, from: data)) ?? []
    }

    private func saveCustomItems(_ items: [CustomSugarItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.customItemsKey)
    }

    deinit {
        resetTimer?.invalidate()
    }
}

private struct CustomSugarItem: Codable, Equatable {
    let name: String
    let grams: Int
    let category: SugarItemCategory

    private enum CodingKeys: String, CodingKey {
        case name
        case grams
        case category
    }

    init(name: String, grams: Int, category: SugarItemCategory) {
        self.name = name
        self.grams = grams
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        grams = try container.decode(Int.self, forKey: .grams)
        category = try container.decodeIfPresent(SugarItemCategory.self, forKey: .category) ?? .custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(grams, forKey: .grams)
        try container.encode(category, forKey: .category)
    }

    func asSugarItem() -> SugarItem {
        SugarItem(name: name, sugarGrams: grams, isCustom: true, category: category)
    }
}

extension SugarMeterViewModel {
    static let defaultItems: [SugarItem] = [
        SugarItem(name: "Donut", sugarGrams: 22, imageName: "donut", category: .bakery),
        SugarItem(name: "Can of Soda", sugarGrams: 39, imageName: "soda", category: .drink),
        SugarItem(name: "Chocolate Bar", sugarGrams: 24, imageName: "chocolate-bar", category: .candy),
        SugarItem(name: "Ice Cream Scoop", sugarGrams: 15, imageName: "ice-cream", category: .dessert),
        SugarItem(name: "Cookie", sugarGrams: 12, imageName: "cookie", category: .bakery),
        SugarItem(name: "Energy Drink", sugarGrams: 27, imageName: "energy-drink", category: .drink),
        SugarItem(name: "Bowl of Cereal", sugarGrams: 20, imageName: "cereal", category: .breakfast),
        SugarItem(name: "Frappuccino", sugarGrams: 45, imageName: "frappucino", category: .drink),
        SugarItem(name: "Candy Pack", sugarGrams: 30, imageName: "candy", category: .candy),
        SugarItem(name: "Juice Box", sugarGrams: 18, imageName: "juice-box", category: .drink)
    ]

    static let defaultLibraryItems: [SugarItem] = {
        let extras: [SugarItem] = [
            SugarItem(name: "Muffin", sugarGrams: 32, category: .bakery),
            SugarItem(name: "Croissant", sugarGrams: 9, category: .bakery),
            SugarItem(name: "Cupcake", sugarGrams: 27, category: .bakery),
            SugarItem(name: "Brownie", sugarGrams: 28, category: .bakery),
            SugarItem(name: "Lemonade", sugarGrams: 26, category: .drink),
            SugarItem(name: "Sweet Tea", sugarGrams: 24, category: .drink),
            SugarItem(name: "Sports Drink", sugarGrams: 21, category: .drink),
            SugarItem(name: "Chocolate Milk", sugarGrams: 24, category: .drink),
            SugarItem(name: "Bubble Tea", sugarGrams: 38, category: .drink),
            SugarItem(name: "Milkshake", sugarGrams: 60, category: .drink),
            SugarItem(name: "Smoothie (Store-bought)", sugarGrams: 40, category: .drink),
            SugarItem(name: "Chocolate Bar", sugarGrams: 24, category: .candy),
            SugarItem(name: "Candy Pack", sugarGrams: 30, category: .candy),
            SugarItem(name: "Gummy Candy", sugarGrams: 23, category: .candy),
            SugarItem(name: "Fruit Snacks", sugarGrams: 15, category: .candy),
            SugarItem(name: "Ice Cream Scoop", sugarGrams: 15, category: .dessert),
            SugarItem(name: "Ice Cream Bar", sugarGrams: 24, category: .dessert),
            SugarItem(name: "Frozen Yogurt", sugarGrams: 30, category: .dessert),
            SugarItem(name: "Bowl of Cereal", sugarGrams: 20, category: .breakfast),
            SugarItem(name: "Granola Bar", sugarGrams: 14, category: .breakfast),
            SugarItem(name: "Flavored Yogurt", sugarGrams: 18, category: .breakfast),
            SugarItem(name: "Flavored Oatmeal Packet", sugarGrams: 12, category: .breakfast),
            SugarItem(name: "Pancake Syrup (2 tbsp)", sugarGrams: 26, category: .breakfast),
            SugarItem(name: "Ketchup (2 tbsp)", sugarGrams: 8, category: .condiment),
            SugarItem(name: "BBQ Sauce (2 tbsp)", sugarGrams: 12, category: .condiment),
            SugarItem(name: "Nutella (2 tbsp)", sugarGrams: 21, category: .condiment),
            SugarItem(name: "Jam/Jelly (2 tbsp)", sugarGrams: 20, category: .condiment),
            SugarItem(name: "Honey (1 tbsp)", sugarGrams: 17, category: .condiment),
            SugarItem(name: "Maple Syrup (2 tbsp)", sugarGrams: 24, category: .condiment),
            SugarItem(name: "Protein Bar", sugarGrams: 16, category: .snack),
            SugarItem(name: "Trail Mix (Sweetened)", sugarGrams: 12, category: .snack),
            SugarItem(name: "Granola", sugarGrams: 10, category: .snack),
            SugarItem(name: "Acai Bowl", sugarGrams: 38, category: .snack),
            SugarItem(name: "McFlurry", sugarGrams: 63, category: .fastfood),
            SugarItem(name: "Blizzard", sugarGrams: 65, category: .fastfood),
            SugarItem(name: "Chocolate Milk Box", sugarGrams: 18, category: .kids),
            SugarItem(name: "Yogurt Tube", sugarGrams: 10, category: .kids),
            SugarItem(name: "Frosted Cereal", sugarGrams: 18, category: .kids)
        ]
        return defaultItems + extras
    }()
}
