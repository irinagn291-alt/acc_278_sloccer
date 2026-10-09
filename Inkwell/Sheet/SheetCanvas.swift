import SwiftUI
import UIKit

/// The practice sheet renders the fold. Dip, Stroke, and Peel stay here.
/// Calendar, Charts, History, and Settings arrive as sheets. The canvas never leaves.
struct PracticeRoot: View {
    var session: SheetSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cover: PracticeCover?
    @State private var didReadLaunch = false
    @State private var revealStep = 0
    @State private var strokeBusy = false
    @State private var strokeSpinner = false
    @State private var dipBusy = false
    @State private var dipSpinner = false
    @State private var peelBusy = false
    @State private var peelSpinner = false
    @State private var confirmPeel = false
    @State private var outcome: String?
    @State private var holdPlaceholder = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            sheet(now: context.date)
        }
        .background {
            DesignTokens.bg.ignoresSafeArea()
        }
        .sheet(item: $cover) { item in
            coverView(item)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: session.ready) { _, ready in
            if ready {
                attemptLaunch()
                reveal()
            }
        }
        .onChange(of: session.folio.onboardingComplete) { _, complete in
            if complete {
                attemptLaunch()
            }
        }
        .onAppear {
            watchPlaceholder()
            if session.ready {
                attemptLaunch()
                reveal()
            }
        }
        .confirmationDialog(
            "Peel the last stroke?",
            isPresented: $confirmPeel,
            titleVisibility: .visible
        ) {
            Button("Peel the stroke", role: .destructive) {
                peel()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The last counted stroke leaves the sheet and today's count drops by one.")
        }
    }

    @ViewBuilder
    private func sheet(now: Date) -> some View {
        if session.ready == false {
            if holdPlaceholder {
                homePlaceholder
            } else {
                DesignTokens.bg
            }
        } else if session.folio.onboardingComplete == false {
            PracticeOnboarding(session: session) {
                attemptLaunch()
            }
        } else {
            practiced(now: now)
        }
    }

    private func practiced(now: Date) -> some View {
        let key = SheetFold.dayKey(for: now)
        let folio = session.folio
        let tally = SheetFold.tally(in: folio, dayKey: key)
        let nib = SheetFold.nib(in: folio, dayKey: key, now: now)
        let reading = SheetFold.reading(in: folio, dayKey: key)
        return GeometryReader { proxy in
            let canvasHeight = max(InkMeasure.steps(48), proxy.size.height - InkMeasure.steps(64))
            ScrollView {
                VStack(alignment: .leading, spacing: InkMeasure.steps(3)) {
                    masthead
                        .opacity(show(1) ? 1 : 0)
                    if let notice = session.notice {
                        NoticePlate(text: notice)
                    }
                    if let outcome {
                        NoticePlate(text: outcome)
                    }
                    if reading == .blank {
                        BlankSheet(dipping: dipSpinner, enabled: dipBusy == false) {
                            dip()
                        }
                        .frame(minHeight: max(canvasHeight, proxy.size.height - InkMeasure.steps(28)))
                    } else {
                        InkTray(
                            nib: nib,
                            now: now,
                            folio: folio,
                            dayKey: key,
                            dipping: dipSpinner,
                            dipEnabled: dipBusy == false && nib == .dry
                        ) {
                            dip()
                        }
                        .opacity(show(2) ? 1 : 0)
                        CapacityRail(tally: tally)
                            .opacity(show(3) ? 1 : 0)
                        ManuscriptCanvas(folio: folio, dayKey: key, tally: tally)
                            .frame(height: canvasHeight)
                            .opacity(show(4) ? 1 : 0)
                        MarkStrip(folio: folio)
                            .opacity(show(5) ? 1 : 0)
                    }
                }
                .padding(.horizontal, InkMeasure.steps(4))
                .padding(.top, InkMeasure.steps(3))
                .padding(.bottom, InkMeasure.steps(3))
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: InkMeasure.steps(2)) {
            if reading == .blank {
                EmptyView()
            } else {
                strokeRow(nib: nib, tally: tally)
                    .padding(.horizontal, InkMeasure.steps(4))
                    .padding(.bottom, InkMeasure.steps(2))
                    .background {
                        DesignTokens.bg.ignoresSafeArea(edges: .bottom)
                    }
            }
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(2)) {
            Text("Today's sheet")
                .font(InkType.headline())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            chrome
        }
    }

    private var chrome: some View {
        HStack(spacing: InkMeasure.steps(1)) {
            coverButton("Calendar", system: "calendar", cover: .calendar)
            coverButton("Charts", system: "chart.bar", cover: .charts)
            coverButton("History", system: "list.bullet", cover: .history)
            coverButton("Settings", system: "gearshape", cover: .settings)
        }
        .padding(InkMeasure.steps(1))
        .background(InkMeasure.tray, in: InkMeasure.cardShape)
        .overlay {
            InkMeasure.cardShape.strokeBorder(DesignTokens.ink.opacity(0.18), lineWidth: InkMeasure.hairline)
        }
    }

    private func coverButton(_ title: String, system: String, cover: PracticeCover) -> some View {
        Button {
            self.cover = cover
        } label: {
            VStack(spacing: InkMeasure.steps(1)) {
                Image(systemName: system)
                    .font(InkType.caption())
                Text(title)
                    .font(InkType.micro())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: InkMeasure.steps(11))
            .contentShape(Rectangle())
        }
        .buttonStyle(ChromePressStyle())
        .accessibilityLabel(title)
    }

    private func strokeRow(nib: NibFold, tally: Tally) -> some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(2)) {
            Text(prompt(nib: nib, tally: tally))
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Stroke the sheet") {
                stroke()
            }
            .buttonStyle(
                StrokePressStyle(
                    loading: strokeSpinner,
                    quiet: nib != .wet,
                    enabled: strokeBusy == false && nib != .filled
                )
            )
            .disabled(strokeBusy || nib == .filled)
            .accessibilityHint(strokeHint(nib))
            Button("Peel") {
                confirmPeel = true
            }
            .buttonStyle(
                StrokePressStyle(
                    loading: peelSpinner,
                    destructive: true,
                    enabled: peelBusy == false && tally.strokes > 0
                )
            )
            .disabled(peelBusy || tally.strokes == 0)
            .accessibilityLabel("Peel the last stroke")
        }
    }

    private func prompt(nib: NibFold, tally: Tally) -> String {
        let remain = InkFormat.integer(tally.remaining)
        switch nib {
        case .wet:
            return "The nib is wet. Stroke the sheet. \(remain) strokes remain."
        case .dry:
            return "The nib is dry. Dip before you stroke, or a dry stroke is a bleed and does not count."
        case .filled:
            return "Today's sheet is filled. Peel if you need the last stroke back."
        }
    }

    private func strokeHint(_ nib: NibFold) -> String {
        switch nib {
        case .wet:
            return "Writes a counted stroke"
        case .dry:
            return "Writes a bleed and leaves the tally"
        case .filled:
            return "The sheet is already filled"
        }
    }

    private var homePlaceholder: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(3)) {
            RoundedRectangle(cornerRadius: InkMeasure.cardRadius, style: .continuous)
                .fill(DesignTokens.muted.opacity(0.2))
                .frame(height: InkMeasure.steps(16))
            RoundedRectangle(cornerRadius: InkMeasure.cardRadius, style: .continuous)
                .fill(DesignTokens.muted.opacity(0.15))
                .frame(height: InkMeasure.steps(20))
            RoundedRectangle(cornerRadius: InkMeasure.cardRadius, style: .continuous)
                .fill(DesignTokens.muted.opacity(0.12))
                .frame(maxHeight: .infinity)
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .accessibilityLabel("Loading today's sheet")
    }

    private func show(_ step: Int) -> Bool {
        reduceMotion || revealStep >= step
    }

    private func reveal() {
        if reduceMotion {
            revealStep = 5
            return
        }
        revealStep = 0
        for step in 1...5 {
            let delay = UInt64(step) * 50_000_000
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                withAnimation(reduceMotion ? .easeOut(duration: 0.25) : SheetMotion.ease) {
                    revealStep = max(revealStep, step)
                }
            }
        }
    }

    private func watchPlaceholder() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if session.ready == false {
                holdPlaceholder = true
            }
        }
    }

    private func attemptLaunch() {
        guard didReadLaunch == false else { return }
        guard session.ready, session.folio.onboardingComplete else { return }
        didReadLaunch = true
        let next: PracticeCover?
        switch ReviewLaunch.screen {
        case "log":
            next = .history
        case "goals":
            next = .settings
        case "calendar":
            next = .calendar
        case "charts":
            next = .charts
        default:
            next = nil
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cover = next
        }
    }

    @ViewBuilder
    private func coverView(_ item: PracticeCover) -> some View {
        switch item {
        case .calendar:
            CalendarBoard(session: session)
        case .charts:
            ChartsBoard(session: session)
        case .history:
            HistoryBoard(session: session) { cover = nil }
        case .settings:
            SettingsSheet(session: session) { cover = nil }
        }
    }

    private func stroke() {
        strokeBusy = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if strokeBusy {
                strokeSpinner = true
            }
        }
        Task { @MainActor in
            let result = await session.strokeTheSheet()
            strokeBusy = false
            strokeSpinner = false
            if result.wrote.contains(.stroke) {
                outcome = nil
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else if result.wrote.contains(.bleed) {
                outcome = "That stroke was dry, so it is a bleed. Today's count stayed put."
            }
        }
    }

    private func dip() {
        dipBusy = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if dipBusy {
                dipSpinner = true
            }
        }
        Task { @MainActor in
            let result = await session.dipTheNib()
            dipBusy = false
            dipSpinner = false
            if result.accepted {
                outcome = nil
            }
        }
    }

    private func peel() {
        peelBusy = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            if peelBusy {
                peelSpinner = true
            }
        }
        Task { @MainActor in
            let result = await session.peelTheSheet()
            peelBusy = false
            peelSpinner = false
            if result.accepted {
                outcome = "The last counted stroke is off the sheet."
            }
        }
    }
}

