import SwiftUI

/// Six Georgia steps. Bold is the tally and the Stroke label.
/// Italic is only the wet-window count.
enum InkType {
    static func display() -> Font {
        Font.custom(boldFace, size: 40, relativeTo: .largeTitle)
    }

    static func title() -> Font {
        Font.custom(boldFace, size: 28, relativeTo: .title)
    }

    static func headline() -> Font {
        Font.custom(face, size: 22, relativeTo: .title2)
    }

    static func body() -> Font {
        Font.custom(face, size: 17, relativeTo: .body)
    }

    static func caption() -> Font {
        Font.custom(face, size: 14, relativeTo: .footnote)
    }

    static func micro() -> Font {
        Font.custom(face, size: 12, relativeTo: .caption)
    }

    static func wetCount() -> Font {
        Font.custom(italicFace, size: 22, relativeTo: .title3)
    }

    private static var face: String { DesignTokens.fontFamily }
    private static var boldFace: String { "\(DesignTokens.fontFamily)-Bold" }
    private static var italicFace: String { "\(DesignTokens.fontFamily)-Italic" }
}

enum InkFormat {
    static let count: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let month: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    static func integer(_ value: Int) -> String {
        count.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func dayLabel(for key: Int) -> String {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let date = Calendar.current.date(from: parts) else {
            return integer(key)
        }
        return day.string(from: Calendar.current.startOfDay(for: date))
    }
}
