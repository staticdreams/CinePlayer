import CinePlayerCore
import SwiftUI

/// Seekable progress bar inside a glass pill, matching Apple's native player.
/// Layout: [elapsed time] [slider track] [remaining time] all inside a single pill.
struct ProgressBar: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    let onDragChanged: (() -> Void)?

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        onSeek: @escaping (TimeInterval) -> Void,
        onDragChanged: (() -> Void)? = nil
    ) {
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
        self.onDragChanged = onDragChanged
    }

    private var displayProgress: Double {
        isDragging ? dragProgress : (duration > 0 ? currentTime / duration : 0)
    }

    private var displayCurrentTime: TimeInterval {
        isDragging ? dragProgress * duration : currentTime
    }

    private var displayRemainingTime: TimeInterval {
        duration - displayCurrentTime
    }

    private let trackHeight: CGFloat = 6
    private let thumbNormal: CGFloat = 10
    private let thumbDragging: CGFloat = 18

    var body: some View {
        HStack(spacing: 12) {
            // Elapsed time
            Text(formatTime(displayCurrentTime))
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .frame(minWidth: 56, alignment: .leading)

            // Slider track
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbX = displayProgress * width
                let currentThumbSize = isDragging ? thumbDragging : thumbNormal

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(height: trackHeight)

                    // Played portion
                    Capsule()
                        .fill(.white)
                        .frame(width: max(0, thumbX), height: trackHeight)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: currentThumbSize, height: currentThumbSize)
                        .offset(x: max(0, thumbX - currentThumbSize / 2))
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let fraction = max(0, min(1, value.location.x / width))
                            dragProgress = fraction
                            onDragChanged?()
                        }
                        .onEnded { value in
                            let fraction = max(0, min(1, value.location.x / width))
                            let seekTime = fraction * duration
                            onSeek(seekTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)

            // Remaining time (negative)
            Text("-\(formatTime(displayRemainingTime))")
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .pillGlass()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
}
