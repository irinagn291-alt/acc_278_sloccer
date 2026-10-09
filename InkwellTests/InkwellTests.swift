import XCTest
@testable import Inkwell

final class InkwellTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        self.calendar = calendar
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertEqual(ReviewLaunch.screen(in: ["Inkwell", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Inkwell", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Inkwell", "-ReviewScreen", "goals"]), "goals")
        XCTAssertEqual(ReviewLaunch.screen(in: ["Inkwell", "-ReviewScreen", "calendar"]), "calendar")
        XCTAssertNil(ReviewLaunch.screen(in: ["Inkwell"]))
        XCTAssertNil(ReviewLaunch.screen(in: ["Inkwell", "-ReviewScreen"]))
    }

    func testFamilyInvariantOneStrokeMovesTallyTowardCapacity() {
        var folio = Folio.empty
        let now = date(2026, 9, 27, 15, 0)
        let key = SheetFold.dayKey(for: now, calendar: calendar)
        XCTAssertEqual(SheetFold.reading(in: folio, dayKey: key), .blank)
        XCTAssertEqual(SheetFold.tally(in: folio, dayKey: key).strokes, 0)

        let dipped = SheetFold.dipTheNib(&folio, now: now, calendar: calendar)
        XCTAssertTrue(dipped.accepted)
        let before = SheetFold.tally(in: folio, dayKey: key).strokes
        let stroked = SheetFold.strokeTheSheet(&folio, now: now, calendar: calendar)
        XCTAssertEqual(stroked.wrote, [.stroke])
        let tally = SheetFold.tally(in: folio, dayKey: key)
        XCTAssertEqual(tally.strokes, before + 1)
        XCTAssertLessThan(tally.strokes, tally.capacity)
        XCTAssertEqual(SheetFold.dayKey(for: calendar.startOfDay(for: now), calendar: calendar), key)
    }

    func testStrokePathsEmptyPopulatedAndRefused() {
        var folio = Folio.empty
        let now = date(2026, 9, 27, 15, 0)
        let key = SheetFold.dayKey(for: now, calendar: calendar)

        let dry = SheetFold.strokeTheSheet(&folio, now: now, calendar: calendar)
        XCTAssertEqual(dry.wrote, [.bleed])
        XCTAssertEqual(SheetFold.tally(in: folio, dayKey: key).strokes, 0)
        XCTAssertEqual(SheetFold.reading(in: folio, dayKey: key), .partial)

        var practiced = Folio.empty
        practiced.books = SheetCapacity(strokes: 1)
        XCTAssertTrue(SheetFold.dipTheNib(&practiced, now: now, calendar: calendar).accepted)
        let logged = SheetFold.strokeTheSheet(&practiced, now: now, calendar: calendar)
        XCTAssertEqual(logged.wrote, [.stroke, .fill])
        XCTAssertEqual(SheetFold.tally(in: practiced, dayKey: key).strokes, 1)
        let filed = SheetFold.strokeTheSheet(&practiced, now: now.addingTimeInterval(1), calendar: calendar)
        XCTAssertEqual(filed.refusal, .strokeOnFilled)
        XCTAssertEqual(SheetFold.tally(in: practiced, dayKey: key).strokes, 1)
    }

    func testDipThenStrokeTwistFillsAndPeels() {
        var folio = Folio.empty
        folio.books = SheetCapacity(strokes: 2)
        let now = date(2026, 9, 27, 15, 0)
        let key = SheetFold.dayKey(for: now, calendar: calendar)

        XCTAssertEqual(SheetFold.dipTheNib(&folio, now: now, calendar: calendar).wrote, [.wet])
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: now), .wet)
        XCTAssertEqual(SheetFold.dipTheNib(&folio, now: now.addingTimeInterval(1), calendar: calendar).refusal, .dipWhileWet)

        XCTAssertEqual(SheetFold.strokeTheSheet(&folio, now: now.addingTimeInterval(1), calendar: calendar).wrote, [.stroke])
        let dry = now.addingTimeInterval(SheetFold.wetWindow)
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: dry), .dry)
        let bleed = SheetFold.strokeTheSheet(&folio, now: dry, calendar: calendar)
        XCTAssertEqual(bleed.wrote, [.bleed])
        XCTAssertEqual(SheetFold.tally(in: folio, dayKey: key).strokes, 1)

        XCTAssertTrue(SheetFold.dipTheNib(&folio, now: dry, calendar: calendar).accepted)
        let filling = SheetFold.strokeTheSheet(&folio, now: dry.addingTimeInterval(1), calendar: calendar)
        XCTAssertEqual(filling.wrote, [.stroke, .fill])
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: dry.addingTimeInterval(1)), .filled)
        XCTAssertEqual(SheetFold.dipTheNib(&folio, now: dry.addingTimeInterval(2), calendar: calendar).refusal, .dipOnFilled)

        let earlier = date(2026, 9, 26, 15, 0)
        XCTAssertTrue(SheetFold.dipTheNib(&folio, now: earlier, calendar: calendar).accepted)
        XCTAssertTrue(SheetFold.strokeTheSheet(&folio, now: earlier, calendar: calendar).accepted)
        let earlierKey = SheetFold.dayKey(for: earlier, calendar: calendar)
        XCTAssertEqual(SheetFold.reading(in: folio, dayKey: earlierKey), .partial)

        let peeled = SheetFold.peelTheSheet(&folio, now: dry.addingTimeInterval(1), calendar: calendar)
        XCTAssertEqual(peeled.wrote, [.peel])
        XCTAssertEqual(SheetFold.tally(in: folio, dayKey: key).strokes, 1)
        XCTAssertFalse(folio.rhumbs.contains { $0.dayKey == key && $0.kind == .fill })
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: dry.addingTimeInterval(1)), .wet)
        XCTAssertEqual(SheetFold.tally(in: folio, dayKey: earlierKey).strokes, 1)
        XCTAssertEqual(SheetFold.peelTheSheet(&folio, now: date(2026, 9, 25, 15, 0), calendar: calendar).refusal, .peelWithoutStroke)
        XCTAssertEqual(SheetFold.setCapacity(&folio, strokes: 0, now: now, calendar: calendar).refusal, .capacityOutOfRange)
    }

    func testSheetFoldOwnsTransitions() {
        var folio = Folio.empty
        let now = date(2026, 9, 27, 15, 0)
        let key = SheetFold.dayKey(for: now, calendar: calendar)
        _ = SheetFold.dipTheNib(&folio, now: now, calendar: calendar)
        let count = folio.rhumbs.count
        XCTAssertEqual(SheetFold.dipTheNib(&folio, now: now, calendar: calendar).refusal, .dipWhileWet)
        XCTAssertEqual(folio.rhumbs.count, count)
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: now), .wet)
        XCTAssertEqual(SheetFold.reading(in: folio, dayKey: SheetFold.dayKey(for: date(2026, 1, 2, 8, 0), calendar: calendar)), .blank)
    }

    func testFolioRoundTripAndCorruptRecovery() async throws {
        let suite = "ink.test.\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite, isDirectory: true)
        let store = try XCTUnwrap(FolioStore.testingStore(suite: suite, directory: directory))
        let now = date(2026, 9, 27, 15, 0)
        _ = await store.load(now: now, calendar: calendar, installSeed: false)
        let dipped = await store.dipTheNib(now: now, calendar: calendar)
        XCTAssertTrue(dipped.accepted)
        await store.flush()
        let stroked = await store.strokeTheSheet(now: now, calendar: calendar)
        XCTAssertEqual(stroked.wrote, [.stroke])
        await store.flush()

        let reloaded = try XCTUnwrap(FolioStore.testingStore(suite: suite, directory: directory))
        let loaded = await reloaded.load(now: now, calendar: calendar, installSeed: false)
        let key = SheetFold.dayKey(for: now, calendar: calendar)
        XCTAssertEqual(SheetFold.tally(in: loaded.folio, dayKey: key).strokes, 1)
        XCTAssertNil(loaded.notice)

        let data = try FolioCoding.encode(loaded.folio)
        let decoded = try FolioCoding.decode(data)
        XCTAssertEqual(decoded, loaded.folio)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertFalse(decoded.islands.isEmpty)
        XCTAssertEqual(decoded.sessions.count, 1)

        await reloaded.testingOverwritePrimary(Data("not-json".utf8))
        let primary = directory.appendingPathComponent("folio.json")
        try Data("not-json".utf8).write(to: primary, options: .atomic)
        let recovered = await reloaded.load(now: now, calendar: calendar, installSeed: false)
        XCTAssertEqual(SheetFold.tally(in: recovered.folio, dayKey: key).strokes, 0)
        XCTAssertEqual(recovered.folio.rhumbs.count, 1)
        XCTAssertNotNil(recovered.notice)

        let emptySuite = "ink.test.\(UUID().uuidString)"
        let emptyDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(emptySuite, isDirectory: true)
        let emptied = try XCTUnwrap(FolioStore.testingStore(suite: emptySuite, directory: emptyDirectory))
        await emptied.testingOverwritePrimary(Data("still-bad".utf8))
        await emptied.testingOverwriteBackup(Data("{]".utf8))
        let blank = await emptied.load(now: now, calendar: calendar, installSeed: false)
        XCTAssertTrue(blank.folio.rhumbs.isEmpty)
        XCTAssertNotNil(blank.notice)

        await store.resetAllData()
        let afterReset = try XCTUnwrap(FolioStore.testingStore(suite: suite, directory: directory))
        let cleared = await afterReset.load(now: now, calendar: calendar, installSeed: false)
        XCTAssertTrue(cleared.folio.rhumbs.isEmpty)
        await store.testingWipe()
        await reloaded.testingWipe()
        await emptied.testingWipe()
        await afterReset.testingWipe()
    }

    func testDebouncedSaveKeepsLatestMarks() async throws {
        let suite = "ink.test.\(UUID().uuidString)"
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite, isDirectory: true)
        let store = try XCTUnwrap(FolioStore.testingStore(suite: suite, directory: directory))
        let now = date(2026, 9, 27, 15, 0)
        _ = await store.load(now: now, calendar: calendar, installSeed: false)
        _ = await store.dipTheNib(now: now, calendar: calendar)
        _ = await store.strokeTheSheet(now: now, calendar: calendar)
        _ = await store.strokeTheSheet(now: now.addingTimeInterval(1), calendar: calendar)
        await store.resetAllData()
        let reloaded = try XCTUnwrap(FolioStore.testingStore(suite: suite, directory: directory))
        let loaded = await reloaded.load(now: now, calendar: calendar, installSeed: false)
        XCTAssertTrue(loaded.folio.rhumbs.isEmpty)
        await store.testingWipe()
        await reloaded.testingWipe()
    }

    func testUnsupportedSchemaIsAnError() {
        let payload = Data("{\"schemaVersion\":9}".utf8)
        XCTAssertThrowsError(try FolioCoding.decode(payload)) { error in
            XCTAssertEqual(error as? FolioDecodeError, .unsupportedSchema(9))
        }
    }

#if targetEnvironment(simulator)
    func testSimulatorSeedLeavesWetSheetOneStrokeShort() {
        let now = date(2026, 9, 27, 15, 0)
        let folio = DemoSeed.make(now: now, calendar: calendar)
        let key = SheetFold.dayKey(for: now, calendar: calendar)
        let tally = SheetFold.tally(in: folio, dayKey: key)
        XCTAssertTrue(folio.onboardingComplete)
        XCTAssertEqual(tally.strokes, tally.capacity - 1)
        XCTAssertEqual(SheetFold.nib(in: folio, dayKey: key, now: now.addingTimeInterval(0.2)), .wet)
        XCTAssertGreaterThan(folio.islands.count, 2)
        let runs = folio.weeklyRuns(calendar: calendar)
        XCTAssertFalse(runs.isEmpty)
        XCTAssertGreaterThan(runs.reduce(0) { $0 + $1.strokeCount }, tally.strokes)
    }
#endif

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
