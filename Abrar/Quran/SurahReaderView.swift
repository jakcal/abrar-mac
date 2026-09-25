import SwiftUI

struct SurahReaderView: View {
    let surah: Surah

    @Environment(ReaderModel.self) private var reader
    @Environment(SettingsStore.self) private var store
    @Environment(AudioPlayerService.self) private var player
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    /// Ayah currently recited in this surah, if it's the one playing.
    private var recitedAyah: Int? {
        player.surah?.id == surah.id ? player.currentAyah : nil
    }

    var body: some View {
        let recited = recitedAyah
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    SurahHeader(surah: surah)
                        .padding(.bottom, 8)
                    // Ayahs are keyed by `Ayah.id` (surah and number) so rows never carry over between surahs.
                    ForEach(reader.ayahs) { ayah in
                        AyahRow(ayah: ayah, fontSize: store.settings.quranFontSize, isRecited: ayah.number == recited)
                            .id(ayah.id)
                            .onAppear { reader.ayahAppeared(ayah.number) }
                            .onDisappear { reader.ayahDisappeared(ayah.number) }
                    }
                    TanzilFooter()
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: Metrics.readingWidth)
                .frame(maxWidth: .infinity)
            }
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onKeyPress(.space) {
                togglePlayback()
                return .handled
            }
            // Clicking the page gives it focus so Space reaches it, without stealing it from the sidebar.
            .simultaneousGesture(TapGesture().onEnded { isFocused = true })
            .onChange(of: reader.scrollTarget, initial: true) { _, target in
                scroll(proxy, to: target)
            }
            .onChange(of: reader.ayahs) {
                scroll(proxy, to: reader.scrollTarget)
            }
            .onChange(of: recited) { _, ayah in
                guard let ayah, store.settings.followRecitation else { return }
                withAnimation(reduceMotion ? nil : Motion.scroll) {
                    proxy.scrollTo(surah.id * 1000 + ayah, anchor: .center)
                }
            }
        }
        .navigationTitle("Abrar")
        .navigationSubtitle("\(surah.nameTransliterated) · \(surah.nameEnglish)")
    }

    /// Space toggles whatever is loaded, or starts this surah.
    private func togglePlayback() {
        if player.surah != nil {
            player.togglePlayPause()
        } else {
            player.play(surah: surah, reciter: Reciter.with(id: store.settings.reciterID))
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to target: Int?) {
        guard let target, reader.ayahs.contains(where: { $0.number == target }) else { return }
        let id = surah.id * 1000 + target
        DispatchQueue.main.async {
            proxy.scrollTo(id, anchor: .top)
            reader.scrollTarget = nil
        }
    }
}

private struct TanzilFooter: View {
    var body: some View {
        // Tanzil's terms require naming the source and linking to tanzil.net.
        Text("Quran text: [Tanzil Project](https://tanzil.net) (tanzil.net)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 28)
    }
}
