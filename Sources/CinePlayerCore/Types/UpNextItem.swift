import Foundation

/// Metadata for the "Coming Up Next" banner overlay.
/// Generic — knows nothing about Video/Season/MediaItem.
public struct UpNextItem: Sendable {
    /// Display title for the next item (e.g. "S01E05: Episode Title").
    public let title: String

    /// Thumbnail URL for the next item's preview image.
    public let thumbnailURL: URL?

    /// How many seconds before the end to show the banner (default 30).
    public let countdownDuration: TimeInterval

    public init(
        title: String,
        thumbnailURL: URL? = nil,
        countdownDuration: TimeInterval = 30
    ) {
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.countdownDuration = countdownDuration
    }
}
