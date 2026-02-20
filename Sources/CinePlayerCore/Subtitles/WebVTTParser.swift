import Foundation

/// A single subtitle cue with timing and text content.
public struct WebVTTCue: Sendable, Equatable {
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let text: String

    public init(startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

/// Parses WebVTT and SRT subtitle content into an array of cues.
///
/// Handles both formats transparently:
/// - WebVTT uses dot separators (`00:01:23.456`)
/// - SRT uses comma separators (`00:01:23,456`) and sequence numbers
public enum WebVTTParser: Sendable {

    /// Parses subtitle content (WebVTT or SRT) into sorted cues.
    public static func parse(_ content: String) -> [WebVTTCue] {
        let cleaned = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            // Remove BOM
            .replacingOccurrences(of: "\u{FEFF}", with: "")

        let blocks = cleaned.components(separatedBy: "\n\n")
        var cues: [WebVTTCue] = []

        for block in blocks {
            let lines = block.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard let cue = parseCueBlock(lines) else { continue }
            cues.append(cue)
        }

        return cues.sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Private

    private static let timecodePattern = #"(\d{1,2}:)?\d{2}:\d{2}[.,]\d{3}"#
    private static let arrowSeparator = "-->"

    private static func parseCueBlock(_ lines: [String]) -> WebVTTCue? {
        // Find the timing line (contains "-->")
        guard let timingIndex = lines.firstIndex(where: { $0.contains(arrowSeparator) }) else {
            return nil
        }

        let timingLine = lines[timingIndex]

        // Extract start and end times
        let parts = timingLine.components(separatedBy: arrowSeparator)
        guard parts.count == 2 else { return nil }

        let startString = parts[0].trimmingCharacters(in: .whitespaces)
        let endString = parts[1].trimmingCharacters(in: .whitespaces)
            // Remove position/alignment settings after the timestamp
            .components(separatedBy: " ").first ?? ""

        guard let start = parseTimestamp(startString),
              let end = parseTimestamp(endString),
              end > start else { return nil }

        // Collect text lines after the timing line
        let textLines = lines.suffix(from: timingIndex + 1)
        guard !textLines.isEmpty else { return nil }

        let rawText = textLines.joined(separator: "\n")
        let cleanText = stripHTMLTags(rawText)

        guard !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        return WebVTTCue(startTime: start, endTime: end, text: cleanText)
    }

    /// Parses a timestamp like `01:23:45.678` or `23:45,678` into seconds.
    private static func parseTimestamp(_ string: String) -> TimeInterval? {
        // Normalize comma to dot (SRT uses comma)
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        let components = normalized.components(separatedBy: ":")

        switch components.count {
        case 3:
            // HH:MM:SS.mmm
            guard let hours = Double(components[0]),
                  let minutes = Double(components[1]),
                  let seconds = Double(components[2]) else { return nil }
            return hours * 3600 + minutes * 60 + seconds

        case 2:
            // MM:SS.mmm
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else { return nil }
            return minutes * 60 + seconds

        default:
            return nil
        }
    }

    /// Strips HTML tags from subtitle text (e.g. `<b>`, `<i>`, `<u>`, `<font ...>`).
    private static func stripHTMLTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
