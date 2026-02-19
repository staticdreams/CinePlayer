import SwiftUI

// MARK: - Glass Circle

struct CircleGlassBackground: ViewModifier {
    var size: CGFloat = 44

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .glassCircle(size: size)
    }
}

// MARK: - Glass Pill

struct PillGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}

// MARK: - Glass Rounded Rect

struct RoundedRectGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}

// MARK: - View Extensions

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

    @ViewBuilder
    func glassCircle(size: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .circle)
        } else {
            self
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}
