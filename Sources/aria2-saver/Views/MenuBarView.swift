import SwiftUI

struct MenuBarView: View {
    @ObservedObject var manager = DownloadManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Active downloads summary
            if !manager.activeDownloads.isEmpty {
                ForEach(manager.activeDownloads.prefix(3)) { item in
                    HStack(spacing: 6) {
                        ProgressView(value: item.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 60)
                        Text(item.filename)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.caption)
                        Spacer()
                        if !item.speedText.isEmpty {
                            Text(item.speedText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
                if manager.activeDownloads.count > 3 {
                    Text("+\(manager.activeDownloads.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                }
            } else {
                Text("No active downloads")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }

            Divider().padding(.vertical, 4)

            Button("Show Downloads...") {
                NotificationCenter.default.post(name: .showDownloadList, object: nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Button("Reload Config") {
                NotificationCenter.default.post(name: .reloadConfig, object: nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider().padding(.vertical, 4)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
        .frame(minWidth: 280)
    }
}

extension Notification.Name {
    static let reloadConfig = Notification.Name("reloadConfig")
    static let showDownloadList = Notification.Name("showDownloadList")
}
