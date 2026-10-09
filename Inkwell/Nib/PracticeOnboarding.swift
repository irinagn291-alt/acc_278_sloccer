import SwiftUI

/// Three pages that name the sheet, the dip-then-stroke gate, and a filled day.
/// Skip and Continue both write the standard capacity and the completion flag.
struct PracticeOnboarding: View {
    var session: SheetSession
    var onFinished: () -> Void

    @State private var page = 0
    @State private var saving = false

    private let pages: [(title: String, line: String, art: String)] = [
        (
            "A sheet with a quota",
            "Count today's calligraphy strokes against the capacity you set for the page.",
            "ink_Onboarding1"
        ),
        (
            "Dip, then stroke",
            "Dip opens eight seconds of wet ink. Stroke while it is wet and the tally moves. A dry stroke is a bleed and does not count.",
            "ink_Onboarding2"
        ),
        (
            "File the day",
            "When the tally meets the sheet capacity, the day files as filled. Peel can lift the last counted stroke.",
            "ink_Onboarding3"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            pageBody
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Button(page == pages.count - 1 ? "Continue" : "Next") {
                if page < pages.count - 1 {
                    page += 1
                } else {
                    commit()
                }
            }
            .buttonStyle(StrokePressStyle(loading: saving))
            .disabled(saving)
            Button("Skip") {
                commit()
            }
            .buttonStyle(StrokePressStyle(destructive: true))
            .disabled(saving)
        }
        .padding(InkMeasure.steps(5))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(DesignTokens.bg)
    }

    private var pageBody: some View {
        let item = pages[page]
        return VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            Image(item.art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: InkMeasure.steps(56))
                .clipped()
                .accessibilityHidden(true)
            Text(item.title)
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.line)
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(pageCountLine)
                .font(InkType.caption())
                .foregroundStyle(DesignTokens.muted)
        }
    }

    private var pageCountLine: String {
        let current = InkFormat.integer(page + 1)
        let total = InkFormat.integer(pages.count)
        return "Page \(current) of \(total)"
    }

    private func commit() {
        saving = true
        Task {
            await session.finishOnboarding()
            saving = false
            onFinished()
        }
    }
}
