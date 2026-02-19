import CinePlayerCore
import SwiftUI

/// Seekable progress bar with buffer indicator and time labels.
struct ProgressBar: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var displayProgress: Double {
        isDragging ? dragProgress : (duration > 0 ? currentTime / duration : 0)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Slider
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbX = displayProgress * width

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)

                    // Played portion
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, thumbX), height: 4)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                        .offset(x: max(0, thumbX - (isDragging ? 8 : 6)))
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let fraction = max(0, min(1, value.location.x / width))
                            dragProgress = fraction
                        }
                        .onEnded { value in
                            let fraction = max(0, min(1, value.location.x / width))
                            let seekTime = fraction * duration
                            onSeek(seekTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)

            // Time labels
            HStack {
                Text(formatTime(isDragging ? dragProgress * duration : currentTime))
                    .monospacedDigit()
                Spacer()
                Text("-\(formatTime(duration - (isDragging ? dragProgress * duration : currentTime)))")
                    .monospacedDigit()
            }
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
