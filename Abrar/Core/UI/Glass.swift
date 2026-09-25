import SwiftUI

extension View {
    /// Liquid Glass on macOS 26; a material surface with a hairline edge on earlier systems.
    func glassSurface<S: InsettableShape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassSurface(shape: shape, tint: tint, interactive: interactive))
    }

    func glassCard(cornerRadius: CGFloat = Metrics.cardRadius, tint: Color? = nil) -> some View {
        glassSurface(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint)
    }

    /// Quiet surface for cards that sit in scrolling content, where glass doesn't belong.
    func contentCard(cornerRadius: CGFloat = Metrics.cardRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(shape.fill(Color.primary.opacity(0.035)))
            .overlay(shape.strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5))
    }

    /// `.glass` / `.glassProminent` on macOS 26, bordered styles before.
    func glassButtonStyle(prominent: Bool = false) -> some View {
        modifier(GlassButton(prominent: prominent))
    }
}

/// Lets neighbouring glass shapes blend on macOS 26; a plain wrapper before.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

private struct GlassSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            content
                .background {
                    ZStack {
                        shape.fill(.regularMaterial)
                        if let tint { shape.fill(tint) }
                    }
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
                }
                .overlay { shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5) }
        }
    }
}

private struct GlassButton: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else if prominent {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}
