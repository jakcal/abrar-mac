import SwiftUI

struct SurahHeader: View {
    let surah: Surah

    @Environment(SettingsStore.self) private var store

    private var fontSize: Double { store.settings.quranFontSize }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 18) {
                titleBlock
                SurahActions(surah: surah)
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) { ornament }
            .contentCard(cornerRadius: 24)

            if let bismillah = surah.bismillah {
                Text(bismillah)
                    .font(QuranFont.font(size: fontSize))
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.bottom, 4)
            }
        }
        .padding(.bottom, 8)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("سُورَةُ \(surah.nameArabic)")
                .font(QuranFont.font(size: max(30, fontSize + 6)))
                .environment(\.layoutDirection, .rightToLeft)
            Text(surah.nameTransliterated)
                .font(.title2.weight(.semibold))
            Text(meta)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var meta: String {
        "\(surah.nameEnglish) · \(surah.revelationType) · \(surah.ayahCount) ayahs"
    }

    /// Faint star behind the title, clipped by the card.
    private var ornament: some View {
        EightPointStar()
            .stroke(Color.accentColor.opacity(0.12), lineWidth: 1)
            .frame(width: 220, height: 220)
            .offset(y: -70)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityHidden(true)
    }
}
