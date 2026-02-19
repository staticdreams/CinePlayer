import AVFoundation

/// Manages audio and subtitle track discovery from AVPlayer, and selection state.
@Observable
@MainActor
public final class TrackState {

    // MARK: - Provided tracks (from host app)

    /// Audio tracks provided by the host app for the custom picker.
    /// When non-empty, the picker shows these instead of raw AV options.
    public var audioTracks: [any PlayerAudioTrack] = []

    /// Subtitle tracks provided by the host app.
    public var subtitleTracks: [any PlayerSubtitleTrack] = []

    // MARK: - Discovered AV options

    /// Audio options discovered from the AVMediaSelectionGroup.
    public private(set) var discoveredAudioOptions: [AVMediaSelectionOption] = []

    /// Subtitle options discovered from the AVMediaSelectionGroup.
    public private(set) var discoveredSubtitleOptions: [AVMediaSelectionOption] = []

    // MARK: - Matched tracks (protocol track + AV option)

    /// Matched audio tracks: each protocol track paired with its AV option (if found).
    public private(set) var matchedAudioTracks: [TrackMatcher.MatchedAudioTrack] = []

    // MARK: - Current selection

    /// Currently selected audio track index (in the audioTracks/matchedAudioTracks array).
    public var selectedAudioIndex: Int? {
        didSet { applyAudioSelection() }
    }

    /// Currently selected subtitle track index.
    public var selectedSubtitleIndex: Int? {
        didSet { applySubtitleSelection() }
    }

    /// Whether subtitles are turned off.
    public var subtitlesOff: Bool = true

    // MARK: - Internal

    weak var player: AVPlayer?

    public init() {}

    // MARK: - Discovery

    /// Discovers audio and subtitle tracks from the current player item's asset.
    public func discoverTracks(from playerItem: AVPlayerItem) async {
        do {
            let asset = playerItem.asset
            let mediaCharacteristics = try await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions)

            // Audio
            if mediaCharacteristics.contains(.audible),
               let group = try await asset.loadMediaSelectionGroup(for: .audible) {
                let options = Array(group.options)
                discoveredAudioOptions = options

                if !audioTracks.isEmpty {
                    matchedAudioTracks = TrackMatcher.matchAudioTracks(audioTracks, to: options)
                    // Auto-select default track.
                    if selectedAudioIndex == nil {
                        selectedAudioIndex = audioTracks.firstIndex(where: { $0.isDefault }) ?? 0
                    }
                }
            }

            // Subtitles
            if mediaCharacteristics.contains(.legible),
               let group = try await asset.loadMediaSelectionGroup(for: .legible) {
                discoveredSubtitleOptions = Array(group.options)

                // When no explicit subtitle tracks are provided, auto-generate
                // from discovered AV options (replicates AVPlayerViewController's
                // default behavior of showing all available subtitles).
                if subtitleTracks.isEmpty && !discoveredSubtitleOptions.isEmpty {
                    subtitleTracks = discoveredSubtitleOptions.enumerated().map { index, option in
                        DiscoveredSubtitleTrack(
                            id: "\(index)",
                            language: option.extendedLanguageTag
                                ?? option.locale?.language.languageCode?.identifier,
                            displayName: option.displayName,
                            isForced: option.hasMediaCharacteristic(.containsOnlyForcedSubtitles)
                        )
                    }
                }
            }
        } catch {
            // Track discovery failure is non-fatal.
            #if DEBUG
            print("[CinePlayer] Track discovery failed: \(error)")
            #endif
        }
    }

    // MARK: - Selection

    /// Selects an audio track by protocol track, finding its matched AV option.
    public func selectAudioTrack(_ track: any PlayerAudioTrack) {
        guard let index = audioTracks.firstIndex(where: { $0.id == track.id }) else { return }
        selectedAudioIndex = index
    }

    /// Selects a subtitle track by protocol track.
    public func selectSubtitleTrack(_ track: any PlayerSubtitleTrack) {
        guard let index = subtitleTracks.firstIndex(where: { $0.id == track.id }) else { return }
        selectedSubtitleIndex = index
        subtitlesOff = false
        applySubtitleSelection()
    }

    /// Turns subtitles off.
    public func disableSubtitles() {
        subtitlesOff = true
        selectedSubtitleIndex = nil
        applySubtitleOff()
    }

    // MARK: - Apply to AVPlayer

    private func applyAudioSelection() {
        guard let player, let item = player.currentItem else { return }

        Task {
            guard let group = try? await item.asset.loadMediaSelectionGroup(for: .audible) else { return }

            let option: AVMediaSelectionOption?
            if let index = selectedAudioIndex {
                if !matchedAudioTracks.isEmpty, index < matchedAudioTracks.count {
                    option = matchedAudioTracks[index].option
                } else if index < discoveredAudioOptions.count {
                    option = discoveredAudioOptions[index]
                } else {
                    option = nil
                }
            } else {
                option = nil
            }

            if let option {
                item.select(option, in: group)
            }
        }
    }

    private func applySubtitleSelection() {
        guard let player, let item = player.currentItem else { return }

        Task {
            guard let group = try? await item.asset.loadMediaSelectionGroup(for: .legible) else { return }

            if let index = selectedSubtitleIndex, index < discoveredSubtitleOptions.count {
                item.select(discoveredSubtitleOptions[index], in: group)
            }
        }
    }

    private func applySubtitleOff() {
        guard let player, let item = player.currentItem else { return }

        Task {
            guard let group = try? await item.asset.loadMediaSelectionGroup(for: .legible) else { return }
            item.select(nil, in: group)
        }
    }
}

// MARK: - Auto-generated subtitle track from AVMediaSelectionOption

/// Lightweight wrapper around a discovered AVMediaSelectionOption,
/// used when the host app doesn't supply explicit subtitle tracks.
private struct DiscoveredSubtitleTrack: PlayerSubtitleTrack {
    let id: String
    let language: String?
    let displayName: String
    let isForced: Bool
}
