import SwiftUI

struct QuranWindow: View {
    @Environment(ReaderModel.self) private var reader
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        NavigationSplitView {
            SurahSidebar()
                .navigationSplitViewColumnWidth(min: 250, ideal: 290, max: 380)
        } detail: {
            // A stacked bar (not a safe-area inset) so it never covers the last ayahs.
            VStack(spacing: 0) {
                if let surah = reader.selectedSurah {
                    // Fresh view per surah so the scroll view and lazy rows don't carry over.
                    SurahReaderView(surah: surah)
                        .id(surah.id)
                } else {
                    NoSurahView()
                }
                if let surah = player.surah {
                    PlayerBar(surah: surah)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .motion(Motion.standard, value: player.surah == nil)
        }
        .toolbar { ReaderToolbar() }
        .background { ReaderShortcuts() }
        .frame(minWidth: 780, minHeight: 500)
    }
}

private struct NoSurahView: View {
    @Environment(ReaderModel.self) private var reader

    var body: some View {
        ContentUnavailableView {
            Label("Select a Surah", systemImage: "book.pages")
        } description: {
            Text(reader.errorMessage ?? "Pick a surah from the sidebar to start reading.")
        } actions: {
            Button("Open Al-Fatiha") { reader.open(surah: 1) }
                .glassButtonStyle(prominent: true)
                .disabled(reader.surahs.isEmpty)
        }
        .frame(maxHeight: .infinity)
    }
}
