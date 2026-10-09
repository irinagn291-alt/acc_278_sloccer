import Foundation

/// FillMark files the day once Tally reaches SheetCapacity.
struct FillMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var filedAt: Date
}
