import CinePlayerCore
import SwiftUI

/// Menu-based speed picker displayed as an icon button for the options pill.
struct SpeedPicker: View {
    let speeds: [PlaybackSpeed]
    let currentRate: Float
    let onSelect: (PlaybackSpeed) -> Void

    private var currentSpeed: PlaybackSpeed {
        speeds.first(where: { abs($0.rate - currentRate) < 0.01 }) ?? .normal
    }

    private var isNonStandardRate: Bool {
        abs(currentRate - 1.0) > 0.01
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isNonStandardRate ? .orange : .white)
                .frame(width: 44, height: 36)
        }
    }
}
