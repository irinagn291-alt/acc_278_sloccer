import Foundation

/// Nib fold. Dry, Wet, and Filled are the only live cases.
/// Blank is the reading of a day that has no marks yet, and the nib is dry.
enum NibFold: String, Codable, Equatable, Sendable {
    case dry
    case wet
    case filled
}

/// How a calendar day reads. Blank is written by the fold when the day has no marks.
enum DayReading: String, Equatable, Sendable {
    case blank
    case partial
    case filled
}
