import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #FFFFFF
    static let bg = Color(red: 1.000000, green: 1.000000, blue: 1.000000)
    static let bgHex = "#FFFFFF"
    /// #FFFFFF
    static let surface = Color(red: 1.000000, green: 1.000000, blue: 1.000000)
    static let surfaceHex = "#FFFFFF"
    /// #0D1117
    static let ink = Color(red: 0.050980, green: 0.066667, blue: 0.090196)
    static let inkHex = "#0D1117"
    /// #A38200
    static let accent = Color(red: 0.639216, green: 0.509804, blue: 0.000000)
    static let accentHex = "#A38200"
    /// #727478
    static let muted = Color(red: 0.447059, green: 0.454902, blue: 0.470588)
    static let mutedHex = "#727478"
    static let fontFamily = "Georgia"
}
