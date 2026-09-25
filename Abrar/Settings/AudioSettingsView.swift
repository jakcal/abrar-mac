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
            Picker("Reciter", selection: $store.settings.reciterID) {
                ForEach(Reciter.all) { Text($0.displayName).tag($0.id) }
            }
            Toggle("Follow recitation in the reader", isOn: $store.settings.followRecitation)
            Section {
                if sizes.isEmpty {
                    Text("No downloads for this reciter.").foregroundStyle(.secondary)
                }
                ForEach(sizes.keys.sorted(), id: \.self) { surah in
                    HStack {
                        Text("\(surah). \(app.reader.surahName(surah))")
                        Spacer()
                        Text((sizes[surah] ?? 0).formatted(.byteCount(style: .file)))
                            .foregroundStyle(.secondary)
                        Button("Delete", systemImage: "trash") {
                            downloads.delete(DownloadKey(reciterID: reciterID, surah: surah))
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("Downloads")
            } footer: {
                Text("Total: \(sizes.values.reduce(0, +).formatted(.byteCount(style: .file)))")
            }
        }
        .formStyle(.grouped)
    }
}