enum PracticeCover: String, Identifiable {
    case calendar
    case charts
    case history
    case settings

    var id: String { rawValue }
}

/// Tray of the nib. Words name Dry, Wet, or Filled. Dip lives here.
struct InkTray: View {
    var nib: NibFold
    var now: Date
    var folio: Folio
    var dayKey: Int
    var dipping: Bool
    var dipEnabled: Bool
    var dip: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: InkMeasure.steps(3)) {
            VStack(alignment: .leading, spacing: InkMeasure.steps(1)) {
                Text(nibWord)
                    .font(InkType.title())
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                nibDetail
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Dip") {
                dip()
            }
            .buttonStyle(
                StrokePressStyle(
                    loading: dipping,
                    quiet: nib != .dry,
                    enabled: dipEnabled && dipping == false
                )
            )
            .disabled(dipping || dipEnabled == false)
            .frame(maxWidth: InkMeasure.steps(28))
            .accessibilityLabel("Dip the nib")
        }
        .padding(InkMeasure.steps(3))
        .background(InkMeasure.tray, in: InkMeasure.cardShape)
        .overlay {
            InkMeasure.cardShape.strokeBorder(DesignTokens.ink.opacity(0.18), lineWidth: InkMeasure.hairline)
        }
    }

    private var nibWord: String {
        switch nib {
        case .dry: return "Dry"
        case .wet: return "Wet"
        case .filled: return "Filled"
        }
    }

    @ViewBuilder
    private var nibDetail: some View {
        switch nib {
        case .wet:
            WetNib(seconds: remainingSeconds)
        case .dry:
            DryNib()
        case .filled:
            FilledNib()
        }
    }

    private var remainingSeconds: Int {
        let open = folio.rhumbs.reversed().compactMap { rhumb -> WetMark? in
            if case .wet(let mark) = rhumb, mark.dayKey == dayKey, mark.contains(now) {
                return mark
            }
            return nil
        }.first
        guard let open else { return 0 }
        return max(0, Int(open.expiresAt.timeIntervalSince(now).rounded(.up)))
    }
}

