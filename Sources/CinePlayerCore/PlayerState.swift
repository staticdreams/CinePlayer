import Foundation

/// Value type representing the current playback state.
/// PlayerEngine owns this and SwiftUI reads it via @Observable.
public struct PlayerState: Sendable {
    /// Current playback position in seconds.
    public var currentTime: TimeInterval = 0

    /// Total duration of the current item in seconds (0 if unknown/live).
    public var duration: TimeInterval = 0

    /// Whether the player is currently playing.
    public var isPlaying: Bool = false

    /// Whether the player is currently buffering/loading.
    public var isBuffering: Bool = false

    /// Whether the current item has finished playing.
    public var didFinishPlaying: Bool = false

    /// Current playback rate.
    public var rate: Float = 0

    /// Player item status.
    public var status: ItemStatus = .unknown

    /// Last error, if any.
    public var error: PlayerError?

    public init() {}

    /// Progress as a fraction (0...1). Returns 0 if duration is unknown.
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    /// Remaining time in seconds.
    public var remainingTime: TimeInterval {
        max(duration - currentTime, 0)
    }

    public enum ItemStatus: Sendable {
        case unknown
        case readyToPlay
        case failed
    }
}
