import SwiftUI

struct LevelMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String
}

struct SugarZone: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let rangeLabel: String
    let lowerBound: Int
    let upperBound: Int?
    let color: Color
}

struct LiquidPalette: Equatable {
    let top: Color
    let mid: Color
    let bottom: Color
    let surfaceTop: Color
    let surfaceBottom: Color
}

struct RingLine: Identifiable, Equatable {
    let id = UUID()
    let fraction: Double
    let color: Color
    let isDashed: Bool
}

struct SugarThreshold: Equatable {
    let grams: Int
    let level: SugarLevel
    let isDashed: Bool
}

struct ThresholdMultipliers: Equatable {
    var l2: Double
    var l3: Double
    var l4: Double
    var l5: Double

    static let `default` = ThresholdMultipliers(l2: 1, l3: 2, l4: 4, l5: 5)

    func normalized() -> ThresholdMultipliers {
        let l2 = max(self.l2, 1)
        let l3 = max(self.l3, l2)
        let l4 = max(self.l4, l3)
        let l5 = max(self.l5, l4)
        return ThresholdMultipliers(l2: l2, l3: l3, l4: l4, l5: l5)
    }
}

enum SugarLevel: Int, CaseIterable {
    case l1 = 1
    case l2 = 2
    case l3 = 3
    case l4 = 4
    case l5 = 5

    static func level(for grams: Int, dailyLimit: Int, multipliers: ThresholdMultipliers) -> SugarLevel {
        let bounds = bounds(for: dailyLimit, multipliers: multipliers)
        if grams <= bounds.l1Max {
            return .l1
        } else if grams <= bounds.l2Max {
            return .l2
        } else if grams <= bounds.l3Max {
            return .l3
        } else if grams <= bounds.l4Max {
            return .l4
        } else {
            return .l5
        }
    }

    static func thresholds(for dailyLimit: Int, multipliers: ThresholdMultipliers) -> [SugarThreshold] {
        let normalized = multipliers.normalized()
        let limit = max(dailyLimit, 1)
        return [
            SugarThreshold(grams: grams(limit, normalized.l2), level: .l2, isDashed: false),
            SugarThreshold(grams: grams(limit, normalized.l3), level: .l3, isDashed: false),
            SugarThreshold(grams: grams(limit, normalized.l4), level: .l4, isDashed: false),
            SugarThreshold(grams: grams(limit, normalized.l5), level: .l5, isDashed: true)
        ]
    }

    static func zones(for dailyLimit: Int, multipliers: ThresholdMultipliers) -> [SugarZone] {
        let bounds = bounds(for: dailyLimit, multipliers: multipliers)
        return [
            SugarZone(
                name: "Healthy Zone",
                rangeLabel: "0-\(bounds.l1Max)g",
                lowerBound: 0,
                upperBound: bounds.l1Max,
                color: Color(red: 0.2, green: 0.7, blue: 0.3)
            ),
            SugarZone(
                name: "Moderate Zone",
                rangeLabel: "\(bounds.l1Max)-\(bounds.l2Max)g",
                lowerBound: bounds.l1Max,
                upperBound: bounds.l2Max,
                color: Color(red: 0.95, green: 0.8, blue: 0.2)
            ),
            SugarZone(
                name: "High Zone",
                rangeLabel: "\(bounds.l2Max)-\(bounds.l3Max)g",
                lowerBound: bounds.l2Max,
                upperBound: bounds.l3Max,
                color: Color(red: 0.95, green: 0.55, blue: 0.2)
            ),
            SugarZone(
                name: "Excess",
                rangeLabel: ">\(bounds.l3Max)g",
                lowerBound: bounds.l3Max,
                upperBound: nil,
                color: Color(red: 0.9, green: 0.2, blue: 0.2)
            )
        ]
    }

    var statusLabel: String {
        switch self {
        case .l1:
            return "In target"
        case .l2:
            return "Caution"
        case .l3:
            return "Warning"
        case .l4:
            return "High"
        case .l5:
            return "OMG"
        }
    }

    var color: Color {
        switch self {
        case .l1:
            return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .l2:
            return Color(red: 0.95, green: 0.8, blue: 0.2)
        case .l3:
            return Color(red: 0.95, green: 0.55, blue: 0.2)
        case .l4:
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .l5:
            return Color(red: 0.62, green: 0.28, blue: 0.84)
        }
    }

