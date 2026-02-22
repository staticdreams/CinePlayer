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

    /// Skip forward/backward interval in seconds.
    public var skipInterval: TimeInterval = 10

    /// Video display gravity.
    public var gravity: VideoGravity = .resizeAspect

    /// Localized strings for the player UI.
    public var localization: PlayerLocalization = .english

    /// Preferred maximum video resolution for quality-constrained playback.
    /// When set, AVPlayer will prefer streams at or below this resolution.
    public var preferredMaximumResolution: CGSize?

    /// Whether the subtitle font size control is shown.
    public var subtitleFontSizeEnabled: Bool = false

    /// Available subtitle font size options.
    public var subtitleFontSizes: [SubtitleFontSize] = SubtitleFontSize.standard

    public init(
        startTime: TimeInterval = 0,
        autoPlay: Bool = true,
        loop: Bool = false,
        speeds: [PlaybackSpeed] = PlaybackSpeed.standard,
        skipInterval: TimeInterval = 10,
        gravity: VideoGravity = .resizeAspect,
        localization: PlayerLocalization = .english,
        subtitleFontSizeEnabled: Bool = false,
        subtitleFontSizes: [SubtitleFontSize] = SubtitleFontSize.standard
    ) {
        self.startTime = startTime
        self.autoPlay = autoPlay
        self.loop = loop
        self.speeds = speeds
        self.skipInterval = skipInterval
        self.gravity = gravity
        self.localization = localization
        self.subtitleFontSizeEnabled = subtitleFontSizeEnabled
        self.subtitleFontSizes = subtitleFontSizes
    }
}
