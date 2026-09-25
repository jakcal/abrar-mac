import SwiftUI

struct BookmarksList: View {
    var onOpen: () -> Void

    @Environment(ReaderModel.self) private var reader

    var body: some View {
        Group {
            if reader.bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Right-click an ayah to bookmark it.")
                )
            } else {
                List(reader.bookmarks) { bookmark in
                    Button {
                        reader.open(surah: bookmark.surah, ayah: bookmark.ayah)
                        onOpen()
                    } label: {
                        HStack {
                            Text(reader.surahName(bookmark.surah))
                            Spacer()
                            Text("\(bookmark.surah):\(bookmark.ayah)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 280, height: 320)
    }
}
