import SwiftUI

struct SurahReaderView: View {
    let surah: Surah

    @Environment(ReaderModel.self) private var reader
    @Environment(SettingsStore.self) private var store
    @Environment(AudioPlayerService.self) private var player

    /// Ayah currently recited in this surah, if it's the one playing.
    private var recitedAyah: Int? {
        player.surah?.id == surah.id ? player.currentAyah : nil
    }

    var body: some View {
        let recited = recitedAyah
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    SurahHeader(surah: surah)
                        .padding(.bottom, 12)
                    // Ayahs are keyed by `Ayah.id` (surah and number) so rows never carry over between surahs.
                    ForEach(reader.ayahs) { ayah in
                        AyahRow(ayah: ayah, fontSize: store.settings.quranFontSize, isRecited: ayah.number == recited)
                            .id(ayah.id)
                            .onAppear { reader.ayahAppeared(ayah.number) }
                            .onDisappear { reader.ayahDisappeared(ayah.number) }
                        Divider().opacity(0.4)
                    }
                    TanzilFooter()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: reader.scrollTarget, initial: true) { _, target in
                scroll(proxy, to: target)
            }
            .onChange(of: reader.ayahs) {
                scroll(proxy, to: reader.scrollTarget)
            }
            .onChange(of: recited) { _, ayah in
                guard let ayah, store.settings.followRecitation else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(surah.id * 1000 + ayah, anchor: .center)
                }
            }
        }
        .navigationTitle(surah.nameTransliterated)
        .navigationSubtitle("\(surah.nameEnglish) · \(surah.revelationType)")
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
            .padding(.top, 24)
    }
}
