import AVFoundation
import UIKit

/// UIView subclass whose layer is AVPlayerLayer.
public final class VideoSurfaceUIView: UIView {
    public override static var layerClass: AnyClass { AVPlayerLayer.self }

    public var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    public var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}
