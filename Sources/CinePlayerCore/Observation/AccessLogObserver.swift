import AVFoundation
import CoreMedia

/// Polls AVPlayerItemAccessLog for playback statistics.
@MainActor
final class AccessLogObserver {
    private var lastTrackInfoUpdate: Date = .distantPast
    private let trackInfoUpdateInterval: TimeInterval = 2.0

    // Cache codec/FPS once discovered — these don't change mid-playback.
    private var cachedVideoCodec: String?
    private var cachedAudioCodec: String?
    private var cachedVideoFPS: String?

    /// Collects current stats from the player item.
    ///
    /// Synchronous stats (rate, resolution, buffer, codecs) are always populated.
    /// Async stats (audio/subtitle track names) are fetched non-blocking and cached
    /// to avoid hanging when a custom resource loader (HLS interceptor) is active.
    func collectStats(from item: AVPlayerItem, player: AVPlayer) async -> PlayerStats {
        var stats = PlayerStats()

        // Network stats from access log.
        if let accessLog = item.accessLog(), let event = accessLog.events.last {
            stats.avgBitrate = PlayerStats.formatBitrate(event.averageVideoBitrate)
            stats.currentBitrate = PlayerStats.formatBitrate(event.indicatedBitrate)
            stats.observedBitrate = PlayerStats.formatBitrate(event.observedBitrate)
            stats.throughput = PlayerStats.formatBitrate(event.observedBitrateStandardDeviation)
            stats.droppedFrames = "\(event.numberOfDroppedVideoFrames)"
            stats.stallCount = "\(event.numberOfStalls)"
            stats.networkType = event.playbackType ?? "Unknown"
            if let uri = event.uri, !uri.isEmpty {
                stats.uri = (uri as NSString).lastPathComponent
            }
            stats.streamType = event.playbackSessionID != nil ? "HLS" : "Progressive"
        }

        // Buffer stats.
        if let timeRange = item.loadedTimeRanges.first?.timeRangeValue {
            let buffered = CMTimeGetSeconds(timeRange.duration)
            stats.bufferedDuration = String(format: "%.2f s", buffered)
        }

        // Playback rate (always available).
        stats.playbackRate = String(format: "%.2fx", player.rate)

        // Resolution from presentationSize.
        let size = item.presentationSize
        if size.width > 0 && size.height > 0 {
            stats.resolution = "\(Int(size.width))\u{00D7}\(Int(size.height))"
        }

        // Apply cached codec/FPS if already discovered.
        if let v = cachedVideoCodec { stats.videoCodec = v }
        if let a = cachedAudioCodec { stats.audioCodec = a }
        if let f = cachedVideoFPS { stats.videoFPS = f }

        // Codec + FPS info (throttled, expensive). Keep trying until found.
        let allFound = cachedVideoCodec != nil && cachedAudioCodec != nil && cachedVideoFPS != nil
        let now = Date()
        if !allFound && now.timeIntervalSince(lastTrackInfoUpdate) >= trackInfoUpdateInterval {
            lastTrackInfoUpdate = now
            updateCodecInfo(from: item, stats: &stats)
        }

        // Audio/subtitle track names — use cached values or try async load with timeout.
        // The async loadMediaSelectionGroup can hang when a custom AVAssetResourceLoader
        // is active (HLS interceptor), so we cache results and never block on them.
        if let cached = cachedAudioTrack {
            stats.audioTrack = cached
        }
        if let cached = cachedSubtitleTrack {
            stats.subtitleTrack = cached
        }

        if cachedAudioTrack == nil || cachedSubtitleTrack == nil {
            // Fire-and-forget: try to load track names without blocking stats return.
            let asset = item.asset
            let mediaSelection = item.currentMediaSelection
            Task { [weak self] in
                guard let self else { return }
                await self.loadTrackNames(asset: asset, mediaSelection: mediaSelection)
            }
        }

        return stats
    }

    // Cached audio/subtitle track names to avoid repeated async calls.
    private var cachedAudioTrack: String?
    private var cachedSubtitleTrack: String?

    /// Non-blocking load of audio/subtitle track display names with a timeout.
    private func loadTrackNames(asset: AVAsset, mediaSelection: AVMediaSelection) async {
        // Use a timeout to prevent hanging on custom resource loader assets.
        let result = await withTaskGroup(of: (String?, String?).self) { group in
            group.addTask {
                var audio: String?
                var subtitle: String?
                if let group = try? await asset.loadMediaSelectionGroup(for: .audible),
                   let selected = mediaSelection.selectedMediaOption(in: group) {
                    audio = selected.displayName
                }
                if let group = try? await asset.loadMediaSelectionGroup(for: .legible),
                   let selected = mediaSelection.selectedMediaOption(in: group) {
                    subtitle = selected.displayName
                } else {
                    subtitle = "Off"
                }
                return (audio, subtitle)
            }

            // Timeout task
            group.addTask {
                try? await Task.sleep(for: .seconds(2))
                return (nil, nil)
            }

            // Take whichever finishes first
            if let first = await group.next() {
                group.cancelAll()
                return first
            }
            return (nil, nil)
        }

        if let audio = result.0 {
            cachedAudioTrack = audio
        }
        if let subtitle = result.1 {
            cachedSubtitleTrack = subtitle
        }
    }

    /// Discovers codec and FPS from the player item's tracks.
    ///
    /// Uses the synchronous `AVPlayerItemTrack` API which works reliably
    /// for both local files and downloaded HLS `.movpkg` bundles.
    /// The async `AVAssetTrack.load(.formatDescriptions)` often fails
    /// for HLS content where tracks are dynamically assembled.
    @MainActor
    private func updateCodecInfo(from item: AVPlayerItem, stats: inout PlayerStats) {
        for playerTrack in item.tracks {
            guard let assetTrack = playerTrack.assetTrack else { continue }
            let mediaType = assetTrack.mediaType

            // Format descriptions are available synchronously from assetTrack.
            let formatDescriptions = assetTrack.formatDescriptions as? [CMFormatDescription] ?? []
            guard let formatDesc = formatDescriptions.first else { continue }

            let codecType = CMFormatDescriptionGetMediaSubType(formatDesc)
            let codecName = PlayerStats.fourCharCodeToString(codecType)

            if mediaType == .video {
                stats.videoCodec = codecName
                cachedVideoCodec = codecName

                if stats.resolution == "N/A" {
                    let dims = CMVideoFormatDescriptionGetDimensions(formatDesc)
                    if dims.width > 0 && dims.height > 0 {
                        stats.resolution = "\(dims.width)\u{00D7}\(dims.height)"
                    }
                }

                let fps = assetTrack.nominalFrameRate
                if fps > 0 {
                    let formatted = String(format: "%.2f fps", fps)
                    stats.videoFPS = formatted
                    cachedVideoFPS = formatted
                }
            } else if mediaType == .audio {
                stats.audioCodec = codecName
                cachedAudioCodec = codecName
            }
        }
    }
}
