import CinePlayerCore
import SwiftUI

/// Bottom bar matching Apple's native player: title, options pill, and glass progress bar.
struct BottomBar: View {
    let engine: PlayerEngine
    let title: String
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void
    let onSeekDrag: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var hasTrackOptions: Bool {
        !engine.trackState.audioTracks.isEmpty || !engine.trackState.subtitleTracks.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title row + options
            HStack(alignment: .bottom) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 12)

                // Options: pill with speed/audio/subtitle icons or "..." menu
                optionsView
            }
            .padding(.horizontal, 16)

            // Progress bar (glass pill)
            ProgressBar(
                currentTime: engine.state.currentTime,
                duration: engine.state.duration,
                onSeek: { time in engine.seek(to: time) },
                onDragChanged: onSeekDrag
            )
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var optionsView: some View {
        if hasTrackOptions {
            // Pill with icon buttons
            HStack(spacing: 0) {
                SpeedPicker(
                    speeds: engine.configuration.speeds,
                    currentRate: engine.state.rate > 0 ? engine.state.rate : 1.0,
                    onSelect: { speed in engine.setSpeed(speed) }
                )

                if !engine.trackState.audioTracks.isEmpty {
                    Button(action: onAudioTrackTap) {
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 36)
                    }
                }

                if !engine.trackState.subtitleTracks.isEmpty {
                    Button(action: onSubtitleTrackTap) {
                        Image(systemName: "captions.bubble")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 36)
                    }
                }
            }
            .pillGlass()
        } else {
            // Just the speed picker when no tracks
            SpeedPicker(
                speeds: engine.configuration.speeds,
                currentRate: engine.state.rate > 0 ? engine.state.rate : 1.0,
                onSelect: { speed in engine.setSpeed(speed) }
            )
            .pillGlass()
        }
    }
}
