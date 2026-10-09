import SwiftUI

/// History lists StrokeMarks and BleedMarks in stroke order.
struct HistorySheet: View {
    var session: SheetSession
    var dismissSheet: () -> Void
    @State private var retrying = false

    private var rows: [Rhumb] {
        session.folio.rhumbs.filter { rhumb in
            switch rhumb {
            case .stroke, .bleed:
                return true
            case .wet, .fill:
                return false
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let notice = session.notice, rows.isEmpty {
                    statusPage(
                        title: "History could not be read.",
                        line: notice,
                        action: "Try again",
                        retry: true
                    )
                } else if rows.isEmpty {
                    statusPage(
                        title: "No strokes on the sheet yet.",
                        line: "Dip, then stroke. Counted strokes and dry bleeds will list here in order.",
                        action: "Back to the sheet"
                    )
                } else {
                    List(rows) { rhumb in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: InkMeasure.steps(1)) {
                                Text(kind(rhumb))
                                    .font(InkType.body())
                                    .foregroundStyle(DesignTokens.ink)
                                Text(InkFormat.dayLabel(for: rhumb.dayKey))
                                    .font(InkType.caption())
                                    .foregroundStyle(DesignTokens.muted)
                            }
                            Spacer()
                            Text(markWord(rhumb))
                                .font(InkType.micro())
                                .foregroundStyle(isStroke(rhumb) ? DesignTokens.accent : DesignTokens.ink)
                                .padding(.horizontal, InkMeasure.steps(2))
                                .padding(.vertical, InkMeasure.steps(1))
                                .background(InkMeasure.plate, in: InkMeasure.chipShape)
                        }
                        .frame(minHeight: InkMeasure.steps(11))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                DesignTokens.bg.ignoresSafeArea()
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismissSheet()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(DesignTokens.ink)
                            .frame(width: InkMeasure.steps(11), height: InkMeasure.steps(11))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ChromePressStyle())
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private func isStroke(_ rhumb: Rhumb) -> Bool {
        if case .stroke = rhumb { return true }
        return false
    }

    private func markWord(_ rhumb: Rhumb) -> String {
        isStroke(rhumb) ? "Counted" : "Miss"
    }

    private func kind(_ rhumb: Rhumb) -> String {
        switch rhumb {
        case .stroke: return "Stroke"
        case .bleed: return "Bleed"
        case .wet: return "Dip"
        case .fill: return "Fill"
        }
    }

    private func statusPage(title: String, line: String, action: String, retry: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            Image("ink_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: InkMeasure.steps(40))
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: InkMeasure.steps(4))
            Button(action) {
                if retry {
                    retryLoad()
                } else {
                    dismissSheet()
                }
            }
            .buttonStyle(StrokePressStyle(loading: retry && retrying))
            .disabled(retry && retrying)
            if retry {
                Button("Back to the sheet") { dismissSheet() }
                    .buttonStyle(StrokePressStyle(quiet: true))
            }
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func retryLoad() {
        retrying = true
        Task { @MainActor in
            await session.prepare()
            retrying = false
        }
    }
}

struct HistoryBoard: View {
    var session: SheetSession
    var dismissSheet: () -> Void

    var body: some View {
        HistorySheet(session: session, dismissSheet: dismissSheet)
    }
}
