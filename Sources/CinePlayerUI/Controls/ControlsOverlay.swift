import CinePlayerCore
import SwiftUI

/// Overlay combining top, center, and bottom controls with auto-hide.
/// The dim background is full-bleed; controls respect safe area insets.
struct ControlsOverlay: View {
    let engine: PlayerEngine
    let controlsVisibility: ControlsVisibility
    let isLandscape: Bool
    let titleInfo: PlayerTitleInfo
    let localization: PlayerLocalization
    let showingStats: Bool
    let onClose: () -> Void
    let onPiPTap: () -> Void
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void
    let onStatsTap: () -> Void
    let onNextEpisode: (() -> Void)?

    var body: some View {
        ZStack {
            if controlsVisibility.isVisible {
                // Dim background — tap empty areas to hide controls.
                // Buttons in the VStack above take tap priority.
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture(count: 2) {
                        engine.toggleZoom()
                        controlsVisibility.resetTimer()
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            controlsVisibility.hide()
                        }
                    }

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
                        isLoading: engine.state.status == .unknown,
                        isLive: engine.state.isLive,
                        skipInterval: engine.configuration.skipInterval,
                        onSkipBackward: {
                            engine.skipBackward(engine.configuration.skipInterval)
                            controlsVisibility.resetTimer()
                        },
                        onTogglePlayPause: {
                            engine.togglePlayPause()
                            controlsVisibility.resetTimer()
                        },
                        onSkipForward: {
                            engine.skipForward(engine.configuration.skipInterval)
                            controlsVisibility.resetTimer()
                        }
                    )
                    .offset(y: 14)

                    Spacer()

                    BottomBar(
                        engine: engine,
                        isLandscape: isLandscape,
                        titleInfo: titleInfo,
                        localization: localization,
                        showingStats: showingStats,
                        onAudioTrackTap: {
                            onAudioTrackTap()
                            controlsVisibility.cancelTimer()
                        },
                        onSubtitleTrackTap: {
                            onSubtitleTrackTap()
                            controlsVisibility.cancelTimer()
                        },
                        onStatsTap: {
                            onStatsTap()
                            controlsVisibility.resetTimer()
                        },
                        onInteraction: {
                            controlsVisibility.resetTimer()
                        },
                        onMenuOpen: {
                            controlsVisibility.cancelTimer()
                        },
                        onNextEpisode: onNextEpisode.map { callback in
                            {
                                callback()
                                controlsVisibility.resetTimer()
                            }
                        }
                    )
                }
                .transition(.opacity)
            } else {
                // Controls hidden — tap anywhere to show them.
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        engine.toggleZoom()
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            controlsVisibility.show()
                        }
                    }
            }
        }
    }
}
