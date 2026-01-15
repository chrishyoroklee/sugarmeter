import Foundation

struct SugarItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sugarGrams: Int
    let imageName: String?
    let isCustom: Bool

    init(name: String, sugarGrams: Int, imageName: String? = nil, isCustom: Bool = false) {
        self.name = name
        self.sugarGrams = sugarGrams
        self.imageName = imageName
        self.isCustom = isCustom
    }

    var storageKey: String {
        name
    }
}

enum SugarItemSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        }
    }

    var shortLabel: String {
        switch self {
        case .small:
            return "S"
        case .medium:
            return "M"
        case .large:
            return "L"
        }
    }

    var multiplier: Double {
        switch self {
        case .small:
            return 0.75
        case .medium:
            return 1.0
        case .large:
            return 1.25
        }
    }
}
