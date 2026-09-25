import AppKit
import SwiftUI

struct AyahRow: View {
    let ayah: Ayah
    let fontSize: Double
    let isRecited: Bool

    @Environment(ReaderModel.self) private var reader
    @Environment(AudioPlayerService.self) private var player
    @Environment(SettingsStore.self) private var store

    var body: some View {
        let bookmarked = reader.isBookmarked(ayah)
        HStack(alignment: .top, spacing: 12) {
            Text("\(ayah.text) \u{06DD}\(QuranFont.arabicDigits(ayah.number))")
                .font(QuranFont.font(size: fontSize))
                .lineSpacing(fontSize * 0.5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.tint)
                .opacity(bookmarked ? 1 : 0)
                .accessibilityHidden(!bookmarked)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(isRecited ? 0.14 : 0))
        )
        .animation(.easeInOut(duration: 0.25), value: isRecited)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Play from Ayah \(ayah.number)", systemImage: "play") {
                guard let surah = reader.selectedSurah else { return }
                player.play(ayah: ayah.number, in: surah, reciter: Reciter.with(id: store.settings.reciterID))
            }
            Button(bookmarked ? "Remove Bookmark" : "Bookmark Ayah \(ayah.number)", systemImage: "bookmark") {
                reader.toggleBookmark(ayah)
            }
            Button("Copy Ayah", systemImage: "doc.on.doc") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ayah.text, forType: .string)
            }
        }
    }
}
