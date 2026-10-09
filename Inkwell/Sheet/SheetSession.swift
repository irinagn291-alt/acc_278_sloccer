import Foundation
import Observation

/// Main-actor owner of the live folio. The store actor performs disk work.
/// This type does not touch UserDefaults.
@MainActor
@Observable
final class SheetSession {
    private let store: FolioStore
    private(set) var folio: Folio
    private(set) var notice: String?
    private(set) var ready = false

    init(store: FolioStore) {
        self.store = store
        self.folio = .empty
    }

    convenience init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Sloccer", isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("Sloccer", isDirectory: true)
        self.init(store: FolioStore(defaults: .standard, directory: directory))
    }

    func prepare(now: Date = Date()) async {
        let loaded = await store.load(now: now)
        folio = loaded.folio
        notice = loaded.notice
        ready = true
    }

    func strokeTheSheet(now: Date = Date()) async -> FoldResult {
        await commit(await store.strokeTheSheet(now: now))
    }

    func dipTheNib(now: Date = Date()) async -> FoldResult {
        await commit(await store.dipTheNib(now: now))
    }

    func peelTheSheet(now: Date = Date()) async -> FoldResult {
        await commit(await store.peelTheSheet(now: now))
    }

    func setCapacity(strokes: Int, now: Date = Date()) async -> FoldResult {
        await commit(await store.setCapacity(strokes: strokes, now: now))
    }

    func flush() async {
        await store.flush()
        folio = await store.snapshot()
        notice = await store.userNotice()
    }

    func finishOnboarding() async {
        await store.finishOnboarding()
        folio = await store.snapshot()
        notice = await store.userNotice()
    }

    func reopenOnboarding() async {
        await store.reopenOnboarding()
        folio = await store.snapshot()
        notice = await store.userNotice()
    }

    func resetAllData() async {
        await store.resetAllData()
        folio = await store.snapshot()
        notice = await store.userNotice()
    }

    private func commit(_ result: FoldResult) async -> FoldResult {
        folio = await store.snapshot()
        notice = await store.userNotice()
        return result
    }
}
