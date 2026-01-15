import Foundation

enum SugarStyle: String, CaseIterable, Identifiable {
    case balanced
    case strict
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .strict:
            return "Strict"
        case .custom:
            return "Custom"
        }
    }

    var detail: String {
        switch self {
        case .balanced:
            return "36g/day (AHA Adult Average)"
        case .strict:
            return "25g/day (AHA Low Sugar)"
        case .custom:
            return "User types a number"
        }
    }

    var defaultLimit: Int? {
        switch self {
        case .balanced:
            return 36
        case .strict:
            return 25
        case .custom:
            return nil
        }
    }
}

final class OnboardingViewModel: ObservableObject {
    @Published var selectedStyle: SugarStyle = .balanced
    @Published var customGramsText: String = ""

    var resolvedLimit: Int? {
        switch selectedStyle {
        case .balanced, .strict:
            return selectedStyle.defaultLimit
        case .custom:
            let trimmed = customGramsText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Int(trimmed), value > 0 else { return nil }
            return value
        }
    }

    var canContinue: Bool {
        if selectedStyle == .custom {
            return resolvedLimit != nil
        }
        return true
    }
}
