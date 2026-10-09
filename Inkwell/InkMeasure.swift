import CoreGraphics
import SwiftUI

/// Spacing, radius, and elevation for the practice sheet.
/// Views reach layout only through this accessor. Base unit is 4pt.
enum InkMeasure {
    static let unit: CGFloat = 4
    static let hairline: CGFloat = 1

    static func steps(_ count: Int) -> CGFloat {
        unit * CGFloat(count)
    }

    /// Cards, sheets, and primary surfaces.
    static let cardRadius: CGFloat = 12
    /// Chips, badges, and small controls.
    static let chipRadius: CGFloat = 8

    static let cardShape = RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    static let chipShape = RoundedRectangle(cornerRadius: chipRadius, style: .continuous)

    static let plate = Material.regularMaterial
    static let tray = Material.thinMaterial
}
