import Foundation

/// Manages the state of externally-loaded subtitles (e.g. from OpenSubtitles).
///
/// Owns parsed cues and exposes the currently active cue based on playback time.
/// Updated by `PlayerEngine`'s time observer on each tick.
@Observable
@MainActor
public final class ExternalSubtitleState {

    /// All parsed cues, sorted by start time.
    public private(set) var cues: [WebVTTCue] = []

    /// The cue that should be displayed right now, or `nil` if none.
    public private(set) var activeCue: WebVTTCue?

    /// Whether external subtitles are loaded and active.
    public var isActive: Bool { !cues.isEmpty }

    public init() {}

    /// Parses subtitle content and stores the resulting cues.
    public func loadSubtitle(content: String) {
        cues = WebVTTParser.parse(content)
        activeCue = nil
    }

    /// Updates the active cue based on current playback time.
    /// Uses binary search for efficient lookup.
    public func updateTime(_ seconds: TimeInterval) {
        guard !cues.isEmpty else {
            if activeCue != nil { activeCue = nil }
            return
        }

        let cue = findActiveCue(at: seconds)
        if cue != activeCue {
            activeCue = cue
        }
    }

    /// Clears all external subtitle state.
    public func clear() {
        cues = []
        activeCue = nil
    }

    // MARK: - Private

    /// Binary search to find the active cue at the given time.
    private func findActiveCue(at time: TimeInterval) -> WebVTTCue? {
        // Binary search for the last cue whose startTime <= time
        var low = 0
        var high = cues.count - 1
        var candidateIndex = -1

        while low <= high {
            let mid = (low + high) / 2
            if cues[mid].startTime <= time {
                candidateIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // Check if the candidate cue is still active (time < endTime)
        guard candidateIndex >= 0, time < cues[candidateIndex].endTime else {
            return nil
        }

        return cues[candidateIndex]
    }
}
