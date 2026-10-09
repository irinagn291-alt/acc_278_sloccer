import SwiftUI

/// Primary Stroke control. Default, pressed, disabled, and loading.
/// Peel uses the destructive variant.
/// Shared press curve. Travel is a short ease-out. Reduce Motion keeps the fade and drops the scale.
enum SheetMotion {
    static let ease = Animation.easeOut(duration: 0.25)
}

struct StrokePressStyle: ButtonStyle {
    var loading: Bool = false
    var destructive: Bool = false
    var quiet: Bool = false
    var enabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let live = enabled && loading == false
        let outline = destructive || quiet
        configuration.label
            .font(outline ? InkType.headline() : InkType.title())
            .foregroundStyle(outline ? DesignTokens.ink : DesignTokens.bg)
            .frame(maxWidth: .infinity, minHeight: InkMeasure.steps(12))
            .padding(.horizontal, InkMeasure.steps(4))
            .background {
                InkMeasure.cardShape
                    .fill(fill(pressed: pressed, enabled: live, outline: outline))
            }
            .overlay {
                InkMeasure.cardShape
                    .strokeBorder(DesignTokens.ink.opacity(outline ? 0.85 : 0.2), lineWidth: InkMeasure.hairline)
            }
            .opacity(live ? (pressed && reduceMotion ? 0.72 : 1) : 0.45)
            .scaleEffect(pressed && live && reduceMotion == false ? 0.98 : 1)
            .animation(SheetMotion.ease, value: pressed)
            .contentShape(InkMeasure.cardShape)
            .overlay {
                if loading {
                    ProgressView()
                        .tint(outline ? DesignTokens.ink : DesignTokens.bg)
                }
            }
    }

    private func fill(pressed: Bool, enabled: Bool, outline: Bool) -> Color {
        if outline {
            return pressed ? DesignTokens.muted.opacity(0.35) : DesignTokens.surface
        }
        if enabled == false {
            return DesignTokens.muted
        }
        return pressed ? DesignTokens.ink : DesignTokens.accent
    }
}

struct ChromePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed && reduceMotion == false ? 0.97 : 1)
            .animation(SheetMotion.ease, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
