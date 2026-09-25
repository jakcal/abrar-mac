import SwiftUI

enum Metrics {
    static let cardRadius: CGFloat = 18
    static let rowRadius: CGFloat = 10
    static let panelWidth: CGFloat = 300
    static let readingWidth: CGFloat = 780
}

enum Motion {
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.spring(duration: 0.35, bounce: 0.08)
    static let scroll = Animation.easeInOut(duration: 0.45)
}

extension View {
    /// `animation(_:value:)` that stands down when Reduce Motion is on.
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(ReducibleAnimation(animation: animation, value: value))
    }

    /// Soft rounded fill while the pointer is over the view.
    func hoverHighlight(cornerRadius: CGFloat = Metrics.rowRadius, isActive: Bool = false) -> some View {
        modifier(HoverHighlight(cornerRadius: cornerRadius, isActive: isActive))
    }
}

private struct ReducibleAnimation<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

private struct HoverHighlight: ViewModifier {
    let cornerRadius: CGFloat
    let isActive: Bool
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(isHovering || isActive ? 0.06 : 0))
            )
            .onHover { isHovering = $0 }
            .motion(Motion.quick, value: isHovering)
    }
}
