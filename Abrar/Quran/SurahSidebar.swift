import SwiftUI

struct SurahSidebar: View {
    @Environment(ReaderModel.self) private var reader
    @Environment(SettingsStore.self) private var store
    @Environment(DownloadManager.self) private var downloads
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        @Bindable var reader = reader
        let downloaded = downloads.downloadedSizes(reciterID: store.settings.reciterID)
        List(reader.filteredSurahs, selection: $reader.selectedSurahID) { surah in
            SurahRow(
                surah: surah,
                isDownloaded: downloaded[surah.id] != nil,
                isSelected: reader.selectedSurahID == surah.id,
                playback: player.surah?.id == surah.id ? (player.isPlaying ? .playing : .paused) : nil
            )
            .tag(surah.id)
        }
        .searchable(text: $reader.searchText, placement: .sidebar, prompt: "Name or number")
        .overlay {
            if reader.filteredSurahs.isEmpty {
                ContentUnavailableView.search(text: reader.searchText)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DownloadAllView(compact: true)
        }
    }
}

private struct SurahRow: View {
    enum Playback { case playing, paused }

    let surah: Surah
    let isDownloaded: Bool
    let isSelected: Bool
    let playback: Playback?

    var body: some View {
        HStack(spacing: 10) {
            StarBadge(number: surah.id, isHighlighted: playback != nil && !isSelected)
            VStack(alignment: .leading, spacing: 1) {
                Text(surah.nameTransliterated)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(surah.nameEnglish) · \(surah.ayahCount) ayahs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            status
            Text(surah.nameArabic)
                .font(QuranFont.font(size: 19))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var status: some View {
        if let playback {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, isActive: playback == .playing)
                .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.tint))
                .font(.caption)
                .help(playback == .playing ? "Now playing" : "Paused")
        } else if isDownloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .help("Downloaded for offline listening")
        }
    }

    private var accessibilityText: String {
        var parts = ["\(surah.id). \(surah.nameTransliterated)", surah.nameEnglish, "\(surah.ayahCount) ayahs"]
        if playback == .playing { parts.append("now playing") }
        if isDownloaded { parts.append("downloaded") }
        return parts.joined(separator: ", ")
    }
}
