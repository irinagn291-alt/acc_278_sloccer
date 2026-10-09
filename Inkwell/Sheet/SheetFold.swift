import Foundation

/// The practice sheet is an algebraic fold over the day's marks.
/// Dry, Wet, and Filled are the only nib cases. This type owns every
/// transition. Views render the fold; they do not apply it.
enum SheetFold {
    static let wetWindow: TimeInterval = Dip.windowSeconds

    static func dayKey(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func tally(in folio: Folio, dayKey: Int) -> Tally {
        let strokes = folio.rhumbs.reduce(into: 0) { count, rhumb in
            if case .stroke(let mark) = rhumb, mark.dayKey == dayKey {
                count += 1
            }
        }
        return Tally(strokes: strokes, capacity: folio.books.strokes)
    }

    static func nib(in folio: Folio, dayKey: Int, now: Date) -> NibFold {
        let tally = tally(in: folio, dayKey: dayKey)
        if tally.isFull, hasFill(in: folio, dayKey: dayKey) {
            return .filled
        }
        if openWet(in: folio, dayKey: dayKey, now: now) != nil {
            return .wet
        }
        return .dry
    }

    static func reading(in folio: Folio, dayKey: Int) -> DayReading {
        let dayMarks = folio.rhumbs.filter { $0.dayKey == dayKey }
        if dayMarks.isEmpty {
            return .blank
        }
        let tally = tally(in: folio, dayKey: dayKey)
        if tally.isFull, hasFill(in: folio, dayKey: dayKey) {
            return .filled
        }
        return .partial
    }

    static func dipTheNib(
        _ folio: inout Folio,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        let key = dayKey(for: now, calendar: calendar)
        switch nib(in: folio, dayKey: key, now: now) {
        case .filled:
            return .refused(.dipOnFilled)
        case .wet:
            return .refused(.dipWhileWet)
        case .dry:
            let mark = WetMark(
                id: UUID(),
                dayKey: key,
                openedAt: now,
                windowSeconds: wetWindow
            )
            folio.rhumbs.append(.wet(mark))
            return .accepted(wrote: [.wet])
        }
    }

    static func strokeTheSheet(
        _ folio: inout Folio,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        let key = dayKey(for: now, calendar: calendar)
        switch nib(in: folio, dayKey: key, now: now) {
        case .filled:
            return .refused(.strokeOnFilled)
        case .wet:
            let stroke = StrokeMark(id: UUID(), dayKey: key, madeAt: now)
            folio.rhumbs.append(.stroke(stroke))
            var wrote: [RhumbKind] = [.stroke]
            let tally = tally(in: folio, dayKey: key)
            if tally.isFull, hasFill(in: folio, dayKey: key) == false {
                let fill = FillMark(id: UUID(), dayKey: key, filedAt: now)
                folio.rhumbs.append(.fill(fill))
                wrote.append(.fill)
            }
            return .accepted(wrote: wrote)
        case .dry:
            let bleed = BleedMark(id: UUID(), dayKey: key, madeAt: now)
            folio.rhumbs.append(.bleed(bleed))
            return .accepted(wrote: [.bleed])
        }
    }

    /// Peel removes the last StrokeMark for today only.
    /// Earlier FillMarks stay. Today's FillMark clears when tally drops below capacity.
    /// A still-open wet window leaves the nib Wet again.
    static func peelTheSheet(
        _ folio: inout Folio,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        let key = dayKey(for: now, calendar: calendar)
        guard let index = folio.rhumbs.lastIndex(where: { rhumb in
            if case .stroke(let mark) = rhumb {
                return mark.dayKey == key
            }
            return false
        }) else {
            return .refused(.peelWithoutStroke)
        }
        folio.rhumbs.remove(at: index)
        let tally = tally(in: folio, dayKey: key)
        if tally.isFull == false {
            folio.rhumbs.removeAll { rhumb in
                if case .fill(let mark) = rhumb {
                    return mark.dayKey == key
                }
                return false
            }
        }
        return .accepted(wrote: [.peel])
    }

    static func setCapacity(_ folio: inout Folio, strokes: Int, now: Date, calendar: Calendar = .current) -> FoldResult {
        guard strokes >= 1 else {
            return .refused(.capacityOutOfRange)
        }
        folio.books = SheetCapacity(strokes: strokes)
        let key = dayKey(for: now, calendar: calendar)
        let tally = tally(in: folio, dayKey: key)
        if tally.isFull, hasFill(in: folio, dayKey: key) == false {
            folio.rhumbs.append(FillMark(id: UUID(), dayKey: key, filedAt: now).asRhumb)
            return .accepted(wrote: [.fill])
        }
        if tally.isFull == false {
            folio.rhumbs.removeAll { rhumb in
                if case .fill(let mark) = rhumb {
                    return mark.dayKey == key
                }
                return false
            }
        }
        return .accepted(wrote: [])
    }

    static func weeklyRuns(in folio: Folio, calendar: Calendar = .current) -> [WeekRun] {
        var buckets: [Int: WeekRun] = [:]
        for rhumb in folio.rhumbs {
            guard let date = date(from: rhumb.dayKey, calendar: calendar) else {
                continue
            }
            let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let key = dayKey(for: start, calendar: calendar)
            var run = buckets[key] ?? WeekRun(weekStartKey: key, strokeCount: 0, bleedCount: 0, fillCount: 0)
            switch rhumb {
            case .stroke:
                run.strokeCount += 1
            case .bleed:
                run.bleedCount += 1
            case .fill:
                run.fillCount += 1
            case .wet:
                break
            }
            buckets[key] = run
        }
        return buckets.values.sorted { $0.weekStartKey < $1.weekStartKey }
    }

    private static func hasFill(in folio: Folio, dayKey: Int) -> Bool {
        folio.rhumbs.contains { rhumb in
            if case .fill(let mark) = rhumb {
                return mark.dayKey == dayKey
            }
            return false
        }
    }

    private static func openWet(in folio: Folio, dayKey: Int, now: Date) -> WetMark? {
        folio.rhumbs.reversed().compactMap { rhumb -> WetMark? in
            if case .wet(let mark) = rhumb, mark.dayKey == dayKey {
                return mark
            }
            return nil
        }.first { $0.contains(now) }
    }

    private static func date(from key: Int, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let day = calendar.date(from: parts) else {
            return nil
        }
        return calendar.startOfDay(for: day)
    }
}

enum RhumbKind: String, Codable, Equatable, Sendable {
    case wet
    case stroke
    case bleed
    case fill
    case peel
}

enum SheetRefusal: String, Equatable, Sendable {
    case dipWhileWet
    case dipOnFilled
    case strokeOnFilled
    case peelWithoutStroke
    case capacityOutOfRange
    case saveFailed
}

struct FoldResult: Equatable, Sendable {
    var accepted: Bool
    var wrote: [RhumbKind]
    var refusal: SheetRefusal?

