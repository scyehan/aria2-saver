import AppKit
import Carbon.HIToolbox
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var config = ConfigService.shared.load()
    private var dialogPanel: FloatingPanel?
    private var listWindow: NSWindow?
    private var hotKeyRef: EventHotKeyRef?

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
        NotificationCenter.default.addObserver(
            self, selector: #selector(downloadFromClipboard),
            name: .downloadFromClipboard, object: nil
        )

        registerGlobalHotKey()
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

    @objc func downloadFromClipboard() {
        guard let clipString = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !clipString.isEmpty else {
            sendNotification(title: "aria2-saver", body: "No URL found in clipboard")
            return
        }

        // Support multiple URLs separated by newlines
        let urls = clipString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("http://") || $0.hasPrefix("https://") }

        guard let firstURL = urls.first else {
            sendNotification(title: "aria2-saver", body: "No valid URL in clipboard")
            return
        }

        showDownloadDialog(for: firstURL)
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

    // MARK: - Global Hot Key (⌘⇧D)

    private func registerGlobalHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4152_4932) // "ARI2"
        hotKeyID.id = 1

        // ⌘⇧D
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_D)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            MainActor.assumeIsolated {
                NotificationCenter.default.post(name: .downloadFromClipboard, object: nil)
            }
            return noErr
        }, 1, &eventType, nil, nil)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
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
