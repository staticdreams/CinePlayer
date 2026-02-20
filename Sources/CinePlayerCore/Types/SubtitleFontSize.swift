import Foundation

/// Represents a subtitle font size option as a percentage of the default size.
public struct SubtitleFontSize: Sendable, Hashable, Identifiable {
    public var id: Int { percentage }

    public let percentage: Int

    public var localizedName: String { "\(percentage)%" }

    public init(percentage: Int) {
        self.percentage = percentage
    }

    /// Standard subtitle font size options.
    public static let standard: [SubtitleFontSize] = [
        SubtitleFontSize(percentage: 75),
        SubtitleFontSize(percentage: 100),
        SubtitleFontSize(percentage: 125),
        SubtitleFontSize(percentage: 150),
        SubtitleFontSize(percentage: 200),
    ]

    public static let `default` = SubtitleFontSize(percentage: 100)
}
