import SwiftUI

/// Charts sheet of stock rows: weekly stroke volume, fill streak, and bleed misses.
struct ChartsSheet: View {
    var session: SheetSession
    @Environment(\.dismiss) private var dismiss
    @State private var retrying = false

    var body: some View {
        NavigationStack {
            Group {
                if let notice = session.notice, session.folio.rhumbs.isEmpty {
                    messagePage(title: "Charts could not be read.", line: notice)
                } else if runs.isEmpty && bleedCount == 0 && streak == 0 {
                    messagePage(
                        title: "No weekly marks yet.",
                        line: "Stroke a wet sheet and the week will show volume, streak, and bleeds."
                    )
                } else {
                    List {
                        Section("Weekly stroke volume") {
                            if runs.isEmpty {
                                Text("This week has no counted strokes yet.")
                                    .font(InkType.body())
                            } else {
                                ForEach(runs, id: \.weekStartKey) { run in
                                    HStack {
                                        Text(InkFormat.dayLabel(for: run.weekStartKey))
                                            .font(InkType.body())
                                            .foregroundStyle(DesignTokens.ink)
                                        Spacer()
                                        Text(strokeCount(run.strokeCount))
                                            .font(InkType.headline())
                                            .foregroundStyle(DesignTokens.ink)
                                    }
                                    .frame(minHeight: InkMeasure.steps(11))
                                }
                            }
                        }
                        Section("Fill streak") {
                            LabeledContent("Filled days in a row") {
                                Text(streakLine)
                                    .font(InkType.headline())
                                    .foregroundStyle(DesignTokens.ink)
                            }
                        }
                        Section("Dry bleeds") {
                            LabeledContent("Dry strokes") {
                                Text(bleedLine)
                                    .font(InkType.headline())
                                    .foregroundStyle(DesignTokens.ink)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                DesignTokens.bg.ignoresSafeArea()
            }
            .navigationTitle("Charts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
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

    private var runs: [WeekRun] {
        session.folio.weeklyRuns()
    }

    private func strokeCount(_ value: Int) -> String {
        InkFormat.integer(value)
    }

    private var streakLine: String {
        InkFormat.integer(streak)
    }

    private var bleedLine: String {
        InkFormat.integer(bleedCount)
    }

    private var bleedCount: Int {
        session.folio.rhumbs.reduce(into: 0) { count, rhumb in
            if case .bleed = rhumb { count += 1 }
        }
    }

    private var streak: Int {
        let calendar = Calendar.current
        var cursor = calendar.startOfDay(for: Date())
        var total = 0
        let todayKey = SheetFold.dayKey(for: cursor, calendar: calendar)
        if SheetFold.reading(in: session.folio, dayKey: todayKey) != .filled {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = calendar.startOfDay(for: yesterday)
        }
        while SheetFold.reading(in: session.folio, dayKey: SheetFold.dayKey(for: cursor, calendar: calendar)) == .filled {
            total += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: previous)
            if total > 400 { break }
        }
        return total
    }

    private func retry() {
        retrying = true
        Task { @MainActor in
            await session.prepare()
            retrying = false
        }
    }

    private func messagePage(title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            Image("ink_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: InkMeasure.steps(36))
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
            Text(line)
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: InkMeasure.steps(4))
            if session.notice != nil && session.folio.rhumbs.isEmpty {
                Button("Try again") { retry() }
                    .buttonStyle(StrokePressStyle(loading: retrying))
                    .disabled(retrying)
            }
            Button("Back to the sheet") { dismiss() }
                .buttonStyle(StrokePressStyle(quiet: session.notice != nil && session.folio.rhumbs.isEmpty))
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct ChartsBoard: View {
    var session: SheetSession

    var body: some View {
        ChartsSheet(session: session)
    }
}
