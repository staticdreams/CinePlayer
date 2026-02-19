import CinePlayerCore
import SwiftUI

/// Bottom bar: portrait shows title + "..." menu + progress pill;
/// landscape shows inline audio/speed/subtitles pill + progress pill.
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

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            // Title row + options pill
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 12)

                // Options pill — audio, speed, subtitles (all inline)
                HStack(spacing: 0) {
                    if !engine.trackState.audioTracks.isEmpty {
                        Button(action: onAudioTrackTap) {
                            Image(systemName: "waveform")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // Inline speed menu
                    speedMenu

                    if !engine.trackState.subtitleTracks.isEmpty {
                        Button(action: onSubtitleTrackTap) {
                            Image(systemName: "captions.bubble")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .pillGlass()
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

    /// Inline speed picker for landscape pill and portrait menu.
    @ViewBuilder
    private var speedMenu: some View {
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
            // Cancel auto-hide when dropdown actually opens (content is instantiated).
            .onAppear { onMenuOpen() }
        } label: {
            Text(speedLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(height: 44)
                .padding(.horizontal, 12)
        }
    }

    /// Portrait-only menu content: speed submenu, audio, subtitles.
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

    private var speedLabel: String {
        let rate = currentRate
        if abs(rate - 1.0) < 0.01 { return "1x" }
        if rate == Float(Int(rate)) { return "\(Int(rate))x" }
        return String(format: "%.1fx", rate)
    }
}
