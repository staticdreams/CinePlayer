import CinePlayerCore
import SwiftUI

/// Bottom bar: progress bar, speed picker, track picker buttons.
struct BottomBar: View {
    let engine: PlayerEngine
    let onAudioTrackTap: () -> Void
    let onSubtitleTrackTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ProgressBar(
                currentTime: engine.state.currentTime,
                duration: engine.state.duration,
                onSeek: { time in
                    engine.seek(to: time)
                }
            )

            HStack(spacing: 12) {
                SpeedPicker(
                    speeds: engine.configuration.speeds,
                    currentRate: engine.state.rate > 0 ? engine.state.rate : 1.0,
                    onSelect: { speed in
                        engine.setSpeed(speed)
                    }
                )

                Spacer()

                // Audio track button (only if tracks are available)
                if !engine.trackState.audioTracks.isEmpty {
                    Button(action: onAudioTrackTap) {
                        Label("Audio", systemImage: "waveform")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                }

                // Subtitle button (only if tracks are available)
                if !engine.trackState.subtitleTracks.isEmpty {
                    Button(action: onSubtitleTrackTap) {
                        Label("CC", systemImage: "captions.bubble")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
