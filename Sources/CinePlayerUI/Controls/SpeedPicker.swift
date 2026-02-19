import CinePlayerCore
import SwiftUI

/// Standalone menu-based speed picker. Can be used as an independent button
/// or its logic reused inside a parent Menu.
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
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .circleGlass(size: 40)
        }
    }
}
