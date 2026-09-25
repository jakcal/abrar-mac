import SwiftUI

struct AudioSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store
    @Environment(DownloadManager.self) private var downloads

    var body: some View {
        @Bindable var store = store
        let reciterID = store.settings.reciterID
        let sizes = downloads.downloadedSizes(reciterID: reciterID)
        Form {
            Section {
                Picker("Reciter", selection: $store.settings.reciterID) {
                    ForEach(Reciter.all) { Text($0.displayName).tag($0.id) }
                }
                Picker("Speed", selection: $store.settings.playbackRate) {
                    ForEach(AudioPlayerService.playbackRates, id: \.self) { Text(SpeedMenu.label($0)).tag($0) }
                }
                Toggle("Follow the recited ayah in the reader", isOn: $store.settings.followRecitation)
            } header: {
                Text("Recitation")
            } footer: {
                Text("Recitations stream from quran.com. Download surahs to listen offline.")
            }
            Section {
                DownloadAllView()
                ForEach(sizes.keys.sorted(), id: \.self) { surah in
                    DownloadedSurahRow(
                        title: "\(surah). \(app.reader.surahName(surah))",
                        size: sizes[surah] ?? 0
                    ) {
                        downloads.delete(DownloadKey(reciterID: reciterID, surah: surah))
                    }
                }
            } header: {
                Text("Downloads · \(Reciter.with(id: reciterID).name)")
            } footer: {
                if !sizes.isEmpty {
                    Text("\(sizes.count) saved · \(sizes.values.reduce(0, +).formatted(.byteCount(style: .file))) on disk")
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct DownloadedSurahRow: View {
    let title: String
    let size: Int64
    var delete: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(size.formatted(.byteCount(style: .file)))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Button("Delete \(title)", systemImage: "trash", action: delete)
                .buttonStyle(.icon(size: 24))
                .foregroundStyle(.secondary)
                .help("Delete download")
        }
    }
}
