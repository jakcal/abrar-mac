import SwiftUI

/// App wordmark: an eight-pointed star with "Abrar" and its Arabic name.
struct BrandMark: View {
    var showsArabic = true

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                EightPointStar()
                    .fill(Color.accentColor.gradient)
                Image(systemName: "moon.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 18, height: 18)
            Text("Abrar")
                .font(.subheadline.weight(.semibold))
            if showsArabic {
                Text("أبرار")
                    .font(QuranFont.font(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Abrar")
    }
}
