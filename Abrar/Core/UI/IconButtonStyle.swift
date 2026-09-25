import SwiftUI

/// Borderless circular icon button with hover and press feedback.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        IconButtonBody(configuration: configuration, size: size)
    }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var icon: IconButtonStyle { IconButtonStyle() }
    static func icon(size: CGFloat) -> IconButtonStyle { IconButtonStyle(size: size) }
}

private struct IconButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let size: CGFloat

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    private var fillOpacity: Double {
        if configuration.isPressed { return 0.16 }
        return isHovering && isEnabled ? 0.08 : 0
    }

    var body: some View {
        configuration.label
            .labelStyle(.iconOnly)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.primary.opacity(fillOpacity)))
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .onHover { isHovering = $0 }
            .motion(Motion.quick, value: isHovering)
            .motion(Motion.quick, value: configuration.isPressed)
    }
}
