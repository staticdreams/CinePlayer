import CinePlayerCore
import SwiftUI

/// Center controls: skip backward, play/pause, skip forward.
struct CenterControls: View {
    let isPlaying: Bool
    let onSkipBackward: () -> Void
    let onTogglePlayPause: () -> Void
    let onSkipForward: () -> Void

    var body: some View {
        HStack(spacing: 56) {
            Button(action: onSkipBackward) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
            }

            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())
            }

            Button(action: onSkipForward) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
            }
        }
    }
}
