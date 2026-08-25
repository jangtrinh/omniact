import SwiftUI

// MARK: - Apple Liquid Glass System (macOS & iOS 27)

public struct OmniGlassBackdrop: View {
    public var cornerRadius: CGFloat
    public var borderOpacity: Double

    public init(cornerRadius: CGFloat = 18, borderOpacity: Double = 0.35) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
    }

    public var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
            Color.black.opacity(0.14)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.white.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(borderOpacity),
                            Color.white.opacity(0.08),
                            Color.white.opacity(borderOpacity * 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
    }
}

public struct OmniGlassSurfaceModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var fallbackOpacity: Double
    public var interactive: Bool

    public init(cornerRadius: CGFloat = 16, fallbackOpacity: Double = 0.10, interactive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.fallbackOpacity = fallbackOpacity
        self.interactive = interactive
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(fallbackOpacity))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(interactive ? 0.22 : 0.12), lineWidth: 0.8)
            )
    }
}

public struct OmniGlassButtonModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var prominent: Bool

    public init(cornerRadius: CGFloat = 12, prominent: Bool = false) {
        self.cornerRadius = cornerRadius
        self.prominent = prominent
    }

    public func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(prominent ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.08))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(prominent ? 0.4 : 0.15), lineWidth: 0.8)
            )
    }
}

public extension View {
    func omniGlassSurface(
        cornerRadius: CGFloat = 16,
        fallbackOpacity: Double = 0.10,
        interactive: Bool = false
    ) -> some View {
        self.modifier(OmniGlassSurfaceModifier(
            cornerRadius: cornerRadius,
            fallbackOpacity: fallbackOpacity,
            interactive: interactive
        ))
    }

    func omniGlassButton(cornerRadius: CGFloat = 12, prominent: Bool = false) -> some View {
        self.modifier(OmniGlassButtonModifier(cornerRadius: cornerRadius, prominent: prominent))
    }

    func appleLiquidGlass(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.3) -> some View {
        self.background(OmniGlassBackdrop(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
            .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 10)
    }
}

// MARK: - VisualEffectBlur Component
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
