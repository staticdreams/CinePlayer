import Foundation

/// All user-facing strings in CinePlayer, ready for translation.
///
/// To add a new language, create an extension file (e.g. `PlayerLocalization+uk.swift`)
/// with a `static let` providing all translated strings, then add a case
/// in ``init(languageCode:)``.
public struct PlayerLocalization: Sendable {
    // MARK: - Menu

    public var playbackSpeed: String
    public var audio: String
    public var subtitles: String
    public var playbackStats: String
    public var hideStats: String

    // MARK: - Live

    public var liveIndicator: String
    public var goLive: String

    // MARK: - Subtitle Size

    public var subtitleSize: String

    // MARK: - Pickers

    public var done: String
    public var off: String

    // MARK: - Stats Sections

    public var statsVideo: String
    public var statsAudioSubs: String
    public var statsNetwork: String

    // MARK: - External Subtitles

    public var searchOnlineSubtitles: String
    public var removeExternalSubtitles: String
    public var externalSubtitleActive: String

    // MARK: - Volume Boost

    public var volumeBoost: String

    // MARK: - Up Next

    public var upNext: String
    public var watchAgain: String

    // MARK: - Stats Labels

    public var statsResolution: String
    public var statsVideoCodec: String
    public var statsFrameRate: String
    public var statsPlaybackRate: String
    public var statsDroppedFrames: String
    public var statsAudioCodec: String
    public var statsAudioTrack: String
    public var statsSubtitle: String
    public var statsAvgBitrate: String
    public var statsCurBitrate: String
    public var statsObservedBR: String
    public var statsThroughput: String
    public var statsBuffer: String
    public var statsStalls: String
    public var statsNetworkType: String
    public var statsStreamType: String
    public var statsSource: String

    public init(
        playbackSpeed: String,
        audio: String,
        subtitles: String,
        subtitleSize: String = "Subtitle Size",
        playbackStats: String,
        hideStats: String,
        liveIndicator: String,
        goLive: String,
        done: String,
        off: String,
        searchOnlineSubtitles: String = "Search Online",
        removeExternalSubtitles: String = "Remove External",
        externalSubtitleActive: String = "External Subtitle",
        volumeBoost: String = "Volume Boost",
        upNext: String = "Up Next",
        watchAgain: String = "Watch Again",
        statsVideo: String,
        statsAudioSubs: String,
        statsNetwork: String,
        statsResolution: String,
        statsVideoCodec: String,
        statsFrameRate: String,
        statsPlaybackRate: String,
        statsDroppedFrames: String,
        statsAudioCodec: String,
        statsAudioTrack: String,
        statsSubtitle: String,
        statsAvgBitrate: String,
        statsCurBitrate: String,
        statsObservedBR: String,
        statsThroughput: String,
        statsBuffer: String,
        statsStalls: String,
        statsNetworkType: String,
        statsStreamType: String,
        statsSource: String
    ) {
        self.playbackSpeed = playbackSpeed
        self.audio = audio
        self.subtitles = subtitles
        self.subtitleSize = subtitleSize
        self.playbackStats = playbackStats
        self.hideStats = hideStats
        self.liveIndicator = liveIndicator
        self.goLive = goLive
        self.done = done
        self.off = off
        self.searchOnlineSubtitles = searchOnlineSubtitles
        self.removeExternalSubtitles = removeExternalSubtitles
        self.externalSubtitleActive = externalSubtitleActive
        self.volumeBoost = volumeBoost
        self.upNext = upNext
        self.watchAgain = watchAgain
        self.statsVideo = statsVideo
        self.statsAudioSubs = statsAudioSubs
        self.statsNetwork = statsNetwork
        self.statsResolution = statsResolution
        self.statsVideoCodec = statsVideoCodec
        self.statsFrameRate = statsFrameRate
        self.statsPlaybackRate = statsPlaybackRate
        self.statsDroppedFrames = statsDroppedFrames
        self.statsAudioCodec = statsAudioCodec
        self.statsAudioTrack = statsAudioTrack
        self.statsSubtitle = statsSubtitle
        self.statsAvgBitrate = statsAvgBitrate
        self.statsCurBitrate = statsCurBitrate
        self.statsObservedBR = statsObservedBR
        self.statsThroughput = statsThroughput
        self.statsBuffer = statsBuffer
        self.statsStalls = statsStalls
        self.statsNetworkType = statsNetworkType
        self.statsStreamType = statsStreamType
        self.statsSource = statsSource
    }

    /// Creates a localization for the given language code, falling back to English.
    public init(languageCode: String) {
        switch languageCode.lowercased().prefix(2) {
        case "ru": self = .russian
        default: self = .english
        }
    }
}
