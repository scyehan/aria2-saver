import Foundation

enum DownloadStatus: String, Codable {
    case active
    case waiting
    case paused
    case complete
    case error
    case removed

    var isFinished: Bool {
        self == .complete || self == .error || self == .removed
    }
}

struct DownloadItem: Identifiable, Codable {
    let id: String // gid
    let url: String
    let backendId: String
    var filename: String
    var filePath: String // full path on the server, e.g. /data/downloads/file.zip
    var status: DownloadStatus
    var totalLength: Int64
    var completedLength: Int64
    var downloadSpeed: Int64
    var addedAt: Date
    var finishedAt: Date?

    var progress: Double {
        guard totalLength > 0 else { return 0 }
        return Double(completedLength) / Double(totalLength)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    var progressText: String {
        if totalLength > 0 {
            return "\(Self.formatBytes(completedLength)) / \(Self.formatBytes(totalLength))"
        }
        return Self.formatBytes(completedLength)
    }

    var speedText: String {
        guard downloadSpeed > 0 else { return "" }
        return "\(Self.formatBytes(downloadSpeed))/s"
    }
}
