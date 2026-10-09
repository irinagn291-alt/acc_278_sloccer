import Foundation

/// WetMark records one accepted Dip and the wet window it opened.
struct WetMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var openedAt: Date
    var windowSeconds: TimeInterval

    var expiresAt: Date {
        openedAt.addingTimeInterval(windowSeconds)
    }

    func contains(_ instant: Date) -> Bool {
        instant >= openedAt && instant < expiresAt
    }
}
