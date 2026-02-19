import CinePlayerCore
import SwiftUI

/// Bottom bar: portrait shows title + "..." menu + progress pill;
/// landscape shows everything in one large glass pill with inline option buttons (Apple-style).
struct BottomBar: View {
    let engine: PlayerEngine
    let title: String
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void
    let onInteraction: () -> Void
    let onMenuOpen: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        if isLandscape {
            landscapeLayout
        } else {
            portraitLayout
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 8) {
            // Title row + "..." glass circle menu
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 12)

                portraitMenu
            }
            .padding(.horizontal, 16)

            // Progress bar (own glass pill)
            ProgressBar(
                currentTime: engine.state.currentTime,
                duration: engine.state.duration,
                onSeek: { time in engine.seek(to: time) },
                onDragChanged: onInteraction
            )
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Landscape Layout (single glass pill)

    private var landscapeLayout: some View {
        VStack(spacing: 6) {
            // Title row + inline option buttons
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                HStack(spacing: 12) {
                    if !engine.trackState.audioTracks.isEmpty {
                        Button(action: onAudioTrackTap) {
                            Image(systemName: "waveform")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                        }
                    }

                    if !engine.trackState.subtitleTracks.isEmpty {
                        Button(action: onSubtitleTrackTap) {
                            Image(systemName: "captions.bubble")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                        }
                    }

                    landscapeMenu
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            // Embedded progress bar (no own glass pill)
            ProgressBar(
                currentTime: engine.state.currentTime,
                duration: engine.state.duration,
                onSeek: { time in engine.seek(to: time) },
                onDragChanged: onInteraction,
                embedded: true
            )
        }
        .padding(.vertical, 8)
        .roundedGlass(cornerRadius: 16)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Menus

    /// Portrait: "..." in a glass circle button.
    @ViewBuilder
    private var portraitMenu: some View {
        Menu {
            menuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .circleGlass(size: 48)
        }
    }

    /// Landscape: "..." as a plain icon (already inside the glass pill).
    @ViewBuilder
    private var landscapeMenu: some View {
        Menu {
            menuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
        }
    }

    /// Shared menu content: speed submenu, audio, subtitles.
    @ViewBuilder
    private var menuContent: some View {
        // Playback Speed submenu
        Menu {
            ForEach(engine.configuration.speeds) { speed in
                Button {
                    engine.setSpeed(speed)
                    onInteraction()
                } label: {
                    HStack {
                        Text(speed.localizedName)
                        if abs(speed.rate - currentRate) < 0.01 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Playback Speed", systemImage: "gauge.with.dots.needle.33percent")
        }
        // Cancel auto-hide when menu content appears (i.e. menu opened).
        .onAppear { onMenuOpen() }

        // Audio track
        if !engine.trackState.audioTracks.isEmpty {
            Button(action: onAudioTrackTap) {
                Label("Audio", systemImage: "waveform")
            }
        }

        // Subtitles
        if !engine.trackState.subtitleTracks.isEmpty {
            Button(action: onSubtitleTrackTap) {
                Label("Subtitles", systemImage: "captions.bubble")
            }
        }
    }

    private var currentRate: Float {
        engine.state.rate > 0 ? engine.state.rate : 1.0
    }
}
