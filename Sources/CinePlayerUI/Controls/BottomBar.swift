import CinePlayerCore
import SwiftUI

/// Bottom bar matching Apple's native player: title, "..." options menu, and glass progress bar.
struct BottomBar: View {
    let engine: PlayerEngine
    let title: String
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void
    let onInteraction: () -> Void
    let onMenuOpen: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Title row + options menu
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 12)

                // "..." menu button — reveals Speed, Audio, Subtitles
                optionsMenu
            }
            .padding(.horizontal, 16)

            // Progress bar (glass pill)
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

    @ViewBuilder
    private var optionsMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .circleGlass(size: 42)
        }
    }

    private var currentRate: Float {
        engine.state.rate > 0 ? engine.state.rate : 1.0
    }
}
