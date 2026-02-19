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
            StatRow(label: "Resolution", value: stats.resolution)
            StatRow(label: "Video Codec", value: stats.videoCodec)
            StatRow(label: "Audio Codec", value: stats.audioCodec)
            StatRow(label: "Avg Bitrate", value: stats.avgBitrate)
            StatRow(label: "Cur Bitrate", value: stats.currentBitrate)
            StatRow(label: "Observed BR", value: stats.observedBitrate)
            StatRow(label: "Throughput", value: stats.throughput)
            StatRow(label: "Buffer", value: stats.bufferedDuration)
            StatRow(label: "Playback Rate", value: stats.playbackRate)
            StatRow(label: "Dropped Frames", value: stats.droppedFrames)
            StatRow(label: "Stalls", value: stats.stallCount)
            StatRow(label: "Network Type", value: stats.networkType)
        }
        .padding(8)
        .background(Color.black.opacity(0.65))
        .foregroundColor(.white)
        .cornerRadius(6)
        .fixedSize(horizontal: false, vertical: true)
        .font(.system(size: 10, design: .monospaced))
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.bold)
                .frame(width: 120, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}
