import SwiftUI

struct DownloadDialogView: View {
    @ObservedObject var viewModel: DownloadDialogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Download")
                .font(.headline)

            LabeledContent("URL") {
                Text(viewModel.url)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }

            LabeledContent("Backend") {
                Picker("", selection: $viewModel.selectedBackend) {
                    ForEach(viewModel.backends) { backend in
                        Text("\(backend.id) (\(backend.host))").tag(backend)
                    }
                }
                .labelsHidden()
                .onChange(of: viewModel.selectedBackend) {
                    viewModel.backendChanged()
                }
            }

            LabeledContent("Save to") {
                ComboBox(text: $viewModel.dir, items: viewModel.pathHistory)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    viewModel.cancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Download") {
                    viewModel.submit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isSubmitting || viewModel.url.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}

struct ComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = false
        comboBox.completes = true
        comboBox.hasVerticalScroller = true
        comboBox.numberOfVisibleItems = 6
        comboBox.delegate = context.coordinator
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        comboBox.removeAllItems()
        comboBox.addItems(withObjectValues: items)

        if comboBox.stringValue != text {
            comboBox.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: ComboBox

        init(_ parent: ComboBox) {
            self.parent = parent
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox,
                  comboBox.indexOfSelectedItem >= 0 else { return }
            DispatchQueue.main.async {
                self.parent.text = comboBox.objectValueOfSelectedItem as? String ?? ""
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }
    }
}
