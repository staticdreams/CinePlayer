import Foundation

/// Playback statistics collected from AVPlayerItemAccessLog.
public struct PlayerStats: Sendable {
    public var resolution: String = "N/A"
    public var avgBitrate: String = "N/A"
    public var currentBitrate: String = "N/A"
    public var observedBitrate: String = "N/A"
    public var throughput: String = "N/A"
    public var bufferedDuration: String = "N/A"
    public var droppedFrames: String = "N/A"
    public var videoCodec: String = "N/A"
    public var audioCodec: String = "N/A"
    public var playbackRate: String = "N/A"
    public var networkType: String = "N/A"
    public var stallCount: String = "N/A"

    public init() {}

    /// Formats a bitrate value (in bps) to a human-readable string.
    public static func formatBitrate(_ bps: Double) -> String {
        guard bps > 0 else { return "N/A" }
        if bps >= 1_000_000 {
            return String(format: "%.1f Mbps", bps / 1_000_000)
        } else if bps >= 1_000 {
            return String(format: "%.1f kbps", bps / 1_000)
        } else {
            return String(format: "%.0f bps", bps)
        }
    }

    /// Converts a FourCharCode to its string representation.
    public static func fourCharCodeToString(_ code: FourCharCode) -> String {
        let chars: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF),
        ]
        let str = String(bytes: chars, encoding: .ascii) ?? String(code)
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        let printable = CharacterSet.alphanumerics.union(.punctuationCharacters)
        if trimmed.unicodeScalars.allSatisfy({ printable.contains($0) }) {
            return trimmed
        }
        return String(code)
    }
}
