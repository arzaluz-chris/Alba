import Foundation
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "FriendshipStore")

final class FriendshipStore {
    static let shared = FriendshipStore()
    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("alba_friendship_records.json")
        logger.info("📊 FriendshipStore path: \(self.fileURL.path)")
    }

    func save(record: FriendshipRecord) {
        var all = loadAll()
        all.insert(record, at: 0)
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL)
            logger.info("💾 Saved record for \(record.friendName). Total: \(all.count)")
        } catch {
            logger.error("❌ Failed to save: \(error.localizedDescription)")
        }
    }

    func loadAll() -> [FriendshipRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([FriendshipRecord].self, from: data)
        } catch {
            logger.error("❌ Failed to load: \(error.localizedDescription)")
            return []
        }
    }

    func recordsFor(friend: String) -> [FriendshipRecord] {
        loadAll().filter { $0.friendName.lowercased() == friend.lowercased() }
    }

    func uniqueFriends() -> [String] {
        let all = loadAll()
        var seen = Set<String>()
        var names: [String] = []
        for r in all {
            let key = r.friendName.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                names.append(r.friendName)
            }
        }
        return names
    }

    func latestRecord(for friend: String) -> FriendshipRecord? {
        recordsFor(friend: friend).first
    }

    func trend(for friend: String, category: String) -> Double? {
        let records = recordsFor(friend: friend)
        guard records.count >= 2 else { return nil }
        let latest = records[0].categoryScores[category] ?? 0
        let previous = records[1].categoryScores[category] ?? 0
        return latest - previous
    }

    func daysSinceLastTest(for friend: String) -> Int? {
        guard let latest = latestRecord(for: friend) else { return nil }
        return Calendar.current.dateComponents([.day], from: latest.date, to: Date()).day
    }

    func deleteFriend(name: String) {
        var all = loadAll()
        all.removeAll { $0.friendName.lowercased() == name.lowercased() }
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL)
            logger.info("🗑️ Deleted all records for \(name)")
        } catch {
            logger.error("❌ Failed to delete friend: \(error.localizedDescription)")
        }
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
        logger.info("🗑️ All records deleted")
    }
}
