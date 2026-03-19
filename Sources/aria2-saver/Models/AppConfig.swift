import Foundation

struct AppConfig: Codable {
    var backends: [Aria2Backend] = []
    var defaultBackendId: String = ""

    var defaultBackend: Aria2Backend? {
        backends.first { $0.id == defaultBackendId } ?? backends.first
    }
}
