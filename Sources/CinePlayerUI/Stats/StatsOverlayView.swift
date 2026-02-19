import CinePlayerCore
import SwiftUI

/// Debug stats overlay showing resolution, bitrate, codec, buffer, stalls.
public struct StatsOverlayView: View {
    let stats: PlayerStats
    let localization: PlayerLocalization

    public init(stats: PlayerStats, localization: PlayerLocalization = .english) {
        self.stats = stats
        self.localization = localization
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Video
            SectionHeader(localization.statsVideo)
            StatRow(label: localization.statsResolution, value: stats.resolution)
            StatRow(label: localization.statsVideoCodec, value: stats.videoCodec)
            StatRow(label: localization.statsFrameRate, value: stats.videoFPS)
            StatRow(label: localization.statsPlaybackRate, value: stats.playbackRate)
            StatRow(label: localization.statsDroppedFrames, value: stats.droppedFrames)

            Divider().overlay(Color.white.opacity(0.2))

            // Audio & Subtitles
            SectionHeader(localization.statsAudioSubs)
            StatRow(label: localization.statsAudioCodec, value: stats.audioCodec)
            StatRow(label: localization.statsAudioTrack, value: stats.audioTrack)
            StatRow(label: localization.statsSubtitle, value: stats.subtitleTrack)

            Divider().overlay(Color.white.opacity(0.2))

            // Network
            SectionHeader(localization.statsNetwork)
            StatRow(label: localization.statsAvgBitrate, value: stats.avgBitrate)
            StatRow(label: localization.statsCurBitrate, value: stats.currentBitrate)
            StatRow(label: localization.statsObservedBR, value: stats.observedBitrate)
            StatRow(label: localization.statsThroughput, value: stats.throughput)
            StatRow(label: localization.statsBuffer, value: stats.bufferedDuration)
            StatRow(label: localization.statsStalls, value: stats.stallCount)
            StatRow(label: localization.statsNetworkType, value: stats.networkType)
            StatRow(label: localization.statsStreamType, value: stats.streamType)
            StatRow(label: localization.statsSource, value: stats.uri)
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
