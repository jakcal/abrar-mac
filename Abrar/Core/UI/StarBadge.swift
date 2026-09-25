import SwiftUI

/// Eight-pointed star (two overlapping squares), the classic Quran ornament.
struct EightPointStar: InsettableShape {
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - inset
        // Where the edges of two squares at 45° cross.
        let inner = outer * cos(.pi / 4) / cos(.pi / 8)
        var path = Path()
        for index in 0..<16 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = Double(index) * .pi / 8 - .pi / 2
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> EightPointStar {
        EightPointStar(inset: inset + amount)
    }
}

/// A number set inside an eight-pointed star, used for surah numbers.
struct StarBadge: View {
    let number: Int
    var size: CGFloat = 32
    var isHighlighted = false

    var body: some View {
        ZStack {
            EightPointStar()
                .fill(isHighlighted ? AnyShapeStyle(Color.accentColor.opacity(0.18)) : AnyShapeStyle(.quaternary.opacity(0.6)))
            EightPointStar()
                .strokeBorder(isHighlighted ? AnyShapeStyle(Color.accentColor.opacity(0.6)) : AnyShapeStyle(.tertiary), lineWidth: 0.75)
            Text(number, format: .number)
                .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.7)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
