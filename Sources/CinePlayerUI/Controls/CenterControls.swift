import CinePlayerCore
import SwiftUI

/// Center playback controls matching Apple's native player: glass circles with size hierarchy.
/// For live streams, skip buttons are hidden and only play/pause is shown.
struct CenterControls: View {
    let isPlaying: Bool
    let isLive: Bool
    let skipInterval: TimeInterval
    let onSkipBackward: () -> Void
    let onTogglePlayPause: () -> Void
    let onSkipForward: () -> Void

    private let playPauseSize: CGFloat = 76
    private let skipSize: CGFloat = 56

    /// SF Symbol name for the skip interval (e.g. "gobackward.10", "gobackward.15").
    private var backwardSymbol: String {
        "gobackward.\(Int(skipInterval))"
    }

    private var forwardSymbol: String {
        "goforward.\(Int(skipInterval))"
    }

    var body: some View {
        HStack(spacing: 48) {
            if !isLive {
                // Skip backward
                Button(action: onSkipBackward) {
                    Image(systemName: backwardSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .circleGlass(size: skipSize)
            }

            // Play / Pause — larger
            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .circleGlass(size: playPauseSize)

            if !isLive {
                // Skip forward
                Button(action: onSkipForward) {
                    Image(systemName: forwardSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .circleGlass(size: skipSize)
            }
        }
    }
}
