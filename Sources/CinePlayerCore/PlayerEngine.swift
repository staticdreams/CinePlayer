import AVFoundation
import Combine

/// The core player engine. Owns AVPlayer, manages lifecycle, observers, and state.
///
/// Usage:
/// 1. Create with a URL and optional configuration.
/// 2. Call `activate()` when the view appears.
/// 3. Call `deactivate()` when the view disappears.
@Observable
@MainActor
public final class PlayerEngine {

    // MARK: - Public state

    /// Current playback state (read by SwiftUI views).
    public private(set) var state = PlayerState()

    /// Configuration (startTime, loop, speeds, gravity).
    public var configuration: PlayerConfiguration

    /// Track discovery and selection state.
    public let trackState = TrackState()

    /// External subtitle state (for sideloaded subtitles from OpenSubtitles, etc.).
    public let externalSubtitleState = ExternalSubtitleState()

    /// Playback statistics (populated when stats overlay is shown).
    public private(set) var stats = PlayerStats()

    /// Whether the stats overlay should collect data.
    public var isCollectingStats: Bool = false

    /// Current subtitle font size (applied via AVTextStyleRule).
    public var subtitleFontSize: SubtitleFontSize = .default {
        didSet { applySubtitleFontSize() }
    }

    // MARK: - Up Next

    /// Set by the host app to show the "Coming Up Next" banner.
    public var upNextItem: UpNextItem?

    /// Whether the user has dismissed the up-next banner for the current item.
    public private(set) var upNextDismissed: Bool = false

    /// Called when the next item should start playing (tap or countdown expiry).
    public var onPlayNext: (() -> Void)?

    /// Called when the user explicitly dismisses the up-next banner.
    public var onDismissNext: (() -> Void)?

    /// Whether the up-next banner should be visible right now.
    public var isUpNextVisible: Bool {
        guard let item = upNextItem,
              !upNextDismissed,
              !state.isLive,
              !configuration.loop,
              state.duration > item.countdownDuration,
              state.remainingTime <= item.countdownDuration,
              state.remainingTime > 0
        else { return false }
        return true
    }

    /// Countdown seconds remaining, clamped to [0, countdownDuration].
    public var upNextCountdown: TimeInterval {
        guard let item = upNextItem else { return 0 }
        return min(max(state.remainingTime, 0), item.countdownDuration)
    }

    // MARK: - Internal

    /// The underlying AVPlayer (exposed for VideoSurfaceView).
    public private(set) var player: AVQueuePlayer

    /// The current video URL.
    public private(set) var url: URL

    // MARK: - Callbacks

    /// Called on each time observer tick with (currentTime, duration).
    public var onProgressUpdate: ((TimeInterval, TimeInterval) -> Void)?

    /// Called when playback reaches the end.
    public var onPlaybackEnd: (() -> Void)?

    // MARK: - Private

    private var timeObserver: TimeObserver?
    private var itemObserver: PlayerItemObserver?
    private var accessLogObserver: AccessLogObserver?
    private var rateObservation: NSKeyValueObservation?
    private var currentItemObservation: NSKeyValueObservation?
    private var hasPerformedInitialSeek = false
    private var isActivated = false

    /// Holds a strong reference to the HLS manifest interceptor (must stay alive while playing).
    private var hlsInterceptor: HLSManifestInterceptor?
    private var hlsResourceLoaderQueue: DispatchQueue?

    // MARK: - Init

    public init(url: URL, configuration: PlayerConfiguration = PlayerConfiguration()) {
        self.url = url
        self.configuration = configuration
        self.player = AVQueuePlayer()
    }

    // MARK: - Lifecycle

    /// Sets up observers, loads the item, performs initial seek, and starts playback.
    /// Call from `.onAppear` or `.task`.
    public func activate() {
        guard !isActivated else { return }
        isActivated = true

        let item: AVPlayerItem

        // If HLS audio tracks are provided and URL is m3u8, set up manifest interception.
        if let interceptorTracks = pendingHLSAudioTracks, !interceptorTracks.isEmpty,
           url.pathExtension.lowercased() == "m3u8" || url.absoluteString.contains(".m3u8")
        {
            let (asset, interceptor) = HLSManifestInterceptor.makeAsset(
                url: url,
                audioTracks: interceptorTracks
            )
            self.hlsInterceptor = interceptor
            item = AVPlayerItem(asset: asset)
        } else {
            item = AVPlayerItem(url: url)
        }

        if let resolution = configuration.preferredMaximumResolution {
            item.preferredMaximumResolution = resolution
        }

        player.replaceCurrentItem(with: item)

        setupTimeObserver()
        setupRateObserver()
        setupCurrentItemObserver()
        observeCurrentItem(item)

        trackState.player = player
    }

