import CinePlayerCore
import SwiftUI

/// Renders the active external subtitle cue as a text overlay at the bottom of the video.
struct ExternalSubtitleOverlay: View {
    let state: ExternalSubtitleState
    let fontSize: SubtitleFontSize

    var body: some View {
        VStack {
            Spacer()

            if let cue = state.activeCue {
                Text(cue.text)
                    .font(.system(size: scaledFontSize, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.black.opacity(0.7))
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                    .transition(.opacity)
                    .id(cue.startTime)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: state.activeCue)
        .allowsHitTesting(false)
    }

    private var scaledFontSize: CGFloat {
        let base: CGFloat = 20
        return base * CGFloat(fontSize.percentage) / 100.0
    }
}
