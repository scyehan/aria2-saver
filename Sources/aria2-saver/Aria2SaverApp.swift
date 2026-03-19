import SwiftUI

@main
struct Aria2SaverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var downloadManager = DownloadManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            if downloadManager.hasActiveDownloads {
                let pct = Int(downloadManager.overallProgress * 100)
                let speed = DownloadItem.formatBytes(downloadManager.overallSpeed)
                Text("\(pct)% \(speed)/s")
                    .monospacedDigit()
            }
            Image(systemName: downloadManager.hasActiveDownloads ? "arrow.down.circle.fill" : "arrow.down.circle")
        }
    }
}
