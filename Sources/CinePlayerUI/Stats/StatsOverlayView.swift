import CinePlayerCore
import SwiftUI

/// Debug stats overlay showing resolution, bitrate, codec, buffer, stalls.
public struct StatsOverlayView: View {
    let stats: PlayerStats

    public init(stats: PlayerStats) {
        self.stats = stats
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Video
            SectionHeader("VIDEO")
            StatRow(label: "Resolution", value: stats.resolution)
            StatRow(label: "Video Codec", value: stats.videoCodec)
            StatRow(label: "Frame Rate", value: stats.videoFPS)
            StatRow(label: "Playback Rate", value: stats.playbackRate)
            StatRow(label: "Dropped Frames", value: stats.droppedFrames)

            Divider().overlay(Color.white.opacity(0.2))

            // Audio & Subtitles
            SectionHeader("AUDIO / SUBS")
            StatRow(label: "Audio Codec", value: stats.audioCodec)
            StatRow(label: "Audio Track", value: stats.audioTrack)
            StatRow(label: "Subtitle", value: stats.subtitleTrack)

            Divider().overlay(Color.white.opacity(0.2))

            // Network
            SectionHeader("NETWORK")
            StatRow(label: "Avg Bitrate", value: stats.avgBitrate)
            StatRow(label: "Cur Bitrate", value: stats.currentBitrate)
            StatRow(label: "Observed BR", value: stats.observedBitrate)
            StatRow(label: "Throughput", value: stats.throughput)
            StatRow(label: "Buffer", value: stats.bufferedDuration)
            StatRow(label: "Stalls", value: stats.stallCount)
            StatRow(label: "Network Type", value: stats.networkType)
            StatRow(label: "Stream Type", value: stats.streamType)
            StatRow(label: "Source", value: stats.uri)
        }
        .padding(10)
        .background(Color.black.opacity(0.7))
        .foregroundColor(.white)
        .cornerRadius(8)
        .fixedSize(horizontal: false, vertical: true)
        .font(.system(size: 10, design: .monospaced))
    }
}

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 2)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.bold)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
    }
}
