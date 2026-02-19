import SwiftUI

/// Reusable glass background modifiers matching Apple's native video player style.

struct CircleGlassBackground: ViewModifier {
    var size: CGFloat = 44

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
    }
}

struct PillGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
    }
}

struct RoundedRectGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func circleGlass(size: CGFloat = 44) -> some View {
        modifier(CircleGlassBackground(size: size))
    }

    func pillGlass() -> some View {
        modifier(PillGlassBackground())
    }

    func roundedGlass(cornerRadius: CGFloat = 12) -> some View {
        modifier(RoundedRectGlassBackground(cornerRadius: cornerRadius))
    }
}
