import Foundation

/// Configuration for CinePlayer, set before or during playback.
public struct PlayerConfiguration: Sendable {
    /// Start playback at this position (seconds).
    public var startTime: TimeInterval = 0

    /// Automatically start playback when ready.
    public var autoPlay: Bool = true

    /// Loop the video when it reaches the end.
    public var loop: Bool = false

    /// Available playback speed options.
    public var speeds: [PlaybackSpeed] = PlaybackSpeed.standard

    /// Video display gravity.
    public var gravity: VideoGravity = .resizeAspect

    public init(
        startTime: TimeInterval = 0,
        autoPlay: Bool = true,
        loop: Bool = false,
        speeds: [PlaybackSpeed] = PlaybackSpeed.standard,
        gravity: VideoGravity = .resizeAspect
    ) {
        self.startTime = startTime
        self.autoPlay = autoPlay
        self.loop = loop
        self.speeds = speeds
        self.gravity = gravity
    }
}
