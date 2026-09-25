import AppKit
import SwiftUI

struct AyahRow: View {
    let ayah: Ayah
    let fontSize: Double
    let isRecited: Bool

    @Environment(ReaderModel.self) private var reader
    @Environment(AudioPlayerService.self) private var player
    @Environment(SettingsStore.self) private var store
    @State private var isHovering = false

    var body: some View {
        let bookmarked = reader.isBookmarked(ayah)
        HStack(alignment: .top, spacing: 14) {
            Text("\(ayah.text)\u{00A0}\(Text(marker).foregroundStyle(Color.accentColor))")
                .font(QuranFont.font(size: fontSize))
                .lineSpacing(fontSize * 0.55)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            AyahActions(
                isRecited: isRecited,
                isBookmarked: bookmarked,
                isRevealed: isHovering,
                play: play,
                toggleBookmark: { reader.toggleBookmark(ayah) }
            )
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(highlight)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .motion(Motion.standard, value: isRecited)
        .motion(Motion.quick, value: isHovering)
        .contextMenu {
            Button("Play from Ayah \(ayah.number)", systemImage: "play", action: play)
            Button(bookmarked ? "Remove Bookmark" : "Bookmark Ayah \(ayah.number)", systemImage: "bookmark") {
                reader.toggleBookmark(ayah)
            }
            Button("Copy Ayah", systemImage: "doc.on.doc", action: copy)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ayah \(ayah.number)")
    }

    /// End-of-ayah sign enclosing the number (Amiri Quran composes them).
    private var marker: String { "\u{06DD}\(QuranFont.arabicDigits(ayah.number))" }

    @ViewBuilder
    private var highlight: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        if isRecited {
            shape.fill(Color.accentColor.opacity(0.10))
                .overlay(shape.strokeBorder(Color.accentColor.opacity(0.28), lineWidth: 1))
        } else {
            shape.fill(Color.primary.opacity(isHovering ? 0.035 : 0))
        }
    }

    private func play() {
        guard let surah = reader.selectedSurah else { return }
        player.play(ayah: ayah.number, in: surah, reciter: Reciter.with(id: store.settings.reciterID))
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ayah.text, forType: .string)
    }
}

/// Trailing column: recitation indicator, bookmark, and hover actions.
private struct AyahActions: View {
    let isRecited: Bool
    let isBookmarked: Bool
    let isRevealed: Bool
    var play: () -> Void
    var toggleBookmark: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            if isRecited && !isRevealed {
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative)
                    .foregroundStyle(.tint)
                    .frame(width: 26, height: 26)
                    .accessibilityLabel("Being recited")
            } else {
                Button("Play from Here", systemImage: "play.fill", action: play)
                    .buttonStyle(.icon(size: 26))
                    .opacity(isRevealed ? 1 : 0)
                    .help("Play from this ayah")
            }
            Button(isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark", action: toggleBookmark)
                .buttonStyle(.icon(size: 26))
                .foregroundStyle(isBookmarked ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .opacity(isRevealed || isBookmarked ? 1 : 0)
                .help(isBookmarked ? "Remove bookmark" : "Bookmark this ayah")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(width: 28)
        .padding(.top, 4)
    }
}
