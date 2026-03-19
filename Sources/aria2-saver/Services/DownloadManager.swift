import AppKit
import Foundation

@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [DownloadItem] = []
    @Published var historyDownloads: [DownloadItem] = []

    private let rpcClient = Aria2RPCClient()
    @Published var backendIds: [String] = []
    private var backends: [String: Aria2Backend] = [:]
    private var pollTask: Task<Void, Never>?
    private var removingGids: Set<String> = []

    private let defaults = UserDefaults.standard
    private let historyKey = "downloadHistory"
    private static let maxHistory = 50

    private init() {
        loadHistory()
    }

    var hasActiveDownloads: Bool { !activeDownloads.isEmpty }

    var overallProgress: Double {
        guard !activeDownloads.isEmpty else { return 0 }
        let total = activeDownloads.reduce(Int64(0)) { $0 + $1.totalLength }
        let completed = activeDownloads.reduce(Int64(0)) { $0 + $1.completedLength }
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var overallSpeed: Int64 {
        activeDownloads.reduce(Int64(0)) { $0 + $1.downloadSpeed }
    }

    func setBackends(_ list: [Aria2Backend]) {
        backendIds = list.map(\.id)
        for b in list {
            backends[b.id] = b
        }
    }

    func activeDownloads(for backendId: String) -> [DownloadItem] {
        activeDownloads.filter { $0.backendId == backendId }
    }

    func historyDownloads(for backendId: String) -> [DownloadItem] {
        historyDownloads.filter { $0.backendId == backendId }
    }

    func backendFor(_ id: String) -> Aria2Backend? {
        backends[id]
    }

    func trackDownload(gid: String, url: String, backend: Aria2Backend) {
        backends[backend.id] = backend
        let item = DownloadItem(
            id: gid,
            url: url,
            backendId: backend.id,
            filename: URL(string: url)?.lastPathComponent ?? url,
            filePath: "",
            status: .active,
            totalLength: 0,
            completedLength: 0,
            downloadSpeed: 0,
            addedAt: Date()
        )
        activeDownloads.insert(item, at: 0)
        startPollingIfNeeded()
    }

    func removeActiveDownload(_ item: DownloadItem) {
        let gid = item.id
        removingGids.insert(gid)
        activeDownloads.removeAll { $0.id == gid }

        guard let backend = backends[item.backendId] else {
            removingGids.remove(gid)
            return
        }
        Task {
            do {
                try await rpcClient.forceRemove(backend: backend, gid: gid)
            } catch {}
            try? await rpcClient.removeDownloadResult(backend: backend, gid: gid)
            removingGids.remove(gid)
        }
    }

    func openInFinder(_ item: DownloadItem) {
        guard let backend = backends[item.backendId],
              !item.filePath.isEmpty,
              let url = backend.smbURL(for: item.filePath) else { return }
        NSWorkspace.shared.open(url)
    }

    func clearHistory(for backendId: String) {
        historyDownloads.removeAll { $0.backendId == backendId }
        saveHistory()
    }

    // MARK: - Polling

    private func startPollingIfNeeded() {
        guard pollTask == nil else { return }
        pollTask = Task {
            while !Task.isCancelled && hasActiveDownloads {
                await pollActive()
                try? await Task.sleep(for: .seconds(1))
            }
            pollTask = nil
        }
    }

    private func pollActive() async {
        let snapshot = activeDownloads.map { ($0.id, $0.backendId) }

        for (gid, backendId) in snapshot {
            guard !removingGids.contains(gid) else { continue }
            guard let backend = backends[backendId] else { continue }

            do {
                let info = try await rpcClient.tellStatus(backend: backend, gid: gid)
                updateItem(gid: gid, with: info)
            } catch {
                if let idx = activeDownloads.firstIndex(where: { $0.id == gid }) {
                    activeDownloads[idx].status = .error
                    activeDownloads[idx].downloadSpeed = 0
                    moveToHistory(gid: gid)
                }
            }
        }
    }

    private func updateItem(gid: String, with info: [String: Any]) {
        guard let index = activeDownloads.firstIndex(where: { $0.id == gid }) else { return }

        let statusStr = info["status"] as? String ?? ""
        let status = DownloadStatus(rawValue: statusStr) ?? .error
        let totalLength = Int64(info["totalLength"] as? String ?? "0") ?? 0
        let completedLength = Int64(info["completedLength"] as? String ?? "0") ?? 0
        let downloadSpeed = Int64(info["downloadSpeed"] as? String ?? "0") ?? 0

        if let files = info["files"] as? [[String: Any]],
           let first = files.first,
           let path = first["path"] as? String,
           !path.isEmpty {
            activeDownloads[index].filePath = path
            activeDownloads[index].filename = (path as NSString).lastPathComponent
        }

        activeDownloads[index].status = status
        activeDownloads[index].totalLength = totalLength
        activeDownloads[index].completedLength = completedLength
        activeDownloads[index].downloadSpeed = downloadSpeed

        if status.isFinished {
            let wasComplete = status == .complete
            moveToHistory(gid: gid)
            if wasComplete {
                promptOpenFile(gid: gid)
            }
        }
    }

    private func moveToHistory(gid: String) {
        guard let index = activeDownloads.firstIndex(where: { $0.id == gid }) else { return }
        var item = activeDownloads.remove(at: index)
        item.downloadSpeed = 0
        item.finishedAt = Date()
        historyDownloads.insert(item, at: 0)
        if historyDownloads.count > Self.maxHistory {
            historyDownloads = Array(historyDownloads.prefix(Self.maxHistory))
        }
        saveHistory()
    }

    private func promptOpenFile(gid: String) {
        guard let item = historyDownloads.first(where: { $0.id == gid }),
              let backend = backends[item.backendId],
              !item.filePath.isEmpty,
              backend.smbURL(for: item.filePath) != nil else { return }

        let alert = NSAlert()
        alert.messageText = "Download Complete"
        alert.informativeText = "Open \(item.filename) in Finder?"
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openInFinder(item)
        }
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let data = defaults.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([DownloadItem].self, from: data) else {
            return
        }
        historyDownloads = items
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(historyDownloads) {
            defaults.set(data, forKey: historyKey)
        }
    }
}
