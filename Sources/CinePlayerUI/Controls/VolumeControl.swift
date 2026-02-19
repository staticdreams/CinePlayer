import MediaPlayer
import SwiftUI

/// Expandable volume control: tapping the speaker icon expands to reveal a styled system volume slider.
/// The slider matches the progress bar's thin track/small thumb look. Collapses after inactivity.
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
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
          .contentTransition(.symbolEffect(.replace))
          .frame(width: 48, height: 48)
          .contentShape(Rectangle())
      }
      .circleGlass(size: 48)

      if isExpanded {
        StyledVolumeSlider()
          .frame(width: 110, height: 48)
          .padding(.trailing, 14)
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

// MARK: - Styled Volume Slider

/// UIViewRepresentable wrapping MPVolumeView with custom thumb (small circle) and track styling
/// to match the progress bar appearance. Uses manual frame layout for precise vertical centering.
private struct StyledVolumeSlider: UIViewRepresentable {
  func makeUIView(context: Context) -> StyledVolumeUIView {
    StyledVolumeUIView()
  }

  func updateUIView(_ uiView: StyledVolumeUIView, context: Context) {}
}

private final class StyledVolumeUIView: UIView {
  private let volumeView = MPVolumeView()
  private var hasStyled = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    volumeView.showsRouteButton = false
    addSubview(volumeView)
  }

  @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Manual frame centering — MPVolumeView has internal top padding that
    // pushes the visible slider track above center. Offset +4pt to compensate.
    volumeView.sizeToFit()
    let volumeHeight = volumeView.bounds.height
    volumeView.frame = CGRect(
      x: 0,
      y: (bounds.height - volumeHeight) / 2 + 8,
      width: bounds.width,
      height: volumeHeight
    )

    if !hasStyled { styleSlider() }
  }

  private func styleSlider() {
    guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
    hasStyled = true

    // Small white circle thumb matching progress bar
    let thumbImage = makeCircleImage(size: 10)
    slider.setThumbImage(thumbImage, for: .normal)
    slider.setThumbImage(thumbImage, for: .highlighted)

    // Track colors
    slider.minimumTrackTintColor = .white
    slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
  }

  private func makeCircleImage(size: CGFloat) -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
      UIColor.white.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
    }
  }
}
