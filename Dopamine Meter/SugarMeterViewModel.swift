import SwiftUI

enum SugarLogType {
    case donut
    case candy

    var increment: Int {
        1
    }
}

final class SugarMeterViewModel: ObservableObject {
    @Published private(set) var sugarLogs: Int = 0
    let maxLogs: Int

    init(maxLogs: Int = 10) {
        self.maxLogs = maxLogs
    }

    var fillLevel: Double {
        guard maxLogs > 0 else { return 0 }
        return min(Double(sugarLogs) / Double(maxLogs), 1.0)
    }

    var isFull: Bool {
        sugarLogs >= maxLogs
    }

    func logSugar(_ type: SugarLogType) {
        guard !isFull else { return }
        let newValue = min(sugarLogs + type.increment, maxLogs)
        withAnimation(.easeInOut(duration: 0.6)) {
            sugarLogs = newValue
        }
    }

    func reset() {
        withAnimation(.easeInOut(duration: 0.4)) {
            sugarLogs = 0
        }
    }
}
