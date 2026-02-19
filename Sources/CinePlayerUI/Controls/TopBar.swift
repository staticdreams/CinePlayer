import CinePlayerCore
import SwiftUI

/// Top bar matching Apple's native player: glass close button, PiP/AirPlay pill, volume control.
struct TopBar: View {
    let onClose: () -> Void
    let onPiPTap: (() -> Void)?
    let onAirPlayTap: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: 8) {
            // Close button — circular glass
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .circleGlass(size: 40)

            // PiP + AirPlay pill
            HStack(spacing: 0) {
                if let onPiPTap {
                    Button(action: onPiPTap) {
                        Image(systemName: "pip.enter")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 36)
                    }
                }
                if let onAirPlayTap {
                    Button(action: onAirPlayTap) {
                        Image(systemName: "airplayvideo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 36)
                    }
                }
            }
            .pillGlass()

            Spacer()

            // Volume button (portrait) or volume slider pill (landscape)
            // For now, simple mute toggle — volume slider is a future enhancement
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