    /// Audio track metadata for HLS manifest rewriting (set before activate).
    public var pendingHLSAudioTracks: [HLSAudioTrackInfo]?

    /// Tears down observers, stops playback, and fully unloads media.
    /// Call from `.onDisappear`.
    public func deactivate() {
        guard isActivated else { return }
        isActivated = false

        player.pause()
        state.isPlaying = false

        timeObserver?.detach()
        timeObserver = nil
        itemObserver?.stopObserving()
        itemObserver = nil
        rateObservation?.invalidate()
        rateObservation = nil
        currentItemObservation?.invalidate()
        currentItemObservation = nil

        // Fully unload media so AVPlayer releases its audio pipeline.
        player.replaceCurrentItem(with: nil)

        // Clear external subtitles.
        externalSubtitleState.clear()

        // Break retain cycles through callback closures.
        onProgressUpdate = nil
        onPlaybackEnd = nil
        onPlayNext = nil
        onDismissNext = nil

        // Release HLS manifest interceptor.
        hlsInterceptor = nil
    }

    /// Replaces the current URL and resets state. Call `activate()` again if needed,
    /// or if already activated, it will auto-setup.
    public func replaceURL(_ newURL: URL) {
        url = newURL
        hasPerformedInitialSeek = false
        state = PlayerState()
        upNextDismissed = false

        if isActivated {
            let item = AVPlayerItem(url: newURL)
            if let resolution = configuration.preferredMaximumResolution {
                item.preferredMaximumResolution = resolution
            }
            player.replaceCurrentItem(with: item)
            // currentItem observer will handle the rest.
        }
    }

    /// Replaces the current URL with a pre-built AVPlayerItem (for HLS interception).
    public func replaceWithItem(_ item: AVPlayerItem) {
        hasPerformedInitialSeek = false
        state = PlayerState()
        upNextDismissed = false
        player.replaceCurrentItem(with: item)
    }

    // MARK: - Playback controls

    public func play() {
        player.play()
        state.isPlaying = true
    }

    public func pause() {
        player.pause()
        state.isPlaying = false
    }

    public func togglePlayPause() {
        if state.isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func seek(to seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let self, finished else { return }
            MainActor.assumeIsolated {
                self.state.didFinishPlaying = false
            }
        }
    }

    public func skipForward(_ seconds: TimeInterval = 10) {
        guard let item = player.currentItem else { return }
        let current = CMTimeGetSeconds(item.currentTime())
        let duration = CMTimeGetSeconds(item.duration)
        guard duration.isFinite else { return }
        let target = min(current + seconds, duration)
        seek(to: target)
    }

    public func skipBackward(_ seconds: TimeInterval = 10) {
        guard let item = player.currentItem else { return }
        let current = CMTimeGetSeconds(item.currentTime())
        let target = max(current - seconds, 0)
        seek(to: target)
    }

    /// Seeks to the live edge of a live stream.
    public func seekToLiveEdge() {
        guard let item = player.currentItem else { return }
        guard let lastRange = item.seekableTimeRanges.last?.timeRangeValue else { return }
        let liveEdge = CMTimeRangeGetEnd(lastRange)
        player.seek(to: liveEdge, toleranceBefore: .zero, toleranceAfter: .zero)
        if !state.isPlaying { play() }
    }

    public func setSpeed(_ speed: PlaybackSpeed) {
        player.rate = speed.rate
        state.rate = speed.rate
    }

    /// Toggles between aspect fit and aspect fill.
    public func toggleZoom() {
        configuration.gravity = configuration.gravity.toggled
    }

    /// Toggles mute on/off.
    public func toggleMute() {
        player.isMuted.toggle()
        state.isMuted = player.isMuted
    }

    // MARK: - Up Next actions

    /// Dismiss the up-next banner for the current item.
    public func dismissUpNext() {
        upNextDismissed = true
        onDismissNext?()
    }

    /// Trigger playback of the next item (user tapped the banner).
    public func triggerPlayNext() {
        onPlayNext?()
    }

    // MARK: - Track selection (convenience)

    public func selectAudioTrack(_ track: any PlayerAudioTrack) {
        trackState.selectAudioTrack(track)
    }

