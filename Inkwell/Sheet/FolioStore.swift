import Foundation

/// Seam between the sheet fold and storage. Views never touch UserDefaults
/// or the folio file. The in-memory folio is the source of truth; a failed
/// write rolls memory back to the last durable snapshot.
actor FolioStore {
    static let storageKey = "ink.folio.v1"
    static let backupKey = "ink.folio.v1.backup"
    static let demoKey = "ink.demo.v1"
    static let debounceNanoseconds: UInt64 = 400_000_000

    private let defaults: UserDefaults
    private let suiteName: String?
    private let directory: URL
    private var folio: Folio
    private var durable: Folio
    private var notice: String?
    private var generation = 0
    private var saveTask: Task<Void, Never>?

    init(defaults: UserDefaults, directory: URL, suiteName: String? = nil) {
        self.defaults = defaults
        self.suiteName = suiteName
        self.directory = directory
        self.folio = .empty
        self.durable = .empty
    }

    static func testingStore(suite: String, directory: URL) -> FolioStore? {
        guard let defaults = UserDefaults(suiteName: suite) else {
            return nil
        }
        defaults.removePersistentDomain(forName: suite)
        return FolioStore(defaults: defaults, directory: directory, suiteName: suite)
    }

    func testingOverwritePrimary(_ data: Data) {
        defaults.set(data, forKey: Self.storageKey)
    }

    func testingOverwriteBackup(_ data: Data) {
        defaults.set(data, forKey: Self.backupKey)
    }

    func testingWipe() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    func load(now: Date = Date(), calendar: Calendar = .current, installSeed: Bool = true) -> LoadedFolio {
        let loaded = readSnapshot()
        folio = loaded.folio
        durable = loaded.folio
        notice = loaded.notice
        #if targetEnvironment(simulator)
        if installSeed {
            installDemoSeedIfNeeded(now: now, calendar: calendar)
        }
        #endif
        return LoadedFolio(folio: folio, notice: notice)
    }

    func snapshot() -> Folio {
        folio
    }

    func userNotice() -> String? {
        notice
    }

    func strokeTheSheet(now: Date, calendar: Calendar = .current) -> FoldResult {
        mutate(immediate: false) { draft in
            SheetFold.strokeTheSheet(&draft, now: now, calendar: calendar)
        }
    }

    func dipTheNib(now: Date, calendar: Calendar = .current) -> FoldResult {
        mutate(immediate: false) { draft in
            SheetFold.dipTheNib(&draft, now: now, calendar: calendar)
        }
    }

    func peelTheSheet(now: Date, calendar: Calendar = .current) -> FoldResult {
        mutate(immediate: true) { draft in
            SheetFold.peelTheSheet(&draft, now: now, calendar: calendar)
        }
    }

    func setCapacity(strokes: Int, now: Date, calendar: Calendar = .current) -> FoldResult {
        mutate(immediate: false) { draft in
            SheetFold.setCapacity(&draft, strokes: strokes, now: now, calendar: calendar)
        }
    }

    func flush() {
        generation += 1
        saveTask?.cancel()
        saveTask = nil
        let saved = persist(folio)
        if saved {
            durable = folio
            notice = nil
        } else {
            folio = durable
            notice = "The sheet could not be saved. The last stored marks are still here."
        }
    }

    func finishOnboarding() {
        folio.onboardingComplete = true
        if folio.books.isUsable == false {
            folio.books = .standard
        }
        flush()
    }

    func reopenOnboarding() {
        folio.onboardingComplete = false
        flush()
    }

    func resetAllData() {
        generation += 1
        saveTask?.cancel()
        saveTask = nil
        folio = .empty
        let saved = persist(folio)
        if saved {
            durable = folio
            notice = nil
        } else {
            folio = durable
            notice = "The sheet could not be erased. The last stored marks are still here."
        }
    }

    private func mutate(immediate: Bool, body: (inout Folio) -> FoldResult) -> FoldResult {
        var draft = folio
        let result = body(&draft)
        guard result.accepted else {
            return result
        }
        folio = draft
        if immediate {
            flush()
            if folio != draft {
                return .refused(.saveFailed)
            }
        } else {
            scheduleSave()
        }
        return result
    }

    private func scheduleSave() {
        generation += 1
        let token = generation
        saveTask?.cancel()
        saveTask = Task { [token] in
            let slept = await Self.pauseForDebounce()
            guard slept else {
                return
            }
            guard token == self.generation else {
                return
            }
            let saved = self.persist(self.folio)
            guard token == self.generation else {
                return
            }
            if saved {
                self.durable = self.folio
            } else {
                self.folio = self.durable
                self.notice = "The sheet could not be saved. The last stored marks are still here."
            }
        }
    }

    private static func pauseForDebounce() async -> Bool {
        do {
            try await Task.sleep(nanoseconds: debounceNanoseconds)
            return true
        } catch {
            return false
        }
    }

    private func persist(_ snapshot: Folio) -> Bool {
        let data: Data
        do {
            data = try FolioCoding.encode(snapshot)
        } catch {
            return false
        }
        if let current = defaults.data(forKey: Self.storageKey), current.isEmpty == false {
            defaults.set(current, forKey: Self.backupKey)
        }
        do {
            try writeAtomically(data)
        } catch {
            return false
        }
        defaults.set(data, forKey: Self.storageKey)
        return true
    }

    private func writeAtomically(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        var folder = directory
        try folder.setResourceValues(values)
        let url = directory.appendingPathComponent("folio.json")
        if FileManager.default.fileExists(atPath: url.path) {
            let backup = directory.appendingPathComponent("folio.json.backup")
            if let existing = try? Data(contentsOf: url), existing.isEmpty == false {
                try existing.write(to: backup, options: .atomic)
            }
        }
        try data.write(to: url, options: .atomic)
    }

    private func readSnapshot() -> LoadedFolio {
        if let data = defaults.data(forKey: Self.storageKey), let folio = try? FolioCoding.decode(data) {
            return LoadedFolio(folio: folio, notice: nil)
        }
        if let data = defaults.data(forKey: Self.backupKey), let folio = try? FolioCoding.decode(data) {
            defaults.set(data, forKey: Self.storageKey)
            return LoadedFolio(
                folio: folio,
                notice: "The sheet file could not be read. Restored the last good folio."
            )
        }
        let primary = directory.appendingPathComponent("folio.json")
        if let data = try? Data(contentsOf: primary), let folio = try? FolioCoding.decode(data) {
            defaults.set(data, forKey: Self.storageKey)
            return LoadedFolio(folio: folio, notice: nil)
        }
        let backup = directory.appendingPathComponent("folio.json.backup")
        if let data = try? Data(contentsOf: backup), let folio = try? FolioCoding.decode(data) {
            defaults.set(data, forKey: Self.storageKey)
            return LoadedFolio(
                folio: folio,
                notice: "The sheet file could not be read. Restored the last good folio."
            )
        }
        if defaults.data(forKey: Self.storageKey) != nil || fileExists(primary) {
            return LoadedFolio(
                folio: .empty,
                notice: "The sheet file could not be read. Started from an empty folio."
            )
        }
        return LoadedFolio(folio: .empty, notice: nil)
    }

    private func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    #if targetEnvironment(simulator)
    private func installDemoSeedIfNeeded(now: Date, calendar: Calendar) {
        if defaults.bool(forKey: Self.demoKey) {
            return
        }
        folio = DemoSeed.make(now: now, calendar: calendar)
        if persist(folio) {
            durable = folio
            defaults.set(true, forKey: Self.demoKey)
        } else {
            folio = durable
            notice = "The sheet could not be prepared."
        }
    }
    #endif
}

