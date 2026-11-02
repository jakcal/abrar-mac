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
        let showsTranslation = store.settings.showTranslation
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    SurahHeader(surah: surah)
                        .padding(.bottom, 8)
                    // Ayahs are keyed by `Ayah.id` (surah and number) so rows never carry over between surahs.
                    ForEach(reader.ayahs) { ayah in
                        VStack(spacing: 4) {
                            if let juz = reader.startsJuz(ayah) {
                                JuzDivider(juz: juz)
                            }
                            AyahRow(
                                ayah: ayah,
                                fontSize: store.settings.quranFontSize,
                                isRecited: ayah.number == recited,
                                translation: showsTranslation ? reader.translation(of: ayah) : nil
                            )
                        }
                        .id(ayah.id)
                        .onAppear { reader.ayahAppeared(ayah.number) }
                        .onDisappear { reader.ayahDisappeared(ayah.number) }
                    }
                    SurahEndNavigation(surah: surah)
                    TanzilFooter(showsTranslation: showsTranslation)
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
        .overlay(alignment: .top) { ReadingProgress(surah: surah) }
        .readerTheme(store.settings.readerTheme)
        .background { ReaderLocationTitle(surah: surah) }
    }

    /// Space toggles whatever is loaded, or starts this surah.
    private func togglePlayback() {
        if player.surah != nil {
            player.togglePlayPause()
        } else {
            player.play(surah: surah, reciter: Reciter.with(id: store.settings.reciterID))
        }
    }

    /// Scrolls twice: rows far down a lazy stack only get their real height once the first jump lays them out,
    /// so a single jump to a late ayah (a bookmark, or where you stopped reading) can land a few ayahs off.
    private func scroll(_ proxy: ScrollViewProxy, to target: Int?) {
        guard let target, reader.ayahs.contains(where: { $0.number == target }) else { return }
        let id = surah.id * 1000 + target
        Task { @MainActor in
            proxy.scrollTo(id, anchor: .top)
            try? await Task.sleep(for: .milliseconds(150))
            proxy.scrollTo(id, anchor: .top)
            reader.scrollTarget = nil
        }
    }
}

/// Title bar location: surah, juz and mushaf page of the topmost ayah. Kept in its own view so scrolling only
/// redraws the title, not the reader.
private struct ReaderLocationTitle: View {
    let surah: Surah

    @Environment(ReaderModel.self) private var reader

    var body: some View {
        Color.clear
            .navigationTitle(surah.nameTransliterated)
            .navigationSubtitle(subtitle)
    }

    private var subtitle: String {
        let ayah = reader.topAyah ?? 1
        var parts = [surah.nameEnglish]
        if let juz = reader.juz(surah: surah.id, ayah: ayah) { parts.append("Juz \(juz)") }
        if let page = reader.page(surah: surah.id, ayah: ayah) { parts.append("Page \(page)") }
        return parts.joined(separator: " · ")
    }
}

/// Hairline across the top of the page showing how far through the surah you've read.
private struct ReadingProgress: View {
    let surah: Surah

    @Environment(ReaderModel.self) private var reader

    var body: some View {
        let value = Double(reader.topAyah ?? 0) / Double(max(surah.ayahCount, 1))
        GeometryReader { proxy in
            Capsule()
                .fill(Color.brand.opacity(0.7))
                .frame(width: proxy.size.width * min(1, value))
        }
        .frame(height: 2)
        .opacity(reader.topAyah == nil ? 0 : 1)
        .motion(Motion.standard, value: value)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Previous and next surah at the end of the page, so reading can carry on without the sidebar.
private struct SurahEndNavigation: View {
    let surah: Surah

    @Environment(ReaderModel.self) private var reader

    var body: some View {
        HStack(spacing: 12) {
            if let previous = neighbour(-1) {
                link(previous, title: "Previous", systemImage: "chevron.left", alignment: .leading)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
            if let next = neighbour(1) {
                link(next, title: "Next", systemImage: "chevron.right", alignment: .trailing)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 32)
    }

    private func neighbour(_ offset: Int) -> Surah? {
        reader.surahs.first { $0.id == surah.id + offset }
    }

    private func link(_ target: Surah, title: String, systemImage: String, alignment: HorizontalAlignment) -> some View {
        Button { reader.open(surah: target.id) } label: {
            HStack(spacing: 10) {
                if alignment == .leading { Image(systemName: systemImage).foregroundStyle(.tertiary) }
                VStack(alignment: alignment, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(target.id). \(target.nameTransliterated)")
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                }
                if alignment == .trailing { Image(systemName: systemImage).foregroundStyle(.tertiary) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentCard(cornerRadius: 14)
        .hoverHighlight(cornerRadius: 14)
        .help("\(title) surah: \(target.nameTransliterated)")
    }
}

private struct TanzilFooter: View {
    let showsTranslation: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Tanzil's terms require naming the source and linking to tanzil.net.
            Text("Quran text: [Tanzil Project](https://tanzil.net) (tanzil.net)")
            if showsTranslation {
                Text("Translation: Saheeh International, via [Tanzil](https://tanzil.net/trans/)")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 28)
    }
}

extension View {
    /// Page colour for the reader. Paper and Night also pin the colour scheme so text stays readable on them.
    @ViewBuilder
    func readerTheme(_ theme: ReaderTheme) -> some View {
        switch theme {
        case .standard:
            self
        case .paper:
            background(Color(red: 0.976, green: 0.953, blue: 0.898)).environment(\.colorScheme, .light)
        case .night:
            background(Color(red: 0.06, green: 0.07, blue: 0.08)).environment(\.colorScheme, .dark)
        }
    }
}
