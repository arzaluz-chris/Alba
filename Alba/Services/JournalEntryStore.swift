import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "JournalEntryStore")

final class JournalEntryStore {
    static let shared = JournalEntryStore()
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("alba_journal_entries.json")
        logger.info("📓 JournalEntryStore path: \(self.fileURL.path)")
    }

    func save(entry: JournalEntry) {
        var all = loadAll()
        all.insert(entry, at: 0)
        persist(all)
        logger.info("💾 Saved diary entry for \(entry.friendName). Total: \(all.count)")
    }

    func loadAll() -> [JournalEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([JournalEntry].self, from: data)
        } catch {
            logger.error("❌ Failed to load entries: \(error.localizedDescription)")
            return []
        }
    }

    func entries(for friendName: String) -> [JournalEntry] {
        loadAll().filter { $0.friendName.lowercased() == friendName.lowercased() }
    }

    func entries(for friendName: String, on date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return entries(for: friendName).filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func update(entry: JournalEntry) {
        var all = loadAll()
        guard let index = all.firstIndex(where: { $0.id == entry.id }) else { return }
        all[index] = entry
        persist(all)
        logger.info("✏️ Updated entry \(entry.id)")
    }

    func delete(entryId: UUID) {
        var all = loadAll()
        all.removeAll { $0.id == entryId }
        persist(all)
        logger.info("🗑️ Deleted entry \(entryId)")
    }

    func datesWithEntries(for friendName: String) -> Set<DateComponents> {
        let calendar = Calendar.current
        let friendEntries = entries(for: friendName)
        return Set(friendEntries.map { calendar.dateComponents([.year, .month, .day], from: $0.date) })
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("🗑️ All journal entries deleted")
    }

    private func persist(_ entries: [JournalEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL)
        } catch {
            logger.error("❌ Failed to persist entries: \(error.localizedDescription)")
        }
    }
}
