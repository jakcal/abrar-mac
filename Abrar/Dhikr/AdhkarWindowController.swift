import AppKit
import SwiftUI

/// An AppKit window so it can also be opened from a notification click, outside any SwiftUI view.
@MainActor
final class AdhkarWindowController {
    private let model: AdhkarModel
    private var window: NSWindow?

    init(model: AdhkarModel) {
        self.model = model
    }

    func show(_ session: AdhkarSession) {
        model.session = session
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let controller = NSHostingController(rootView: AdhkarView().environment(model))
        controller.sceneBridgingOptions = [.toolbars]
        let window = NSWindow(contentViewController: controller)
        window.title = "Adhkar"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 640, height: 760))
        window.center()
        window.setFrameAutosaveName("Adhkar")
        return window
    }
}
