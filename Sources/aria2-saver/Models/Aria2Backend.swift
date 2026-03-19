import Foundation

struct Aria2Backend: Codable, Identifiable, Hashable {
    let id: String
    let host: String
    var port: Int = 6800
    var useTLS: Bool = false
    var secret: String = ""
    var defaultDir: String = ""
    var sambaPrefix: String?
    var sambaHost: String?

    var rpcURL: URL {
        let scheme = useTLS ? "https" : "http"
        return URL(string: "\(scheme)://\(host):\(port)/jsonrpc")!
    }

    func smbURL(for filePath: String) -> URL? {
        var components = URLComponents()
        components.scheme = "smb"
        components.host = sambaHost ?? host

        var pathParts = ""
        if let prefix = sambaPrefix, !prefix.isEmpty {
            pathParts += prefix.hasPrefix("/") ? prefix : "/\(prefix)"
        }
        let normalized = filePath.hasPrefix("/") ? filePath : "/\(filePath)"
        pathParts += normalized

        components.path = pathParts
        return components.url
    }
}
