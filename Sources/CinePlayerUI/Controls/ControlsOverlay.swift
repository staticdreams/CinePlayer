import CinePlayerCore
import SwiftUI

/// Overlay combining top, center, and bottom controls with auto-hide.
/// The dim background is full-bleed; controls respect safe area insets.
struct ControlsOverlay: View {
    let engine: PlayerEngine
    let controlsVisibility: ControlsVisibility
    let title: String
    let onClose: () -> Void
    let onPiPTap: () -> Void
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void

    var body: some View {
        ZStack {
            // Tap area to toggle controls (full bleed)
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        controlsVisibility.toggle()
                    }
                }

            if controlsVisibility.isVisible {
                // Subtle dim (full bleed)
                Color.black.opacity(0.25)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                // Controls layout (respects safe area)
                VStack {
                    TopBar(
                        isMuted: engine.state.isMuted,
                        onClose: onClose,
                        onPiPTap: onPiPTap,
                        onMuteTap: {
                            engine.toggleMute()
                            controlsVisibility.resetTimer()
                        },
                        onInteraction: {
                            controlsVisibility.resetTimer()
                        }
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
                        onInteraction: {
                            controlsVisibility.resetTimer()
                        },
                        onMenuOpen: {
                            controlsVisibility.cancelTimer()
                        }
                    )
                }
                .transition(.opacity)
            }
        }
    }
}
