import SwiftUI

struct PrayerRowView: View {
    let time: PrayerTime
    let timeZone: TimeZone
    let isCurrent: Bool
    let isNext: Bool
    let isMuted: Bool
    let now: Date

    private var hasPassed: Bool { time.date <= now && !isCurrent }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: time.prayer.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isNext ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 20)
            Text(time.prayer.displayName)
                .fontWeight(isNext || isCurrent ? .semibold : .regular)
            if isCurrent {
                Text("Now")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.gold.opacity(0.18)))
                    .foregroundStyle(Color.gold)
            }
            Spacer()
            if isMuted {
                Image(systemName: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .help("No notification for \(time.prayer.displayName)")
            }
            Text(PrayerFormatting.time(time.date, in: timeZone))
                .monospacedDigit()
                .fontWeight(isNext ? .semibold : .regular)
        }
        .foregroundStyle(hasPassed || !time.prayer.isObligatory ? .secondary : .primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                    .fill(Color.brand.opacity(0.14))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.brand)
                            .frame(width: 3, height: 14)
                            .padding(.leading, 3)
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isNext ? .isSelected : [])
    }
}
