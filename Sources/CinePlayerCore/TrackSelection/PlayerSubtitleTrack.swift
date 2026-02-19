import Foundation

/// Protocol for subtitle track metadata, decoupled from any app-specific types.
public protocol PlayerSubtitleTrack: Sendable, Identifiable where ID == String {
    /// Unique identifier for this track.
    var id: String { get }

    /// ISO-639 language code.
    var language: String? { get }

    /// Rich display name shown in the subtitle picker.
    var displayName: String { get }

    /// Whether this is a forced subtitle track.
    var isForced: Bool { get }
}
