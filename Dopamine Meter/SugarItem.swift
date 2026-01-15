import Foundation

struct SugarItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let sugarGrams: Int
}
