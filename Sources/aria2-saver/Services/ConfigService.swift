import Foundation
import Yams

@MainActor
final class ConfigService {
    static let shared = ConfigService()

    private let configDir: URL
    private let configFile: URL

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent(".config/aria2-saver")
        configFile = configDir.appendingPathComponent("config.yaml")
    }

    func load() -> AppConfig {
        let fm = FileManager.default

        if !fm.fileExists(atPath: configFile.path) {
            createExampleConfig()
        }

        guard let data = fm.contents(atPath: configFile.path),
              let yaml = String(data: data, encoding: .utf8) else {
            return AppConfig()
        }

        do {
            let config = try YAMLDecoder().decode(AppConfig.self, from: yaml)
            return config
        } catch {
            print("Failed to parse config: \(error)")
            return AppConfig()
        }
    }

    private func createExampleConfig() {
        let fm = FileManager.default
        try? fm.createDirectory(at: configDir, withIntermediateDirectories: true)

        let example = """
        backends:
          - id: homelab
            host: 192.168.1.100
            port: 6800
            useTLS: false
            secret: "mysecrettoken"
            defaultDir: /data/downloads
            sambaPrefix: /share

        defaultBackendId: homelab
        """

        fm.createFile(atPath: configFile.path, contents: example.data(using: .utf8))
    }
}
