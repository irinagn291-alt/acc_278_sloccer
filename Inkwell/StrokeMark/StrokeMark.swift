import Foundation

/// StrokeMark is one accepted stroke on a wet nib. Tally counts these.
struct StrokeMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var madeAt: Date
}
