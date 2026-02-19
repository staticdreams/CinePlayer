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
