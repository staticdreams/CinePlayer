import AVFoundation
import CinePlayerCore
import SwiftUI

/// UIViewRepresentable that wraps AVPlayerLayer via VideoSurfaceUIView.
struct VideoSurfaceView: UIViewRepresentable {
    let player: AVQueuePlayer
    let gravity: VideoGravity

    /// Callback providing the player layer for PiP setup.
    var onPlayerLayerReady: ((AVPlayerLayer) -> Void)?

    func makeUIView(context: Context) -> VideoSurfaceUIView {
        let view = VideoSurfaceUIView()
        view.player = player
        view.playerLayer.videoGravity = gravity.avGravity
        view.backgroundColor = .black
        onPlayerLayerReady?(view.playerLayer)
        return view
    }

    func updateUIView(_ uiView: VideoSurfaceUIView, context: Context) {
        uiView.playerLayer.videoGravity = gravity.avGravity
        if uiView.player !== player {
            uiView.player = player
        }
    }
}
