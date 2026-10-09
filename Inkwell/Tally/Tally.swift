import Foundation

/// Metric record for this sheet. Stroke count is derived from StrokeMarks
/// so a day total is never stored beside the marks that already imply it.
struct Tally: Equatable, Sendable {
    var strokes: Int
    var capacity: Int

    var remaining: Int {
        max(0, capacity - strokes)
    }

    var isFull: Bool {
        capacity > 0 && strokes >= capacity
    }
}
