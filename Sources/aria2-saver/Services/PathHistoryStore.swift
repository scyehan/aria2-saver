import Foundation

@MainActor
final class PathHistoryStore {
    static let shared = PathHistoryStore()

    private let defaults = UserDefaults.standard
    private let keyPrefix = "pathHistory_"

    private init() {}

    func history(for backendId: String) -> PathHistory {
        let key = keyPrefix + backendId
        guard let data = defaults.data(forKey: key),
              let history = try? JSONDecoder().decode(PathHistory.self, from: data) else {
            return PathHistory()
        }
        return history
    }

    func addPath(_ path: String, for backendId: String) {
        var history = history(for: backendId)
        history.add(path)
        save(history, for: backendId)
    }

    func suggestions(for backendId: String, prefix: String) -> [String] {
        history(for: backendId).suggestions(prefix: prefix)
    }

    private func save(_ history: PathHistory, for backendId: String) {
        let key = keyPrefix + backendId
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: key)
        }
    }
}
