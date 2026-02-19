import AVFoundation
import AVKit
import CinePlayerCore

/// Manages AVPictureInPictureController lifecycle.
@Observable
@MainActor
public final class PiPManager: NSObject {
    public private(set) var isPiPActive: Bool = false
    public private(set) var isPiPPossible: Bool = false

    private var controller: AVPictureInPictureController?

    public override init() {
        super.init()
    }

    /// Configures PiP with the given player layer.
    public func configure(with playerLayer: AVPlayerLayer, canStartAutomatically: Bool = true) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        let pip = AVPictureInPictureController(playerLayer: playerLayer)
        pip?.delegate = self
        pip?.canStartPictureInPictureAutomaticallyFromInline = canStartAutomatically
        self.controller = pip
        isPiPPossible = true
    }

    /// Toggles PiP on/off.
    public func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }

    /// Tears down the PiP controller.
    public func tearDown() {
        controller?.stopPictureInPicture()
        controller = nil
        isPiPPossible = false
        isPiPActive = false
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isPiPActive = true
    }

    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        isPiPActive = false
    }

    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isPiPActive = false
        #if DEBUG
        print("[CinePlayer] PiP failed: \(error)")
        #endif
    }
}
