import AppKit
import SwiftUI

struct AyahRow: View {
    let ayah: Ayah
    let fontSize: Double
    let isRecited: Bool
    var translation: String?

    @Environment(ReaderModel.self) private var reader
    @Environment(AudioPlayerService.self) private var player
    @Environment(SettingsStore.self) private var store
    @State private var isHovering = false

    var body: some View {
        let bookmarked = reader.isBookmarked(ayah)
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(ayah.text)\u{00A0}\(Text(marker).foregroundStyle(Color.brand))")
                    .font(QuranFont.font(size: fontSize))
                    .lineSpacing(fontSize * 0.55)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                if let translation {
                    TranslationText(number: ayah.number, text: translation, fontSize: fontSize)
                }
            }
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
            Divider()
            Button("Copy Ayah", systemImage: "doc.on.doc") { copy(withTranslation: false) }
            if translation != nil {
                Button("Copy with Translation", systemImage: "doc.on.doc.fill") { copy(withTranslation: true) }
            }
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
            shape.fill(Color.brand.opacity(0.10))
                .overlay(shape.strokeBorder(Color.brand.opacity(0.28), lineWidth: 1))
        } else {
            shape.fill(Color.primary.opacity(isHovering ? 0.035 : 0))
        }
    }

    private func play() {
        guard let surah = reader.selectedSurah else { return }
        player.play(ayah: ayah.number, in: surah, reciter: Reciter.with(id: store.settings.reciterID))
    }

    /// Copies the ayah with its reference, e.g. "— Al-Baqara 2:255".
    private func copy(withTranslation: Bool) {
        var parts = [ayah.text]
        if withTranslation, let translation { parts.append(translation) }
        parts.append("— \(reader.surahName(ayah.surah)) \(ayah.surah):\(ayah.number)")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(parts.joined(separator: "\n\n"), forType: .string)
    }
}

/// English meaning under the Arabic, left to right, sized relative to the Arabic text.
private struct TranslationText: View {
    let number: Int
    let text: String
    let fontSize: Double

    var body: some View {
        Text("\(Text("\(number)").foregroundStyle(.tertiary).monospacedDigit())  \(text)")
            .font(.system(size: min(22, max(13, fontSize * 0.5))))
            .lineSpacing(3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .environment(\.layoutDirection, .leftToRight)
    }
}

/// Marks where a new juz begins inside a surah.
struct JuzDivider: View {
    let juz: Int

    var body: some View {
        HStack(spacing: 10) {
            line
            HStack(spacing: 5) {
                EightPointStar()
                    .fill(Color.gold)
                    .frame(width: 9, height: 9)
                Text("Juz \(juz)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            line
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var line: some View {
        Rectangle().fill(Color.gold.opacity(0.35)).frame(height: 0.5)
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
