import AVFoundation
import CoreMedia

/// Polls AVPlayerItemAccessLog for playback statistics.
@MainActor
final class AccessLogObserver {
    private var lastTrackInfoUpdate: Date = .distantPast
    private let trackInfoUpdateInterval: TimeInterval = 2.0

    /// Collects current stats from the player item.
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
        }

        // Buffer stats.
        if let timeRange = item.loadedTimeRanges.first?.timeRangeValue {
            let buffered = CMTimeGetSeconds(timeRange.duration)
            stats.bufferedDuration = String(format: "%.2f s", buffered)
        }

        // Playback rate.
        stats.playbackRate = String(format: "%.2fx", player.rate)

        // Resolution from presentationSize.
        let size = item.presentationSize
        if size.width > 0 && size.height > 0 {
            stats.resolution = "\(Int(size.width))\u{00D7}\(Int(size.height))"
        }

        // Codec info (throttled, expensive).
        let now = Date()
        if now.timeIntervalSince(lastTrackInfoUpdate) >= trackInfoUpdateInterval {
            lastTrackInfoUpdate = now
            await updateCodecInfo(from: item, stats: &stats)
        }

        return stats
    }

    private func updateCodecInfo(from item: AVPlayerItem, stats: inout PlayerStats) async {
        do {
            let tracks = try await item.asset.load(.tracks)
            for track in tracks {
                let mediaType = track.mediaType
                let formatDescriptions = try await track.load(.formatDescriptions)
                guard let formatDesc = formatDescriptions.first else { continue }

                let codecType = CMFormatDescriptionGetMediaSubType(formatDesc)
                let codecName = PlayerStats.fourCharCodeToString(codecType)

                if mediaType == .video {
                    stats.videoCodec = codecName
                    if stats.resolution == "N/A" {
                        let dims = CMVideoFormatDescriptionGetDimensions(formatDesc)
                        if dims.width > 0 && dims.height > 0 {
                            stats.resolution = "\(dims.width)\u{00D7}\(dims.height)"
                        }
                    }
                } else if mediaType == .audio {
                    stats.audioCodec = codecName
                }
            }
        } catch {
            // Non-fatal.
        }
    }
}
