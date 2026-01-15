import SwiftUI

final class SugarMeterViewModel: ObservableObject {
    @Published private(set) var totalSugarGrams: Int = 0
    @Published private(set) var logCount: Int = 0
    @Published private(set) var dailyLimit: Int
    let items: [SugarItem]

    init(dailyLimit: Int = 36, items: [SugarItem] = SugarMeterViewModel.defaultItems) {
        self.dailyLimit = max(dailyLimit, 1)
        self.items = items
    }

    var fillLevel: Double {
        guard dailyLimit > 0 else { return 0 }
        return min(Double(totalSugarGrams) / Double(dailyLimit), 1.0)
    }

    var isFull: Bool {
        totalSugarGrams >= dailyLimit
    }

    func logSugar(_ item: SugarItem) {
        guard !isFull else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            totalSugarGrams += item.sugarGrams
            logCount += 1
        }
    }

    func reset() {
        withAnimation(.easeInOut(duration: 0.4)) {
            totalSugarGrams = 0
            logCount = 0
        }
    }

    func updateDailyLimit(_ newLimit: Int) {
        dailyLimit = max(newLimit, 1)
    }
}

extension SugarMeterViewModel {
    static let defaultItems: [SugarItem] = [
        SugarItem(name: "Donut", sugarGrams: 22),
        SugarItem(name: "Can of Soda", sugarGrams: 39),
        SugarItem(name: "Chocolate Bar", sugarGrams: 24),
        SugarItem(name: "Ice Cream Scoop", sugarGrams: 15),
        SugarItem(name: "Cookie", sugarGrams: 12),
        SugarItem(name: "Energy Drink", sugarGrams: 27),
        SugarItem(name: "Bowl of Cereal", sugarGrams: 20),
        SugarItem(name: "Frappuccino", sugarGrams: 45),
        SugarItem(name: "Candy Pack", sugarGrams: 30),
        SugarItem(name: "Juice Box", sugarGrams: 18)
    ]
}
