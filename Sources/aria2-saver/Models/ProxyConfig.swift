import Foundation

struct ProxyConfig: Codable, Identifiable, Hashable {
    let label: String
    let host: String
    var port: Int = 8080

    var id: String { label }

    var proxyURL: String {
        "http://\(host):\(port)"
    }
}
