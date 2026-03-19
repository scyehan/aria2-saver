import Foundation

struct Aria2RPCError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct Aria2StatusInfo: Sendable {
    let status: String
    let totalLength: Int64
    let completedLength: Int64
    let downloadSpeed: Int64
    let filePath: String?
    let fileName: String?
}

struct Aria2RPCClient: Sendable {

    private static let statusKeys = [
        "gid", "status", "totalLength", "completedLength",
        "downloadSpeed", "files",
    ] as [String]

    func addUri(backend: Aria2Backend, uris: [String], dir: String) async throws -> String {
        let params: [any Sendable] = buildParams(backend: backend, extra: [uris, ["dir": dir] as [String: String]])
        let result = try await call(backend: backend, method: "aria2.addUri", params: params)
        guard let gid = result as? String else {
            throw Aria2RPCError(message: "Unexpected response from aria2")
        }
        return gid
    }

    func tellStatus(backend: Aria2Backend, gid: String) async throws -> Aria2StatusInfo {
        let params: [any Sendable] = buildParams(backend: backend, extra: [gid, Self.statusKeys])
        let result = try await call(backend: backend, method: "aria2.tellStatus", params: params)
        guard let dict = result as? [String: Any] else {
            throw Aria2RPCError(message: "Unexpected response from aria2")
        }
        var filePath: String?
        var fileName: String?
        if let files = dict["files"] as? [[String: Any]],
           let first = files.first,
           let path = first["path"] as? String,
           !path.isEmpty {
            filePath = path
            fileName = (path as NSString).lastPathComponent
        }
        return Aria2StatusInfo(
            status: dict["status"] as? String ?? "",
            totalLength: Int64(dict["totalLength"] as? String ?? "0") ?? 0,
            completedLength: Int64(dict["completedLength"] as? String ?? "0") ?? 0,
            downloadSpeed: Int64(dict["downloadSpeed"] as? String ?? "0") ?? 0,
            filePath: filePath,
            fileName: fileName
        )
    }

    func remove(backend: Aria2Backend, gid: String) async throws {
        let params: [any Sendable] = buildParams(backend: backend, extra: [gid])
        _ = try await call(backend: backend, method: "aria2.remove", params: params)
    }

    func forceRemove(backend: Aria2Backend, gid: String) async throws {
        let params: [any Sendable] = buildParams(backend: backend, extra: [gid])
        _ = try await call(backend: backend, method: "aria2.forceRemove", params: params)
    }

    func removeDownloadResult(backend: Aria2Backend, gid: String) async throws {
        let params: [any Sendable] = buildParams(backend: backend, extra: [gid])
        _ = try await call(backend: backend, method: "aria2.removeDownloadResult", params: params)
    }

    func getVersion(backend: Aria2Backend) async throws -> String {
        let params: [any Sendable] = buildParams(backend: backend, extra: [])
        let result = try await call(backend: backend, method: "aria2.getVersion", params: params)
        guard let dict = result as? [String: Any],
              let version = dict["version"] as? String else {
            throw Aria2RPCError(message: "Unexpected response from aria2")
        }
        return version
    }

    private func buildParams(backend: Aria2Backend, extra: [any Sendable]) -> [any Sendable] {
        var params: [any Sendable] = []
        if !backend.secret.isEmpty {
            params.append("token:\(backend.secret)")
        }
        params.append(contentsOf: extra)
        return params
    }

    private func call(backend: Aria2Backend, method: String, params: [any Sendable]) async throws -> Any {
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": method,
            "params": params,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: backend.rpcURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw Aria2RPCError(message: "HTTP error from aria2")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Aria2RPCError(message: "Invalid JSON response")
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw Aria2RPCError(message: message)
        }

        guard let result = json["result"] else {
            throw Aria2RPCError(message: "No result in response")
        }

        return result
    }
}
