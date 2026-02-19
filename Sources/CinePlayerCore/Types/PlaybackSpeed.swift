import Foundation

/// Represents a playback speed option.
public struct PlaybackSpeed: Sendable, Hashable, Identifiable {
    public var id: Float { rate }

    public let rate: Float
    public let localizedName: String

    public init(rate: Float, localizedName: String) {
        self.rate = rate
        self.localizedName = localizedName
    }

    /// Standard playback speed options.
    public static let standard: [PlaybackSpeed] = [
        PlaybackSpeed(rate: 0.5, localizedName: "0.5x"),
        PlaybackSpeed(rate: 0.75, localizedName: "0.75x"),
        PlaybackSpeed(rate: 1.0, localizedName: "1x"),
        PlaybackSpeed(rate: 1.25, localizedName: "1.25x"),
        PlaybackSpeed(rate: 1.5, localizedName: "1.5x"),
        PlaybackSpeed(rate: 1.75, localizedName: "1.75x"),
        PlaybackSpeed(rate: 2.0, localizedName: "2x"),
    ]

    public static let normal = PlaybackSpeed(rate: 1.0, localizedName: "1x")
}
