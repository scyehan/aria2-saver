import Foundation

struct PathHistory: Codable {
    var paths: [String] = []

    static let maxCount = 6

    mutating func add(_ path: String) {
        paths.removeAll { $0 == path }
        paths.insert(path, at: 0)
        if paths.count > Self.maxCount {
            paths = Array(paths.prefix(Self.maxCount))
        }
    }

    func suggestions(prefix: String) -> [String] {
        guard !prefix.isEmpty else { return paths }
        return paths.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
    }
}
