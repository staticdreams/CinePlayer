import CinePlayerCore
import SwiftUI

/// Top bar matching Apple's native player layout.
/// Left: close button + PiP/AirPlay pill.
/// Right: expandable volume control.
struct TopBar: View {
    let isMuted: Bool
    let onClose: () -> Void
    let onPiPTap: () -> Void
    let onMuteTap: () -> Void
    let onInteraction: () -> Void

    private let buttonSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 8) {
            // Close button — circular glass
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .circleGlass(size: buttonSize)

            // PiP + AirPlay pill (consistent height)
            HStack(spacing: 0) {
                Button {
                    onPiPTap()
                    onInteraction()
                } label: {
                    Image(systemName: "pip.enter")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: buttonSize, height: buttonSize)
                }

                AirPlayRouteView()
                    .scaleEffect(0.7)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .pillGlass()

            Spacer()

            // Expandable volume control
            VolumeControl(
                isMuted: isMuted,
                onMuteTap: onMuteTap,
                onInteraction: onInteraction
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