    public func selectSubtitleTrack(_ track: any PlayerSubtitleTrack) {
        trackState.selectSubtitleTrack(track)
    }

    // MARK: - Observers setup

    private func setupTimeObserver() {
        let observer = TimeObserver { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            guard seconds.isFinite else { return }

            self.state.currentTime = seconds

            // Update duration and live detection from current item.
            // Only check for live AFTER readyToPlay — HLS streams start with
            // .indefinite duration before the manifest loads.
            if let item = self.player.currentItem {
                let dur = CMTimeGetSeconds(item.duration)
                if dur.isFinite && dur > 0 {
                    self.state.duration = dur
                    self.state.isLive = false
                } else if item.duration == .indefinite, self.state.status == .readyToPlay {
                    self.state.isLive = true
                }
            }

            self.onProgressUpdate?(self.state.currentTime, self.state.duration)

            // Update external subtitle cue.
            self.externalSubtitleState.updateTime(seconds)

            // Collect stats if needed.
            if self.isCollectingStats {
                Task { [weak self] in
                    guard let self, let item = self.player.currentItem else { return }
                    if self.accessLogObserver == nil {
                        self.accessLogObserver = AccessLogObserver()
                    }
                    self.stats = await self.accessLogObserver!.collectStats(from: item, player: self.player)
                }
            }
        }
        observer.attach(to: player)
        self.timeObserver = observer
    }

    private func setupRateObserver() {
        rateObservation = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                let isNowPlaying = player.rate > 0
                self.state.isPlaying = isNowPlaying
                self.state.rate = player.rate
            }
        }
    }

    private func setupCurrentItemObserver() {
        currentItemObservation = player.observe(\.currentItem, options: [.new, .old]) {
            [weak self] player, change in
            guard let self else { return }
            MainActor.assumeIsolated {
                // Stop observing old item.
                self.itemObserver?.stopObserving()

                // Start observing new item.
                if let newItem = player.currentItem {
                    self.observeCurrentItem(newItem)
                }
            }
        }
    }

    private func observeCurrentItem(_ item: AVPlayerItem) {
        let observer = PlayerItemObserver()

        observer.onStatusChanged = { [weak self] status in
            guard let self else { return }
            switch status {
            case .readyToPlay:
                self.state.status = .readyToPlay
                self.performInitialSeekIfNeeded()
                self.applySubtitleFontSize()

                // Discover tracks.
                Task {
                    await self.trackState.discoverTracks(from: item)
                }

            case .failed:
                self.state.status = .failed
                if let error = item.error {
                    self.state.error = .playerItemFailed(underlying: error)
                }

            case .unknown:
                self.state.status = .unknown

            @unknown default:
                break
            }
        }

        observer.onPlaybackEnded = { [weak self] in
            guard let self else { return }
            self.state.didFinishPlaying = true

            if self.configuration.loop {
                self.player.seek(to: .zero)
                self.player.play()
            } else if self.upNextItem != nil && !self.upNextDismissed {
                self.state.isPlaying = false
                self.onPlayNext?()
            } else {
                self.state.isPlaying = false
                self.onPlaybackEnd?()
            }
        }

        observer.onPlaybackFailed = { [weak self] error in
            guard let self else { return }
            if let error {
                self.state.error = .playerItemFailed(underlying: error)
            }
            self.state.status = .failed
        }

        observer.observe(item)
        self.itemObserver = observer
    }

    private func applySubtitleFontSize() {
        guard let item = player.currentItem else { return }
        if subtitleFontSize.percentage == 100 {
            item.textStyleRules = nil
        } else {
            let attributes: [String: Any] = [
                kCMTextMarkupAttribute_RelativeFontSize as String: subtitleFontSize.percentage
            ]
            if let rule = AVTextStyleRule(textMarkupAttributes: attributes) {
                item.textStyleRules = [rule]
            }
        }
    }

    private func performInitialSeekIfNeeded() {
        guard !hasPerformedInitialSeek else {
            // Already seeked — just ensure playback state if autoPlay.
            if configuration.autoPlay {
                play()
            }
            return
        }

        hasPerformedInitialSeek = true

        if configuration.startTime > 0 {
            let time = CMTime(seconds: configuration.startTime, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) {
                [weak self] finished in
                guard let self, finished else { return }
                MainActor.assumeIsolated {
                    if self.configuration.autoPlay {
                        self.play()
                    }
                }
            }
        } else if configuration.autoPlay {
            play()
        }
    }
}
