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

    var body: some View {
        HStack(spacing: 8) {
            // Close button — circular glass
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .circleGlass(size: 42)

            // PiP + AirPlay pill (consistent 42pt height)
            HStack(spacing: 0) {
                Button {
                    onPiPTap()
                    onInteraction()
                } label: {
                    Image(systemName: "pip.enter")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                }

                AirPlayRouteView()
                    .frame(width: 42, height: 42)
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
