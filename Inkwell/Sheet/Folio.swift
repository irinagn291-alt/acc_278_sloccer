import Foundation

/// Capacity record. One integer: how many strokes file the sheet.
struct SheetCapacity: Codable, Equatable, Sendable {
    var strokes: Int

    static let standard = SheetCapacity(strokes: 8)

    var isUsable: Bool {
        strokes >= 1
    }
}

/// One calendar day projected from marks. Not an independent source of truth.
struct Island: Codable, Equatable, Sendable {
    var dayKey: Int
    var wet: [WetMark]
    var strokes: [StrokeMark]
    var bleeds: [BleedMark]
    var fills: [FillMark]
}

/// A wet window kept so Charts and the nib can read sessions without scanning ad hoc.
struct NibSession: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var openedAt: Date
    var windowSeconds: TimeInterval
}

/// Weekly stroke, bleed, and fill counts. Computed from marks at encode time.
struct WeekRun: Codable, Equatable, Sendable {
    var weekStartKey: Int
    var strokeCount: Int
    var bleedCount: Int
    var fillCount: Int
}

/// Chart root. Islands, books, sessions, runs, and rhumbs are one folio.
/// In memory, rhumbs plus books are the source of truth. Islands, sessions,
/// and runs are projections.
struct Folio: Codable, Equatable, Sendable {
    static let schema = 1

    var schemaVersion: Int
    var books: SheetCapacity
    var rhumbs: [Rhumb]
    var onboardingComplete: Bool

    init(schemaVersion: Int, books: SheetCapacity, rhumbs: [Rhumb], onboardingComplete: Bool) {
        self.schemaVersion = schemaVersion
        self.books = books
        self.rhumbs = rhumbs
        self.onboardingComplete = onboardingComplete
    }

    static let empty = Folio(
        schemaVersion: schema,
        books: .standard,
        rhumbs: [],
        onboardingComplete: false
    )

    var islands: [Int: Island] {
        var grouped: [Int: Island] = [:]
        for rhumb in rhumbs {
            var island = grouped[rhumb.dayKey] ?? Island(
                dayKey: rhumb.dayKey,
                wet: [],
                strokes: [],
                bleeds: [],
                fills: []
            )
            switch rhumb {
            case .wet(let mark):
                island.wet.append(mark)
            case .stroke(let mark):
                island.strokes.append(mark)
            case .bleed(let mark):
                island.bleeds.append(mark)
            case .fill(let mark):
                island.fills.append(mark)
            }
            grouped[rhumb.dayKey] = island
        }
        return grouped
    }

    var sessions: [NibSession] {
        rhumbs.compactMap { rhumb in
            guard case .wet(let mark) = rhumb else {
                return nil
            }
            return NibSession(
                id: mark.id,
                dayKey: mark.dayKey,
                openedAt: mark.openedAt,
                windowSeconds: mark.windowSeconds
            )
        }
    }

    func weeklyRuns(calendar: Calendar = .current) -> [WeekRun] {
        SheetFold.weeklyRuns(in: self, calendar: calendar)
    }
}

extension Folio {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case islands
        case books
        case sessions
        case runs
        case rhumbs
        case onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        guard version == Folio.schema else {
            throw FolioDecodeError.unsupportedSchema(version)
        }
        schemaVersion = version
        books = try container.decodeIfPresent(SheetCapacity.self, forKey: .books) ?? .standard
        onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        let decodedRhumbs = try container.decodeIfPresent([Rhumb].self, forKey: .rhumbs) ?? []
        if decodedRhumbs.isEmpty {
            let islands = try container.decodeIfPresent([String: Island].self, forKey: .islands) ?? [:]
            rhumbs = islands.values
                .sorted { $0.dayKey < $1.dayKey }
                .flatMap { island in
                    island.wet.map(Rhumb.wet)
                        + island.strokes.map(Rhumb.stroke)
                        + island.bleeds.map(Rhumb.bleed)
                        + island.fills.map(Rhumb.fill)
                }
        } else {
            rhumbs = decodedRhumbs
        }
        _ = try container.decodeIfPresent([NibSession].self, forKey: .sessions)
        _ = try container.decodeIfPresent([WeekRun].self, forKey: .runs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Folio.schema, forKey: .schemaVersion)
        try container.encode(books, forKey: .books)
        try container.encode(rhumbs, forKey: .rhumbs)
        try container.encode(onboardingComplete, forKey: .onboardingComplete)
        var islandObject: [String: Island] = [:]
        for (key, island) in islands {
            islandObject[String(key)] = island
        }
        try container.encode(islandObject, forKey: .islands)
        try container.encode(sessions, forKey: .sessions)
        try container.encode(weeklyRuns(), forKey: .runs)
    }
}

enum FolioDecodeError: Error, Equatable {
    case unsupportedSchema(Int)
    case malformed
}

enum FolioCoding {
    static func encode(_ folio: Folio) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(folio)
    }

    static func decode(_ data: Data) throws -> Folio {
        let probe: SchemaProbe
        do {
            probe = try JSONDecoder().decode(SchemaProbe.self, from: data)
        } catch {
            throw FolioDecodeError.malformed
        }
        switch probe.schemaVersion {
        case Folio.schema:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                return try decoder.decode(Folio.self, from: data)
            } catch let error as FolioDecodeError {
                throw error
            } catch {
                throw FolioDecodeError.malformed
            }
        default:
            throw FolioDecodeError.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
