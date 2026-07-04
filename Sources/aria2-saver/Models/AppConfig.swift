import Foundation

struct AppConfig: Codable {
    var backends: [Aria2Backend] = []
    var defaultBackendId: String = ""
    var proxies: [ProxyConfig]?
    var githubProxyPrefix: String?

    var defaultBackend: Aria2Backend? {
        backends.first { $0.id == defaultBackendId } ?? backends.first
    }
}
