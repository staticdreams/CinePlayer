import CinePlayerCore
import SwiftUI

/// Menu-based speed picker button.
struct SpeedPicker: View {
    let speeds: [PlaybackSpeed]
    let currentRate: Float
    let onSelect: (PlaybackSpeed) -> Void

    private var currentSpeed: PlaybackSpeed {
        speeds.first(where: { abs($0.rate - currentRate) < 0.01 }) ?? .normal
    }

    var body: some View {
        Menu {
            ForEach(speeds) { speed in
                Button {
                    onSelect(speed)
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
            Text(currentSpeed.localizedName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15), in: Capsule())
        }
    }
}
