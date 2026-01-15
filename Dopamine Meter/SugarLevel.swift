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

enum SugarLevel: Int, CaseIterable {
    case l1 = 1
    case l2 = 2
    case l3 = 3
    case l4 = 4
    case l5 = 5

    static func level(for grams: Int) -> SugarLevel {
        if grams <= 36 {
            return .l1
        } else if grams <= 72 {
            return .l2
        } else if grams <= 144 {
            return .l3
        } else if grams <= 180 {
            return .l4
        } else {
            return .l5
        }
    }

    static let zones: [SugarZone] = [
        SugarZone(name: "Healthy Zone", rangeLabel: "0-36g", lowerBound: 0, upperBound: 36, color: Color(red: 0.2, green: 0.7, blue: 0.3)),
        SugarZone(name: "Moderate Zone", rangeLabel: "36-72g", lowerBound: 36, upperBound: 72, color: Color(red: 0.95, green: 0.8, blue: 0.2)),
        SugarZone(name: "High Zone", rangeLabel: "72-144g", lowerBound: 72, upperBound: 144, color: Color(red: 0.95, green: 0.55, blue: 0.2)),
        SugarZone(name: "Excess", rangeLabel: ">144g", lowerBound: 144, upperBound: nil, color: Color(red: 0.9, green: 0.2, blue: 0.2))
    ]

    static let thresholds: [SugarThreshold] = [
        SugarThreshold(grams: 36, level: .l2, isDashed: false),
        SugarThreshold(grams: 72, level: .l3, isDashed: false),
        SugarThreshold(grams: 144, level: .l4, isDashed: false),
        SugarThreshold(grams: 180, level: .l5, isDashed: true)
    ]

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

    var message: LevelMessage? {
        switch self {
        case .l1:
            return nil
        case .l2:
            return LevelMessage(
                title: "Level 2 - Caution",
                body: "Moderate Zone (36-72g). Over the recommended max (36g/day)."
            )
        case .l3:
            return LevelMessage(
                title: "Level 3 - Warning",
                body: "High Zone (72-144g). Typical American range (~4x strict)."
            )
        case .l4:
            return LevelMessage(
                title: "Level 4 - High",
                body: "Excess Zone (>144g). You are above the lenient ceiling."
            )
        case .l5:
            return LevelMessage(
                title: "Level 5 - OMG",
                body: "Over 180g/day. Consider a reset tomorrow."
            )
        }
    }
}