struct DryNib: View {
    var body: some View {
        Text(line)
            .font(InkType.caption())
            .foregroundStyle(DesignTokens.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var line: String { "Dip to open the wet window" }
}

struct WetNib: View {
    var seconds: Int

    var body: some View {
        Text(line)
            .font(InkType.wetCount())
            .foregroundStyle(DesignTokens.accent)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(spoken)
    }

    private var line: String {
        let count = InkFormat.integer(seconds)
        return "\(count) seconds of wet ink"
    }

    private var spoken: String {
        let count = InkFormat.integer(seconds)
        return "\(count) seconds of wet ink remain"
    }
}

struct FilledNib: View {
    var body: some View {
        Text(line)
            .font(InkType.caption())
            .foregroundStyle(DesignTokens.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var line: String { "Dip is closed on a filled sheet" }
}

/// Capacity rail. One figure, not a second tray.
struct CapacityRail: View {
    var tally: Tally

    var body: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(2)) {
            Text(figure)
                .font(InkType.display())
                .foregroundStyle(DesignTokens.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Strokes on this sheet, against the capacity you set")
                .font(InkType.caption())
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    InkMeasure.chipShape.fill(DesignTokens.muted.opacity(0.25))
                    InkMeasure.chipShape
                        .fill(DesignTokens.accent)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: InkMeasure.steps(2))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spoken)
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InkMeasure.plate, in: InkMeasure.cardShape)
        .overlay {
            InkMeasure.cardShape.strokeBorder(DesignTokens.accent.opacity(0.7), lineWidth: InkMeasure.hairline)
        }
    }

    private var figure: String {
        let done = InkFormat.integer(tally.strokes)
        let cap = InkFormat.integer(tally.capacity)
        return "\(done) of \(cap)"
    }

    private var spoken: String {
        let done = InkFormat.integer(tally.strokes)
        let cap = InkFormat.integer(tally.capacity)
        return "Strokes \(done) of \(cap)"
    }

    private var fraction: CGFloat {
        guard tally.capacity > 0 else { return 0 }
        return min(1, CGFloat(tally.strokes) / CGFloat(tally.capacity))
    }
}

/// Manuscript canvas. The only custom-drawn surface. Stroke lines already on a seeded page.
struct ManuscriptCanvas: View {
    var folio: Folio
    var dayKey: Int
    var tally: Tally

