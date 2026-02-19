import MediaPlayer
import SwiftUI

/// Expandable volume control: tapping the speaker icon expands to reveal a system volume slider.
/// Collapses back to a circle after inactivity.
struct VolumeControl: View {
    let isMuted: Bool
    let onMuteTap: () -> Void
    let onInteraction: () -> Void

    @State private var isExpanded = false
    @State private var collapseTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 0) {
            // Speaker icon — tap to expand or toggle mute
            Button {
                if isExpanded {
                    onMuteTap()
                    onInteraction()
                    scheduleCollapse()
                } else {
                    isExpanded = true
                    onInteraction()
                    scheduleCollapse()
                }
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 42, height: 42)
            }

            if isExpanded {
                SystemVolumeSlider()
                    .frame(width: 100, height: 30)
                    .padding(.trailing, 12)
                    .transition(.opacity)
            }
        }
        .pillGlass()
        .animation(.spring(duration: 0.3, bounce: 0.15), value: isExpanded)
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            isExpanded = false
        }
    }
}

// MARK: - System Volume Slider (MPVolumeView)

/// Wraps MPVolumeView to provide a system volume slider without the AirPlay route button.
private struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsRouteButton = false
        volumeView.tintColor = .white
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
