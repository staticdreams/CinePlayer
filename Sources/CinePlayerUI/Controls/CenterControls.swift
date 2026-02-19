import CinePlayerCore
import SwiftUI

/// Center playback controls matching Apple's native player: glass circles with size hierarchy.
struct CenterControls: View {
    let isPlaying: Bool
    let onSkipBackward: () -> Void
    let onTogglePlayPause: () -> Void
    let onSkipForward: () -> Void

    private let playPauseSize: CGFloat = 74
    private let skipSize: CGFloat = 54

    var body: some View {
        HStack(spacing: 48) {
            // Skip backward
            Button(action: onSkipBackward) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .circleGlass(size: skipSize)

            // Play / Pause — larger
            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .circleGlass(size: playPauseSize)

            // Skip forward
            Button(action: onSkipForward) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .circleGlass(size: skipSize)
        }
    }
}