    var body: some View {
        Canvas { context, size in
            let margin = InkMeasure.steps(4)
            let border = Path(
                roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1),
                cornerRadius: InkMeasure.cardRadius
            )
            context.stroke(border, with: .color(DesignTokens.ink.opacity(0.35)), lineWidth: InkMeasure.hairline)
            let slots = max(tally.capacity, 1)
            let usable = size.height - margin * 2
            for index in 0..<min(tally.strokes, slots) {
                let y = margin + usable * (CGFloat(index) + 0.5) / CGFloat(slots)
                var stroke = Path()
                stroke.move(to: CGPoint(x: margin, y: y))
                stroke.addQuadCurve(
                    to: CGPoint(x: size.width - margin, y: y + InkMeasure.steps(1)),
                    control: CGPoint(x: size.width * 0.45, y: y - InkMeasure.steps(2))
                )
                context.stroke(stroke, with: .color(DesignTokens.ink), lineWidth: InkMeasure.steps(1) / 2)
            }
            let bleeds = folio.rhumbs.filter { rhumb in
                if case .bleed(let mark) = rhumb { return mark.dayKey == dayKey }
                return false
            }.count
            if bleeds > 0 {
                let mark = InkFormat.integer(bleeds)
                context.draw(
                    Text(mark).font(InkType.micro()).foregroundStyle(DesignTokens.muted),
                    at: CGPoint(x: size.width - margin, y: margin),
                    anchor: .topTrailing
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surface, in: InkMeasure.cardShape)
        .clipped()
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        let count = InkFormat.integer(tally.strokes)
        return "Sheet with \(count) strokes"
    }
}

struct MarkStrip: View {
    var folio: Folio

    private struct Note: Identifiable {
        var id: UUID
        var title: String
        var day: String
    }

    var body: some View {
        if notes.isEmpty {
            EmptyView()
        } else {
            lines
        }
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(2)) {
            Text("Latest lines")
                .font(InkType.caption())
                .foregroundStyle(DesignTokens.muted)
            ForEach(notes) { note in
                HStack(alignment: .firstTextBaseline, spacing: InkMeasure.steps(2)) {
                    Text(note.title)
                        .font(InkType.body())
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: InkMeasure.steps(2))
                    Text(note.day)
                        .font(InkType.caption())
                        .foregroundStyle(DesignTokens.muted)
                        .lineLimit(1)
                }
                .frame(minHeight: InkMeasure.steps(11))
            }
        }
        .padding(InkMeasure.steps(3))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InkMeasure.plate, in: InkMeasure.cardShape)
        .overlay {
            InkMeasure.cardShape.strokeBorder(DesignTokens.ink.opacity(0.18), lineWidth: InkMeasure.hairline)
        }
    }

    private var notes: [Note] {
        folio.rhumbs.reversed().compactMap { rhumb -> Note? in
            switch rhumb {
            case .stroke:
                return Note(id: rhumb.id, title: "Counted stroke", day: InkFormat.dayLabel(for: rhumb.dayKey))
            case .bleed:
                return Note(id: rhumb.id, title: "Dry bleed", day: InkFormat.dayLabel(for: rhumb.dayKey))
            case .wet, .fill:
                return nil
            }
        }.prefix(4).map { $0 }
    }
}

struct BlankSheet: View {
    var dipping: Bool
    var enabled: Bool = true
    var dip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            Image("ink_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: InkMeasure.steps(40), maxHeight: InkMeasure.steps(40))
                .clipped()
                .accessibilityHidden(true)
            Text("The sheet is blank.")
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Dip the nib to open the wet window, then stroke today's lines.")
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: InkMeasure.steps(4))
            Button("Dip") {
                dip()
            }
            .buttonStyle(StrokePressStyle(loading: dipping, enabled: enabled && dipping == false))
            .disabled(dipping || enabled == false)
            .accessibilityLabel("Dip the nib")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct NoticePlate: View {
    var text: String

    var body: some View {
        Text(text)
            .font(InkType.caption())
            .foregroundStyle(DesignTokens.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(InkMeasure.steps(3))
            .background(InkMeasure.plate, in: InkMeasure.chipShape)
            .overlay {
                InkMeasure.chipShape.strokeBorder(DesignTokens.muted, lineWidth: InkMeasure.hairline)
            }
    }
}
