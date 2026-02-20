import CinePlayerCore
import SwiftUI

/// Bottom bar: portrait shows title + "..." menu + progress pill;
/// landscape shows inline audio/speed/subtitles pill + progress pill.
/// For live streams, the progress bar is replaced with a LIVE indicator + "Go Live" button.
struct BottomBar: View {
    let engine: PlayerEngine
    let isLandscape: Bool
    let titleInfo: PlayerTitleInfo
    let localization: PlayerLocalization
    let showingStats: Bool
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void
    let onStatsTap: () -> Void
    let onInteraction: () -> Void
    let onMenuOpen: () -> Void

    private var isLive: Bool {
        engine.state.isLive
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
                titleView(fontSize: 18)

                Spacer(minLength: 12)

                portraitMenu
            }
            .padding(.horizontal, 16)

            if isLive {
                liveBar
                    .padding(.horizontal, 12)
            } else {
                // Progress bar (own glass pill)
                ProgressBar(
                    currentTime: engine.state.currentTime,
                    duration: engine.state.duration,
                    onSeek: { time in engine.seek(to: time) },
                    onDragChanged: onInteraction
                )
                .padding(.horizontal, 12)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            // Title row + options pill
            HStack(alignment: .bottom) {
                titleView(fontSize: 16)

                Spacer(minLength: 12)

                // Options pill — audio, speed (hidden for live), subtitles, stats (all inline)
                HStack(spacing: 0) {
                    if !engine.trackState.audioTracks.isEmpty {
                        Button(action: onAudioTrackTap) {
                            Image(systemName: "waveform")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                    }

                    if !isLive {
                        // Inline speed menu
                        speedMenu
                    }

                    if !engine.trackState.subtitleTracks.isEmpty {
                        Button(action: onSubtitleTrackTap) {
                            Image(systemName: "captions.bubble")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                    }

                    if engine.configuration.subtitleFontSizeEnabled && !engine.trackState.subtitlesOff {
                        subtitleSizeMenu
                    }

                    Button(action: onStatsTap) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(showingStats ? .blue : .white)
                            .frame(width: 44, height: 44)
                    }
                }
                .pillGlass()
            }
            .padding(.horizontal, 16)

            if isLive {
                liveBar
                    .padding(.horizontal, 12)
            } else {
                // Progress bar (own glass pill)
                ProgressBar(
                    currentTime: engine.state.currentTime,
                    duration: engine.state.duration,
                    onSeek: { time in engine.seek(to: time) },
                    onDragChanged: onInteraction
                )
                .padding(.horizontal, 12)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Title

    @ViewBuilder
    private func titleView(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleInfo.title)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            if let original = titleInfo.subtitle, !original.isEmpty {
                Text(original)
                    .font(.system(size: fontSize - 4, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            if !titleInfo.metadata.isEmpty {
                Text(titleInfo.metadata.joined(separator: " · "))
                    .font(.system(size: fontSize - 6, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
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

    /// Inline subtitle font size picker for landscape pill.
    @ViewBuilder
    private var subtitleSizeMenu: some View {
        Menu {
            ForEach(engine.configuration.subtitleFontSizes) { size in
                Button {
                    engine.subtitleFontSize = size
                    onInteraction()
                } label: {
                    HStack {
                        Text(size.localizedName)
                        if size == engine.subtitleFontSize {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .onAppear { onMenuOpen() }
        } label: {
            Text(subtitleSizeLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(height: 44)
                .padding(.horizontal, 12)
        }
    }

    /// Portrait-only menu content: speed submenu (hidden for live), audio, subtitles.
    @ViewBuilder
    private var menuContent: some View {
        if !isLive {
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
                Label(localization.playbackSpeed, systemImage: "gauge.with.dots.needle.33percent")
            }
            // Cancel auto-hide when menu content appears (i.e. menu opened).
            .onAppear { onMenuOpen() }
        }

        // Audio track
        if !engine.trackState.audioTracks.isEmpty {
            Button(action: onAudioTrackTap) {
                Label(localization.audio, systemImage: "waveform")
            }
        }

        // Subtitles
        if !engine.trackState.subtitleTracks.isEmpty {
            Button(action: onSubtitleTrackTap) {
                Label(localization.subtitles, systemImage: "captions.bubble")
            }
        }

        // Subtitle font size submenu
        if engine.configuration.subtitleFontSizeEnabled && !engine.trackState.subtitlesOff {
            Menu {
                ForEach(engine.configuration.subtitleFontSizes) { size in
                    Button {
                        engine.subtitleFontSize = size
                        onInteraction()
                    } label: {
                        HStack {
                            Text(size.localizedName)
                            if size == engine.subtitleFontSize {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(localization.subtitleSize, systemImage: "textformat.size")
            }
        }

        Divider()

        // Stats toggle
        Button(action: onStatsTap) {
            Label(
                showingStats ? localization.hideStats : localization.playbackStats,
                systemImage: "chart.bar.xaxis"
            )
        }
    }

    // MARK: - Live Bar

    /// Replaces the progress bar for live streams: red "LIVE" indicator + "Go Live" button.
    private var liveBar: some View {
        HStack(spacing: 12) {
            // Red LIVE indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text(localization.liveIndicator)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // "Go Live" button — seeks to live edge
            Button {
                engine.seekToLiveEdge()
                onInteraction()
            } label: {
                Text(localization.goLive)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .pillGlass()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .pillGlass()
    }

    private var currentRate: Float {
        engine.state.rate > 0 ? engine.state.rate : 1.0
    }

    private var subtitleSizeLabel: String {
        "\(engine.subtitleFontSize.percentage)%"
    }

    private var speedLabel: String {
        let rate = currentRate
        if abs(rate - 1.0) < 0.01 { return "1x" }
        if rate == Float(Int(rate)) { return "\(Int(rate))x" }
        return String(format: "%.1fx", rate)
    }
}
