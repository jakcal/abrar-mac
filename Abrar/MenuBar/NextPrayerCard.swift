import SwiftUI

/// Hero card: the next prayer, time left, and how far we are through the wait.
struct NextPrayerCard: View {
    let next: PrayerTime
    let window: DateInterval?
    let timeZone: TimeZone
    let now: Date
    /// Close enough that the menu bar countdown has turned red.
    var isSoon = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next prayer")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .kerning(0.6)
                        .foregroundStyle(.secondary)
                    Label(next.prayer.displayName, systemImage: next.prayer.symbolName)
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)
                }
                Spacer()
                Text(next.prayer.arabicName)
                    .font(QuranFont.font(size: 22))
                    .foregroundStyle(.secondary)
            }
            countdown
            if let window {
                SkyProgress(value: PrayerSchedule.progress(of: window, at: now), colors: next.prayer.sky)
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
        let number = Font.system(size: 36, weight: .semibold, design: .rounded)
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
            .foregroundStyle(isSoon ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))
            .contentTransition(.numericText(countsDown: true))
            .motion(Motion.standard, value: left.minutes)
            Spacer()
            Text("at \(PrayerFormatting.time(next.date, in: timeZone))")
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    /// Time-of-day gradient with a faint star ornament tucked into the corner.
    private var sky: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
        return ZStack(alignment: .topTrailing) {
            LinearGradient(colors: next.prayer.sky, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(colorScheme == .dark ? 0.32 : 0.22)
            EightPointStar()
                .strokeBorder(Color.gold.opacity(colorScheme == .dark ? 0.22 : 0.3), lineWidth: 1)
                .background(EightPointStar().inset(by: 14).strokeBorder(Color.gold.opacity(0.14), lineWidth: 0.75))
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(11))
                .offset(x: 44, y: -40)
        }
        .clipShape(shape)
    }

    private var accessibilityText: String {
        let spoken = PrayerFormatting.spokenCountdown(from: now, to: next.date)
        return "\(next.prayer.displayName) in \(spoken), at \(PrayerFormatting.time(next.date, in: timeZone))"
    }
}

/// Progress through the wait, coloured like the sky it leads to, with a glowing marker for now.
private struct SkyProgress: View {
    let value: Double
    let colors: [Color]

    var body: some View {
        GeometryReader { proxy in
            let width = max(6, proxy.size.width * value)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .frame(width: width, height: 4)
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(colors.last ?? .white, lineWidth: 2))
                    .frame(width: 10, height: 10)
                    .shadow(color: (colors.last ?? .white).opacity(0.7), radius: 4)
                    .offset(x: width - 5)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 10)
        .motion(Motion.standard, value: value)
    }
}