struct LoadedFolio: Equatable, Sendable {
    var folio: Folio
    var notice: String?
}

#if targetEnvironment(simulator)
enum DemoSeed {
    static func make(now: Date, calendar: Calendar = .current) -> Folio {
        var folio = Folio.empty
        folio.onboardingComplete = true
        folio.books = .standard
        let capacity = folio.books.strokes
        let today = calendar.startOfDay(for: now)
        for offset in [4, 3, 2, 1] {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                continue
            }
            let stamped = calendar.date(byAdding: .hour, value: 9, to: day) ?? day
            if offset == 2 {
                _ = SheetFold.dipTheNib(&folio, now: stamped, calendar: calendar)
                for index in 0..<3 {
                    let strokeTime = stamped.addingTimeInterval(Double(index))
                    _ = SheetFold.strokeTheSheet(&folio, now: strokeTime, calendar: calendar)
                }
                let dry = stamped.addingTimeInterval(30)
                _ = SheetFold.strokeTheSheet(&folio, now: dry, calendar: calendar)
            } else {
                _ = SheetFold.dipTheNib(&folio, now: stamped, calendar: calendar)
                for index in 0..<capacity {
                    let strokeTime = stamped.addingTimeInterval(Double(index))
                    _ = SheetFold.strokeTheSheet(&folio, now: strokeTime, calendar: calendar)
                }
            }
        }
        _ = SheetFold.dipTheNib(&folio, now: now, calendar: calendar)
        let shy = max(0, capacity - 1)
        for index in 0..<shy {
            let strokeTime = now.addingTimeInterval(Double(index) * 0.01)
            _ = SheetFold.strokeTheSheet(&folio, now: strokeTime, calendar: calendar)
        }
        return folio
    }
}
#endif
