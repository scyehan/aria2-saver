import SwiftUI

struct DownloadListView: View {
    @ObservedObject var manager: DownloadManager
    @State private var selectedTab: String = ""

    var body: some View {
        VStack(spacing: 0) {
            if manager.backendIds.count > 1 {
                Picker("", selection: $selectedTab) {
                    ForEach(manager.backendIds, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            let active = manager.activeDownloads(for: selectedTab)
            let history = manager.historyDownloads(for: selectedTab)

            if active.isEmpty && history.isEmpty {
                Text("No downloads")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if !active.isEmpty {
                            SectionHeader(title: "Downloading")
                            ForEach(active) { item in
                                ActiveDownloadRow(item: item) {
                                    manager.removeActiveDownload(item)
                                }
                                Divider().padding(.horizontal, 12)
                            }
                        }

                        if !history.isEmpty {
                            HStack {
                                SectionHeader(title: "History")
                                Spacer()
                                Button("Clear") {
                                    manager.clearHistory(for: selectedTab)
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 12)
                                .padding(.top, 8)
                            }
                            ForEach(history) { item in
                                HistoryDownloadRow(item: item) {
                                    manager.openInFinder(item)
                                }
                                Divider().padding(.horizontal, 12)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if selectedTab.isEmpty, let first = manager.backendIds.first {
                selectedTab = first
            }
        }
        .onChange(of: manager.backendIds) {
            if !manager.backendIds.contains(selectedTab),
               let first = manager.backendIds.first {
                selectedTab = first
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

struct ActiveDownloadRow: View {
    let item: DownloadItem
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.filename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.callout)
                Spacer()
                StatusBadge(status: item.status)
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Stop and remove")
            }

            ProgressView(value: item.progress)
                .progressViewStyle(.linear)

            HStack {
                Text(item.progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !item.speedText.isEmpty {
                    Text(item.speedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(Int(item.progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct HistoryDownloadRow: View {
    let item: DownloadItem
    var onOpen: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.status == .complete ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(item.status == .complete ? .green : .red)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.callout)
                HStack(spacing: 8) {
                    if item.totalLength > 0 {
                        Text(DownloadItem.formatBytes(item.totalLength))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let finished = item.finishedAt {
                        Text(finished, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if item.status == .complete && !item.filePath.isEmpty {
                Button(action: onOpen) {
                    Image(systemName: "folder")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("Open in Finder")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct StatusBadge: View {
    let status: DownloadStatus

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private var label: String {
        switch status {
        case .active: "Downloading"
        case .waiting: "Waiting"
        case .paused: "Paused"
        case .complete: "Done"
        case .error: "Error"
        case .removed: "Removed"
        }
    }

    private var color: Color {
        switch status {
        case .active: .blue
        case .waiting: .orange
        case .paused: .yellow
        case .complete: .green
        case .error: .red
        case .removed: .gray
        }
    }
}
