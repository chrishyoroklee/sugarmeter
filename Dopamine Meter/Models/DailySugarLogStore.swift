import Foundation

struct DailySugarLog: Codable, Equatable {
    let grams: Int
    let count: Int
}

final class DailySugarLogStore {
    private let historyKey = AppGroup.logHistoryKey
    private let userDefaults: UserDefaults
    private let dateFormatter: DateFormatter

    init(userDefaults: UserDefaults = AppGroup.userDefaults) {
        AppGroup.migrateIfNeeded()
        self.userDefaults = userDefaults
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.timeZone = .current
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    func log(for date: Date) -> DailySugarLog {
        let key = dateKey(for: date)
        return history()[key] ?? DailySugarLog(grams: 0, count: 0)
    }

    func saveLog(grams: Int, count: Int, for date: Date) {
        var logs = history()
        logs[dateKey(for: date)] = DailySugarLog(grams: grams, count: count)
        saveHistory(logs)
    }

    func loggedDateKeys(minGrams: Int = 1) -> Set<String> {
        let logs = history()
        let keys = logs.compactMap { key, log -> String? in
            log.grams >= minGrams ? key : nil
        }
        return Set(keys)
    }

    func dateKeyString(for date: Date) -> String {
        dateKey(for: date)
    }

    private func history() -> [String: DailySugarLog] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: DailySugarLog].self, from: data)) ?? [:]
    }

    private func saveHistory(_ logs: [String: DailySugarLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            userDefaults.set(data, forKey: historyKey)
        }
    }

    private func dateKey(for date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
