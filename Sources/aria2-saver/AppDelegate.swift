import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var config = ConfigService.shared.load()
    private var dialogPanel: FloatingPanel?
    private var listWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        DownloadManager.shared.setBackends(config.backends)

        NotificationCenter.default.addObserver(
            self, selector: #selector(reloadConfig),
            name: .reloadConfig, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(showDownloadList),
            name: .showDownloadList, object: nil
        )
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            let urlString = url.absoluteString
            guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else { continue }
            showDownloadDialog(for: urlString)
        }
    }

    @objc private func reloadConfig() {
        config = ConfigService.shared.load()
        DownloadManager.shared.setBackends(config.backends)
    }

    @objc private func showDownloadList() {
        if let existing = listWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = DownloadListView(manager: DownloadManager.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Downloads"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        self.listWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showDownloadDialog(for url: String) {
        guard !config.backends.isEmpty else {
            sendNotification(title: "aria2-saver", body: "No backends configured. Edit ~/.config/aria2-saver/config.yaml")
            return
        }

        let vm = DownloadDialogViewModel(url: url, config: config)
        let view = DownloadDialogView(viewModel: vm)
        let newPanel = FloatingPanel(contentView: view)

        vm.onComplete = { [weak self, weak newPanel] result in
            guard let self else { return }
            newPanel?.close()
            self.dialogPanel = nil

            if let (gid, backend) = result {
                DownloadManager.shared.trackDownload(gid: gid, url: url, backend: backend)
                self.sendNotification(title: "Download Added", body: URL(string: url)?.lastPathComponent ?? url)
            }
        }

        self.dialogPanel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
