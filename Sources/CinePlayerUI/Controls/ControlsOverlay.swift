import CinePlayerCore
import SwiftUI

/// Overlay combining top, center, and bottom controls with auto-hide.
/// No gradient backgrounds — uses glass material on individual controls (Apple style).
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
                // Subtle dim overlay for readability (not a gradient — uniform)
                Color.black.opacity(0.25)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                // Controls layout
                VStack {
                    TopBar(
                        onClose: onClose,
                        onPiPTap: nil,
                        onAirPlayTap: nil
                    )

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
                        title: title,
                        onAudioTrackTap: {
                            onAudioTrackTap()
                            controlsVisibility.cancelTimer()
                        },
                        onSubtitleTrackTap: {
                            onSubtitleTrackTap()
                            controlsVisibility.cancelTimer()
                        },
                        onSeekDrag: {
                            controlsVisibility.resetTimer()
                        }
                    )
                }
                .transition(.opacity)
            }
        }
    }
}
