import Foundation

/// BleedMark is a stroke made on a dry nib. Tally does not move.
struct BleedMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var madeAt: Date
}
