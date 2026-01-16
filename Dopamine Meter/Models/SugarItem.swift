import Foundation

enum SugarItemCategory: String, CaseIterable, Identifiable, Codable {
    case bakery
    case drink
    case candy
    case dessert
    case breakfast
    case condiment
    case snack
    case fastfood
    case kids
    case custom
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bakery:
            return "Bakery"
        case .drink:
            return "Drink"
        case .candy:
            return "Candy"
        case .dessert:
            return "Dessert"
        case .breakfast:
            return "Breakfast"
        case .condiment:
            return "Condiment"
        case .snack:
            return "Snack"
        case .fastfood:
            return "Fast Food"
        case .kids:
            return "Kids"
        case .custom:
            return "Custom"
        case .other:
            return "Other"
        }
    }
}

struct SugarItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sugarGrams: Int
    let imageName: String?
    let isCustom: Bool
    let category: SugarItemCategory

    init(
        name: String,
        sugarGrams: Int,
        imageName: String? = nil,
        isCustom: Bool = false,
        category: SugarItemCategory = .other
    ) {
        self.name = name
        self.sugarGrams = sugarGrams
        self.imageName = imageName
        self.isCustom = isCustom
        self.category = category
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
