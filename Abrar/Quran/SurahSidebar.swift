import SwiftUI

struct SurahSidebar: View {
    @Environment(ReaderModel.self) private var reader
    @Environment(SettingsStore.self) private var store
    @Environment(DownloadManager.self) private var downloads

    var body: some View {
        @Bindable var reader = reader
        let downloaded = downloads.downloadedSizes(reciterID: store.settings.reciterID)
        List(reader.filteredSurahs, selection: $reader.selectedSurahID) { surah in
            SurahRow(surah: surah, isDownloaded: downloaded[surah.id] != nil)
                .tag(surah.id)
        }
        .searchable(text: $reader.searchText, placement: .sidebar, prompt: "Name or number")
        .overlay {
            if reader.filteredSurahs.isEmpty {
                ContentUnavailableView.search(text: reader.searchText)
            }
        }
    }
}

private struct SurahRow: View {
    let surah: Surah
    let isDownloaded: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("\(surah.id)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 28, height: 28)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliterated)
                    .font(.body.weight(.medium))
                Text("\(surah.nameEnglish) · \(surah.ayahCount) ayahs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if isDownloaded {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.secondary)
                    .help("Downloaded for offline listening")
            }
            Text(surah.nameArabic)
                .font(QuranFont.font(size: 18))
        }
        .padding(.vertical, 2)
    }
}
