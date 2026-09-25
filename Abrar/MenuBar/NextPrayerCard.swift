import SwiftUI

/// Hero card: the next prayer, time left, and how far we are through the wait.
struct NextPrayerCard: View {
    let next: PrayerTime
    let window: DateInterval?
    let timeZone: TimeZone
    let now: Date

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(next.prayer.displayName, systemImage: next.prayer.symbolName)
                    .font(.headline)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                Text(next.prayer.arabicName)
                    .font(QuranFont.font(size: 20))
                    .foregroundStyle(.secondary)
            }
            countdown
            if let window {
                ProgressBar(value: PrayerSchedule.progress(of: window, at: now))
            }
        }
        .padding(16)
        .background(sky)
        .glassCard(tint: next.prayer.sky[0].opacity(colorScheme == .dark ? 0.22 : 0.12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var countdown: some View {
        let left = PrayerFormatting.remaining(from: now, to: next.date)
        let number = Font.system(size: 34, weight: .semibold, design: .rounded)
        let unit = Font.system(size: 17, weight: .medium, design: .rounded)
        return HStack(alignment: .lastTextBaseline) {
            Group {
                if left.hours > 0 {
                    Text("\(Text("\(left.hours)").font(number))\(Text("h ").font(unit))\(Text("\(left.minutes)").font(number))\(Text("m").font(unit))")
                } else {
                    Text("\(Text("\(left.minutes)").font(number))\(Text(" min").font(unit))")
                }
            }
            .monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .motion(Motion.standard, value: left.minutes)
            Spacer()
            Text(PrayerFormatting.time(next.date, in: timeZone))
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var sky: some View {
        LinearGradient(colors: next.prayer.sky, startPoint: .topLeading, endPoint: .bottomTrailing)
            .opacity(colorScheme == .dark ? 0.32 : 0.22)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }

    private var accessibilityText: String {
        let spoken = PrayerFormatting.spokenCountdown(from: now, to: next.date)
        return "\(next.prayer.displayName) in \(spoken), at \(PrayerFormatting.time(next.date, in: timeZone))"
    }
}

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: max(4, proxy.size.width * value))
            }
        }
        .frame(height: 4)
        .motion(Motion.standard, value: value)
    }
}
