import AVFoundation
import CinePlayerCore
import SwiftUI

/// UIViewRepresentable that wraps AVPlayerLayer via VideoSurfaceUIView.
struct VideoSurfaceView: UIViewRepresentable {
    let player: AVQueuePlayer
    let gravity: VideoGravity

    /// Callback providing the player layer (called once after the view is created).
    var onPlayerLayerReady: ((AVPlayerLayer) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> VideoSurfaceUIView {
        let view = VideoSurfaceUIView()
        view.player = player
        view.playerLayer.videoGravity = gravity.avGravity
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: VideoSurfaceUIView, context: Context) {
        uiView.playerLayer.videoGravity = gravity.avGravity
        if uiView.player !== player {
            uiView.player = player
        }
        // Notify once when the player layer is ready (first update cycle).
        if !context.coordinator.didNotifyLayer {
            context.coordinator.didNotifyLayer = true
            onPlayerLayerReady?(uiView.playerLayer)
        }
    }

    final class Coordinator {
        var didNotifyLayer = false
    }
}
