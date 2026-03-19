import Foundation
import SwiftUI

@MainActor
final class DownloadDialogViewModel: ObservableObject {
    @Published var url: String
    @Published var selectedBackend: Aria2Backend
    @Published var dir: String
    @Published var pathHistory: [String] = []
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    let backends: [Aria2Backend]
    private let rpcClient = Aria2RPCClient()
    /// Returns (gid, backend) on success, nil on cancel
    var onComplete: (@MainActor ((String, Aria2Backend)?) -> Void)?

    init(url: String, config: AppConfig) {
        self.url = url
        self.backends = config.backends
        let backend = config.defaultBackend ?? config.backends.first!
        self.selectedBackend = backend
        self.dir = backend.defaultDir
        self.pathHistory = PathHistoryStore.shared.history(for: backend.id).paths
    }

    func backendChanged() {
        dir = selectedBackend.defaultDir
        pathHistory = PathHistoryStore.shared.history(for: selectedBackend.id).paths
    }

    func submit() {
        guard !url.isEmpty, !dir.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let gid = try await rpcClient.addUri(
                    backend: selectedBackend,
                    uris: [url],
                    dir: dir
                )
                PathHistoryStore.shared.addPath(dir, for: selectedBackend.id)
                onComplete?((gid, selectedBackend))
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }

    func cancel() {
        onComplete?(nil)
    }
}