    static func accepted(wrote: [RhumbKind]) -> FoldResult {
        FoldResult(accepted: true, wrote: wrote, refusal: nil)
    }

    static func refused(_ refusal: SheetRefusal) -> FoldResult {
        FoldResult(accepted: false, wrote: [], refusal: refusal)
    }
}

/// Ordered mark. Identity is the mark id, never a list index.
enum Rhumb: Codable, Equatable, Sendable, Identifiable {
    case wet(WetMark)
    case stroke(StrokeMark)
    case bleed(BleedMark)
    case fill(FillMark)

    var id: UUID {
        switch self {
        case .wet(let mark):
            return mark.id
        case .stroke(let mark):
            return mark.id
        case .bleed(let mark):
            return mark.id
        case .fill(let mark):
            return mark.id
        }
    }

    var dayKey: Int {
        switch self {
        case .wet(let mark):
            return mark.dayKey
        case .stroke(let mark):
            return mark.dayKey
        case .bleed(let mark):
            return mark.dayKey
        case .fill(let mark):
            return mark.dayKey
        }
    }

    var kind: RhumbKind {
        switch self {
        case .wet:
            return .wet
        case .stroke:
            return .stroke
        case .bleed:
            return .bleed
        case .fill:
            return .fill
        }
    }
}

extension FillMark {
    var asRhumb: Rhumb { .fill(self) }
}
