import SwiftUI

struct BookmarksList: View {
    var onOpen: () -> Void

    @Environment(ReaderModel.self) private var reader

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Bookmarks")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
            if reader.bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks Yet",
                    systemImage: "bookmark",
                    description: Text("Hover over an ayah and click the bookmark, or right-click it.")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(reader.bookmarks) { bookmark in
                            BookmarkRow(bookmark: bookmark) {
                                reader.open(surah: bookmark.surah, ayah: bookmark.ayah)
                                onOpen()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(width: 300, height: 340)
    }
}

private struct BookmarkRow: View {
    let bookmark: Bookmark
    var open: () -> Void

    @Environment(ReaderModel.self) private var reader
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: open) {
                HStack(spacing: 10) {
                    StarBadge(number: bookmark.surah, size: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(reader.surahName(bookmark.surah))
                            .font(.callout.weight(.medium))
                        Text("Ayah \(bookmark.ayah) · \(bookmark.createdAt.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(reader.surahName(bookmark.surah)), ayah \(bookmark.ayah)")
            Button("Remove Bookmark", systemImage: "xmark") { reader.removeBookmark(bookmark) }
                .buttonStyle(.icon(size: 22))
                .font(.caption)
                .foregroundStyle(.secondary)
                .opacity(isHovering ? 1 : 0)
                .help("Remove bookmark")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .hoverHighlight()
        .onHover { isHovering = $0 }
    }
}
