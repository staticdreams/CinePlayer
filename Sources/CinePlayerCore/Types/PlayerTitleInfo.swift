import Foundation

/// Rich title metadata for display in the player controls.
///
/// Renders as up to three lines:
/// - **Line 1** (`title`): Primary title, bold, largest font.
/// - **Line 2** (`subtitle`): Secondary line, medium weight, slightly smaller. Hidden when nil/empty.
/// - **Line 3** (`metadata`): Tertiary detail line, regular weight, smallest. Components joined with " · ".
///
/// Usage:
/// ```swift
/// // Simple — single line
/// CinePlayerView(url: url).title("My Movie")
///
/// // Rich — all three lines
/// CinePlayerView(url: url).titleInfo(PlayerTitleInfo(
///     title: "My Movie",
///     subtitle: "Original Title",
///     metadata: ["S1E5", "2024", "Drama"]
/// ))
/// ```
public struct PlayerTitleInfo: Sendable {
    /// Primary title (line 1). Always shown.
    public let title: String

    /// Secondary title (line 2). Shown below the primary title in a smaller font.
    /// Pass nil or empty string to hide this line.
    public let subtitle: String?

    /// Metadata components (line 3). Joined with " · " separator.
    /// Pass an empty array to hide this line.
    public let metadata: [String]

    public init(
        title: String,
        subtitle: String? = nil,
        metadata: [String] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata.filter { !$0.isEmpty }
    }

    /// Convenience: create from a plain string (single-line title).
    public init(_ title: String) {
        self.title = title
        self.subtitle = nil
        self.metadata = []
    }
}
