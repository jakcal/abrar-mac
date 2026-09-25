import SwiftUI

struct QuranWindow: View {
    @Environment(ReaderModel.self) private var reader
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        @Bindable var reader = reader
        NavigationSplitView {
            SurahSidebar()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            // A stacked bar (not a safe-area inset) so it never covers the last ayahs.
            VStack(spacing: 0) {
                if let surah = reader.selectedSurah {
                    // Fresh view per surah so the scroll view and lazy rows don't carry over.
                    SurahReaderView(surah: surah)
                        .id(surah.id)
                } else {
                    ContentUnavailableView("Select a Surah", systemImage: "book", description: Text("Pick a surah from the list to start reading."))
                        .frame(maxHeight: .infinity)
                }
                if player.surah != nil {
                    PlayerBar()
                }
            }
        }
        .toolbar { ReaderToolbar() }
        .frame(minWidth: 760, minHeight: 480)
    }
}

private struct ReaderToolbar: ToolbarContent {
    @Environment(SettingsStore.self) private var store
    @State private var showsBookmarks = false

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                store.settings.quranFontSize = max(18, store.settings.quranFontSize - 2)
            } label: {
                Label("Smaller Text", systemImage: "textformat.size.smaller")
            }
            .keyboardShortcut("-", modifiers: .command)

            Button {
                store.settings.quranFontSize = min(64, store.settings.quranFontSize + 2)
            } label: {
                Label("Larger Text", systemImage: "textformat.size.larger")
            }
            .keyboardShortcut("+", modifiers: .command)

            Toggle(isOn: Bindable(store).settings.followRecitation) {
                Label("Follow Recitation", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .help("Scroll to the ayah being recited")

            Button {
                showsBookmarks.toggle()
            } label: {
                Label("Bookmarks", systemImage: "bookmark")
            }
            .popover(isPresented: $showsBookmarks, arrowEdge: .bottom) {
                BookmarksList { showsBookmarks = false }
            }
        }
    }
}
