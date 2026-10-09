import Foundation

/// Dip is the gate that opens a wet window. It does not increment Tally.
struct Dip: Equatable, Sendable {
    var dayKey: Int
    var openedAt: Date
    var windowSeconds: TimeInterval

    static let windowSeconds: TimeInterval = 8
}
