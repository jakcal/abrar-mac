import SwiftUI

struct ReaderToolbar: ToolbarContent {
    @Environment(SettingsStore.self) private var store
    @State private var showsBookmarks = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ControlGroup {
                Button("Smaller Text", systemImage: "textformat.size.smaller") { store.adjustQuranFontSize(by: -1) }
                    .help("Smaller text (⌘−)")
                    .disabled(store.settings.quranFontSize <= QuranTextSize.range.lowerBound)
                Button("Larger Text", systemImage: "textformat.size.larger") { store.adjustQuranFontSize(by: 1) }
                    .help("Larger text (⌘+)")
                    .disabled(store.settings.quranFontSize >= QuranTextSize.range.upperBound)
            } label: {
                Label("Text Size", systemImage: "textformat.size")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: Bindable(store).settings.followRecitation) {
                Label("Follow Recitation", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .help("Keep the recited ayah in view")
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Bookmarks", systemImage: "bookmark") { showsBookmarks.toggle() }
                .help("Bookmarks")
                .popover(isPresented: $showsBookmarks, arrowEdge: .bottom) {
                    BookmarksList { showsBookmarks = false }
                }
        }
    }
}

enum QuranTextSize {
    static let range: ClosedRange<Double> = 18...64
    static let step: Double = 2
}

extension SettingsStore {
    func adjustQuranFontSize(by steps: Int) {
        let size = settings.quranFontSize + Double(steps) * QuranTextSize.step
        settings.quranFontSize = min(QuranTextSize.range.upperBound, max(QuranTextSize.range.lowerBound, size))
    }

    func resetQuranFontSize() {
        settings.quranFontSize = AppSettings().quranFontSize
    }
}

/// Window-wide shortcuts. Invisible buttons, since the app has no main menu while it's an accessory.
struct ReaderShortcuts: View {
    @Environment(SettingsStore.self) private var store
    @Environment(ReaderModel.self) private var reader

    var body: some View {
        ZStack {
            Button("Larger Text") { store.adjustQuranFontSize(by: 1) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Larger Text") { store.adjustQuranFontSize(by: 1) }
                .keyboardShortcut("=", modifiers: .command)
            Button("Smaller Text") { store.adjustQuranFontSize(by: -1) }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size", action: store.resetQuranFontSize)
                .keyboardShortcut("0", modifiers: .command)
            Button("Previous Surah") { step(-1) }
                .keyboardShortcut("[", modifiers: .command)
            Button("Next Surah") { step(1) }
                .keyboardShortcut("]", modifiers: .command)
        }
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func step(_ offset: Int) {
        let target = (reader.selectedSurahID ?? 0) + offset
        guard reader.surahs.contains(where: { $0.id == target }) else { return }
        reader.open(surah: target)
    }
}
