import SwiftUI

struct PrayerRowView: View {
    let time: PrayerTime
    let timeZone: TimeZone
    let isCurrent: Bool
    let isNext: Bool
    let now: Date

    var body: some View {
        HStack {
            Text(time.prayer.displayName)
                .fontWeight(isNext ? .semibold : .regular)
            if isNext {
                Text("in \(PrayerFormatting.countdown(from: now, to: time.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(PrayerFormatting.time(time.date, in: timeZone))
                .monospacedDigit()
                .fontWeight(isNext ? .semibold : .regular)
        }
        .foregroundStyle(time.prayer.isObligatory ? .primary : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(background, in: RoundedRectangle(cornerRadius: 6))
    }

    private var background: AnyShapeStyle {
        if isNext { return AnyShapeStyle(Color.accentColor.opacity(0.22)) }
        if isCurrent { return AnyShapeStyle(.quaternary) }
        return AnyShapeStyle(.clear)
    }
}