    var liquidPalette: LiquidPalette {
        switch self {
        case .l1:
            return LiquidPalette(
                top: Color(red: 1.0, green: 0.84, blue: 0.6).opacity(0.95),
                mid: Color(red: 0.98, green: 0.66, blue: 0.32).opacity(0.96),
                bottom: Color(red: 0.86, green: 0.42, blue: 0.2).opacity(0.98),
                surfaceTop: Color(red: 1.0, green: 0.88, blue: 0.64).opacity(0.98),
                surfaceBottom: Color(red: 0.95, green: 0.62, blue: 0.3).opacity(0.95)
            )
        case .l2:
            return LiquidPalette(
                top: Color(red: 1.0, green: 0.76, blue: 0.42).opacity(0.95),
                mid: Color(red: 0.96, green: 0.55, blue: 0.22).opacity(0.96),
                bottom: Color(red: 0.82, green: 0.38, blue: 0.18).opacity(0.98),
                surfaceTop: Color(red: 1.0, green: 0.8, blue: 0.46).opacity(0.98),
                surfaceBottom: Color(red: 0.94, green: 0.52, blue: 0.22).opacity(0.95)
            )
        case .l3:
            return LiquidPalette(
                top: Color(red: 0.98, green: 0.66, blue: 0.32).opacity(0.95),
                mid: Color(red: 0.9, green: 0.44, blue: 0.18).opacity(0.96),
                bottom: Color(red: 0.72, green: 0.26, blue: 0.14).opacity(0.98),
                surfaceTop: Color(red: 0.98, green: 0.7, blue: 0.34).opacity(0.98),
                surfaceBottom: Color(red: 0.86, green: 0.4, blue: 0.18).opacity(0.95)
            )
        case .l4, .l5:
            return LiquidPalette(
                top: Color(red: 0.98, green: 0.4, blue: 0.32).opacity(0.95),
                mid: Color(red: 0.9, green: 0.22, blue: 0.18).opacity(0.96),
                bottom: Color(red: 0.7, green: 0.12, blue: 0.12).opacity(0.98),
                surfaceTop: Color(red: 1.0, green: 0.46, blue: 0.36).opacity(0.98),
                surfaceBottom: Color(red: 0.86, green: 0.2, blue: 0.18).opacity(0.95)
            )
        }
    }

    func message(dailyLimit: Int, multipliers: ThresholdMultipliers) -> LevelMessage? {
        let bounds = SugarLevel.bounds(for: dailyLimit, multipliers: multipliers)
        switch self {
        case .l1:
            return nil
        case .l2:
            return LevelMessage(
                title: "Level 2 - Caution",
                body: "Moderate Zone (\(bounds.l1Max)-\(bounds.l2Max)g). Over your target max (\(bounds.l1Max)g/day)!"
            )
        case .l3:
            return LevelMessage(
                title: "Level 3 - Warning",
                body: "High Zone (\(bounds.l2Max)-\(bounds.l3Max)g)! Be careful!"
            )
        case .l4:
            return LevelMessage(
                title: "Level 4 - High",
                body: "Excess Zone (\(bounds.l3Max)-\(bounds.l4Max)g)! Getting dangerous!"
            )
        case .l5:
            return LevelMessage(
                title: "Level 5 - OMG",
                body: "Over \(bounds.l4Max)g/day! Oh no!"
            )
        }
    }

    private struct LevelBounds {
        let l1Max: Int
        let l2Max: Int
        let l3Max: Int
        let l4Max: Int
    }

    private static func bounds(for dailyLimit: Int, multipliers: ThresholdMultipliers) -> LevelBounds {
        let limit = max(dailyLimit, 1)
        let normalized = multipliers.normalized()
        return LevelBounds(
            l1Max: grams(limit, normalized.l2),
            l2Max: grams(limit, normalized.l3),
            l3Max: grams(limit, normalized.l4),
            l4Max: grams(limit, normalized.l5)
        )
    }

    private static func grams(_ limit: Int, _ multiplier: Double) -> Int {
        Int((Double(limit) * multiplier).rounded())
    }
}
