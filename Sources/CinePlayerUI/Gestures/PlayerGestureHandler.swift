import CinePlayerCore
import SwiftUI

/// Adds double-tap zoom and 3-finger long-press stats toggle.
struct PlayerGestureModifier: ViewModifier {
    let engine: PlayerEngine
    @Binding var showStats: Bool

    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                engine.toggleZoom()
            }
    }
}

extension View {
    func playerGestures(engine: PlayerEngine, showStats: Binding<Bool>) -> some View {
        modifier(PlayerGestureModifier(engine: engine, showStats: showStats))
    }
}

/// Adds swipe-down-to-dismiss gesture for the player.
struct SwipeToDismissModifier: ViewModifier {
    let enabled: Bool
    let onDismiss: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    func body(content: Content) -> some View {
        if enabled {
            content
                .offset(y: max(0, dragOffset))
                .opacity(dismissOpacity)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            let horizontal = abs(value.translation.width)
                            let vertical = value.translation.height

                            if !isDragging {
                                guard vertical > 0, vertical > horizontal else { return }
                                isDragging = true
                            }

                            dragOffset = max(0, value.translation.height)
                        }
                        .onEnded { value in
                            guard isDragging else { return }
                            isDragging = false

                            let velocity = value.velocity.height
                            if dragOffset > 150 || velocity > 1000 {
                                onDismiss()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
        } else {
            content
        }
    }

    private var dismissOpacity: Double {
        let maxDrag: CGFloat = 300
        return 1.0 - min(max(0, dragOffset) / maxDrag, 0.5)
    }
}

extension View {
    func swipeToDismiss(enabled: Bool, onDismiss: @escaping () -> Void) -> some View {
        modifier(SwipeToDismissModifier(enabled: enabled, onDismiss: onDismiss))
    }
}
