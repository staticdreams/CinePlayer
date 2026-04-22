import AVFoundation
import Observation

/// Shared bridge that exposes the currently-active AVPlayer to an external
/// display scene owned by the host app. The host app is responsible for
/// implementing a `UIWindowSceneDelegate` for the
/// `.windowExternalDisplayNonInteractive` role that observes this bridge
/// and mounts an AVPlayerLayer on the external UIWindow.
///
/// `PlayerEngine` writes the current player on `activate()` and clears it on
/// `deactivate()`. The external scene delegate flips `isExternalSceneActive`
/// on scene connect/disconnect. The host app sets `isEnabled` from user
/// preferences.
@Observable
@MainActor
public final class ExternalPlayerBridge {
    public static let shared = ExternalPlayerBridge()

    /// User-configurable switch. When false, the bridge acts as if no
    /// external display is available — handoff never activates.
    public var isEnabled: Bool = true

    /// User-configurable: when true, the external window renders a live
    /// mirror of the main UI while no video is playing. When false, the
    /// external window shows a static idle view until playback starts.
    public var isLiveMirrorEnabled: Bool = true

    /// The currently active player, if any. `PlayerEngine` owns this and
    /// sets/clears it via `registerPlayer` / `unregisterPlayer`.
    public private(set) var currentPlayer: AVPlayer?

    /// True while the host app's external `UIWindowScene` is connected.
    public private(set) var isExternalSceneActive: Bool = false

    /// True when a player is handed off to the external display.
    public var isHandoffActive: Bool {
        isEnabled && isExternalSceneActive && currentPlayer != nil
    }

    private init() {}

    public func registerPlayer(_ player: AVPlayer) {
        currentPlayer = player
    }

    public func unregisterPlayer(_ player: AVPlayer) {
        if currentPlayer === player {
            currentPlayer = nil
        }
    }

    public func setExternalSceneActive(_ active: Bool) {
        isExternalSceneActive = active
    }
}
