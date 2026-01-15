import Foundation

enum AppGroup {
    static let identifier = "group.com.hyoroklee.sugarmeter"
    static let dailyLimitKey = "dailySugarLimit"
    static let logHistoryKey = "dailySugarLogs"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static func migrateIfNeeded() {
        guard let shared = UserDefaults(suiteName: identifier) else { return }
        let keys = [dailyLimitKey, logHistoryKey]
        for key in keys where shared.object(forKey: key) == nil {
            if let value = UserDefaults.standard.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }
    }
}
