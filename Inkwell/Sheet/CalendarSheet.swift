import SwiftUI

/// Calendar sheet. Days are YYYYMMDD keys. Each day reads filled, partial, or blank in words.
struct CalendarSheet: View {
    var session: SheetSession
    @Environment(\.dismiss) private var dismiss
    @State private var month = Calendar.current.startOfDay(for: Date())
    @State private var retrying = false

    var body: some View {
        NavigationStack {
            Group {
                if session.notice != nil && session.folio.rhumbs.isEmpty {
                    errorPage
                } else if monthIsEmpty {
                    emptyPage
                } else {
                    populated
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                DesignTokens.bg.ignoresSafeArea()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeToolbar }
        }
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
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

    private var monthIsEmpty: Bool {
        days.allSatisfy { SheetFold.reading(in: session.folio, dayKey: $0.key) == .blank }
    }

    private var emptyPage: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(4)) {
            monthControls
            Image("ink_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: InkMeasure.steps(36))
                .clipped()
                .accessibilityHidden(true)
            Text("This month is still blank.")
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
            Text("Filled and partial days show up here after you stroke the sheet.")
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: InkMeasure.steps(4))
            Button("Back to the sheet") { dismiss() }
                .buttonStyle(StrokePressStyle())
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: InkMeasure.steps(3)) {
            Text("The calendar could not be read.")
                .font(InkType.title())
                .foregroundStyle(DesignTokens.ink)
            Text(noticeLine)
                .font(InkType.body())
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: InkMeasure.steps(4))
            Button("Try again") { retry() }
                .buttonStyle(StrokePressStyle(loading: retrying))
                .disabled(retrying)
        }
        .padding(InkMeasure.steps(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var populated: some View {
        List {
            Section {
                monthControls
                    .listRowBackground(DesignTokens.bg)
            }
            Section {
                ForEach(days, id: \.key) { day in
                    let reading = SheetFold.reading(in: session.folio, dayKey: day.key)
                    HStack {
                        Text(InkFormat.dayLabel(for: day.key))
                            .font(InkType.body())
                            .foregroundStyle(DesignTokens.ink)
                        Spacer()
                        Text(word(reading))
                            .font(InkType.caption())
                            .foregroundStyle(reading == .filled ? DesignTokens.accent : DesignTokens.muted)
                            .padding(.horizontal, InkMeasure.steps(2))
                            .padding(.vertical, InkMeasure.steps(1))
                            .background(InkMeasure.plate, in: InkMeasure.chipShape)
                    }
                    .frame(minHeight: InkMeasure.steps(11))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var noticeLine: String {
        session.notice ?? "The saved sheet could not be opened."
    }

    private func retry() {
        retrying = true
        Task { @MainActor in
            await session.prepare()
            retrying = false
        }
    }

    private var monthControls: some View {
        HStack {
            Button("Previous month") { shift(-1) }
                .font(InkType.caption())
                .buttonStyle(ChromePressStyle())
                .frame(minWidth: InkMeasure.steps(11), minHeight: InkMeasure.steps(11))
            Spacer()
            Text(monthTitle)
                .font(InkType.headline())
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1)
            Spacer()
            Button("Next month") { shift(1) }
                .font(InkType.caption())
                .buttonStyle(ChromePressStyle())
                .frame(minWidth: InkMeasure.steps(11), minHeight: InkMeasure.steps(11))
        }
    }

    private var monthTitle: String {
        InkFormat.month.string(from: month)
    }

    private var days: [(key: Int, date: Date)] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: start) ?? 1..<2
        return range.compactMap { day -> (Int, Date)? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: start) else { return nil }
            let edge = calendar.startOfDay(for: date)
            return (SheetFold.dayKey(for: edge, calendar: calendar), edge)
        }
    }

    private func word(_ reading: DayReading) -> String {
        switch reading {
        case .blank: return "Blank"
        case .partial: return "Partial"
        case .filled: return "Filled"
        }
    }

    private func shift(_ months: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: months, to: month) {
            month = Calendar.current.startOfDay(for: next)
        }
    }
}

struct CalendarBoard: View {
    var session: SheetSession

    var body: some View {
        CalendarSheet(session: session)
    }
}
