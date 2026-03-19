import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init(contentView: some View, width: CGFloat = 480, height: CGFloat = 280, fullSizeContent: Bool = true) {
        var style: NSWindow.StyleMask = [.titled, .closable]
        if fullSizeContent {
            style.insert(.fullSizeContentView)
        }

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: style,
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        animationBehavior = .utilityWindow
        isReleasedWhenClosed = false

        if fullSizeContent {
            titlebarAppearsTransparent = true
            titleVisibility = .hidden
        }

        self.contentView = NSHostingView(rootView: contentView)
        center()
    }
}
