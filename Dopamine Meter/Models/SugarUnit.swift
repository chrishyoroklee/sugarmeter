import Foundation

enum SugarUnit: String, CaseIterable, Identifiable {
    case grams
    case ounces

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grams:
            return "g"
        case .ounces:
            return "oz"
        }
    }

    var title: String {
        switch self {
        case .grams:
            return "Grams"
        case .ounces:
            return "Ounces"
        }
    }

    func value(fromGrams grams: Int) -> Double {
        switch self {
        case .grams:
            return Double(grams)
        case .ounces:
            return Double(grams) / 28.3495
        }
    }

    func grams(from value: Double) -> Int {
        switch self {
        case .grams:
            return Int(value.rounded())
        case .ounces:
            return Int((value * 28.3495).rounded())
        }
    }

    func formattedValue(from grams: Int) -> String {
        switch self {
        case .grams:
            return "\(grams)"
        case .ounces:
            return formatOunces(value(fromGrams: grams))
        }
    }

    func formattedWithUnit(from grams: Int) -> String {
        "\(formattedValue(from: grams))\(label)"
    }

    private func formatOunces(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        if text.hasSuffix("00") {
            text.removeLast(3)
        } else if text.hasSuffix("0") {
            text.removeLast(1)
        }
        return text
    }
}
