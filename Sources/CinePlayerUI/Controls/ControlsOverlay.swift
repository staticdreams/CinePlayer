import CinePlayerCore
import SwiftUI

/// Overlay combining top, center, and bottom controls with auto-hide and gradient backgrounds.
struct ControlsOverlay: View {
    let engine: PlayerEngine
    let controlsVisibility: ControlsVisibility
    let title: String
    let onClose: () -> Void
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void

    var body: some View {
        ZStack {
            // Tap area to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        controlsVisibility.toggle()
                    }
                }

            if controlsVisibility.isVisible {
                // Top gradient
                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Bottom gradient
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
                .allowsHitTesting(false)

                // Controls
                VStack {
                    TopBar(title: title, onClose: onClose)
                    Spacer()
                    CenterControls(
                        isPlaying: engine.state.isPlaying,
                        onSkipBackward: {
                            engine.skipBackward()
                            controlsVisibility.resetTimer()
                        },
                        onTogglePlayPause: {
                            engine.togglePlayPause()
                            controlsVisibility.resetTimer()
                        },
                        onSkipForward: {
                            engine.skipForward()
                            controlsVisibility.resetTimer()
                        }
                    )
                    Spacer()
                    BottomBar(
                        engine: engine,
                        onAudioTrackTap: {
                            onAudioTrackTap()
                            controlsVisibility.cancelTimer()
                        },
                        onSubtitleTrackTap: {
                            onSubtitleTrackTap()
                            controlsVisibility.cancelTimer()
                        }
                    )
                }
                .transition(.opacity)
            }
        }
    }
}
