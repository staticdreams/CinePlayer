import AVFoundation
import Combine
import CinePlayerCore
import CinePlayerNowPlaying
import CinePlayerPiP
import SwiftUI
import UIKit

/// Now Playing metadata for lock screen / control center integration.
private struct NowPlayingMetadata {
    let title: String
    let artist: String?
    let artwork: UIImage?
    let artworkURL: URL?
}

/// The main public view for CinePlayer. Hosts the video surface and controls overlay.
public struct CinePlayerView: View {
    @State private var engine: PlayerEngine
    @State private var controlsVisibility = ControlsVisibility()
    @State private var pipManager = PiPManager()
    @State private var nowPlayingManager = NowPlayingManager()
    @State private var showAudioPicker = false
    @State private var showSubtitlePicker = false
    @State private var showStats = false
    @State private var isLandscape = Self.currentIsLandscape()
    @Environment(\.dismiss) private var dismiss

    // Configurable via modifiers
    private var titleInfo = PlayerTitleInfo("")
    private var nowPlayingMetadata: NowPlayingMetadata?
    private var onProgressUpdateCallback: ((TimeInterval, TimeInterval) -> Void)?
    private var onPlaybackEndCallback: (() -> Void)?
    private var onPlayNextCallback: (() -> Void)?
    private var onDismissNextCallback: (() -> Void)?
    private var onReplayCallback: (() -> Void)?
    private var onSearchSubtitlesCallback: (() -> Void)?
    private var onRemoveExternalSubtitlesCallback: (() -> Void)?
    private var externalSubtitleContent: String?
    private var hasExternalSubtitle: Bool = false
    private var onNextEpisodeCallback: (() -> Void)?
    private var hasNextEpisodeFlag: Bool = false
    private var swipeToDismiss: Bool = true
    private var onAudioTrackSelectedCallback: ((Int) -> Void)?
    private var onEngineReadyCallback: ((PlayerEngine) -> Void)?
    private var onPiPStateChangeCallback: ((Bool) -> Void)?
    private var onRestoreFromPiPCallback: (() -> Void)?
    private var onCloseCallback: (() -> Void)?
    private var onPlaybackSpeedChangeCallback: ((Float) -> Void)?

    public init(url: URL, configuration: PlayerConfiguration = PlayerConfiguration()) {
        self._engine = State(initialValue: PlayerEngine(url: url, configuration: configuration))
    }

    private static func currentIsLandscape() -> Bool {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return false }
        return scene.interfaceOrientation.isLandscape
    }

    private let orientationChanged = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification)

    public var body: some View {
        playerContent
            .swipeToDismiss(enabled: swipeToDismiss) {
                engine.deactivate()
                performClose()
            }
    }

    private func performClose() {
        if let onCloseCallback {
            onCloseCallback()
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private var playerContent: some View {
        ZStack {
            // Full-bleed background + video (ignore safe area)
            Color.black.ignoresSafeArea()

            VideoSurfaceView(
                player: engine.player,
                gravity: engine.configuration.gravity,
                onPlayerLayerReady: { layer in
                    pipManager.configure(with: layer)
                }
            )
            .ignoresSafeArea()

            // Controls overlay (respects safe area — stays below Dynamic Island, above home indicator)
            ControlsOverlay(
                engine: engine,
                controlsVisibility: controlsVisibility,
                isLandscape: isLandscape,
                hasNextEpisode: hasNextEpisodeFlag,
                titleInfo: titleInfo,
                localization: engine.configuration.localization,
                showingStats: showStats,
                onClose: {
                    engine.deactivate()
                    performClose()
                },
                onPiPTap: {
                    pipManager.toggle()
                },
                onAudioTrackTap: {
                    showAudioPicker = true
                },
                onSubtitleTrackTap: {
                    showSubtitlePicker = true
                },
                onStatsTap: {
                    showStats.toggle()
                    engine.isCollectingStats = showStats
                }
            )

            // External subtitle overlay
            if engine.externalSubtitleState.isActive {
                ExternalSubtitleOverlay(
                    state: engine.externalSubtitleState,
                    fontSize: engine.subtitleFontSize
                )
            }

            // Stats overlay (top-left)
            if showStats {
                VStack {
                    HStack {
                        StatsOverlayView(stats: engine.stats, localization: engine.configuration.localization)
                            .padding(15)
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // Up Next overlay (bottom-right, above progress bar)
            if engine.isUpNextVisible {
                UpNextOverlay(
                    item: engine.upNextItem,
                    countdown: engine.upNextCountdown,
                    countdownDuration: engine.upNextItem?.countdownDuration ?? 0,
                    localization: engine.configuration.localization,
                    onTap: { engine.triggerPlayNext() },
                    onDismiss: { engine.dismissUpNext() },
                    onReplay: engine.onReplayRequested != nil ? { engine.triggerReplay() } : nil
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: engine.isUpNextVisible)
            } else if engine.isReplayVisible {
                UpNextOverlay(
                    item: nil,
                    countdown: engine.replayCountdown,
                    countdownDuration: engine.replayCountdownDuration,
                    localization: engine.configuration.localization,
                    onTap: { engine.triggerReplay() },
                    onDismiss: { engine.dismissUpNext() },
                    onReplay: nil
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: engine.isReplayVisible)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onReceive(orientationChanged) { _ in
            isLandscape = Self.currentIsLandscape()
        }
        .onChange(of: pipManager.isPiPActive) { _, newValue in
            onPiPStateChangeCallback?(newValue)
        }
        .task {
            // Wire up callbacks before activating.
            if let nowPlayingMetadata {
                let originalCallback = onProgressUpdateCallback
                engine.onProgressUpdate = { [nowPlayingManager] currentTime, duration in
                    originalCallback?(currentTime, duration)
                    nowPlayingManager.updatePlaybackPosition(engine: engine)
                }
            } else {
                engine.onProgressUpdate = onProgressUpdateCallback
            }
            engine.onPlaybackEnd = { [onPlaybackEndCallback] in
                onPlaybackEndCallback?()
            }
            engine.onPlayNext = { [onPlayNextCallback] in
                onPlayNextCallback?()
            }
            engine.onDismissNext = { [onDismissNextCallback] in
                onDismissNextCallback?()
            }
            if let onReplayCallback {
                engine.onReplayRequested = {
                    onReplayCallback()
                }
            }
            if let onNextEpisodeCallback {
                engine.onNextEpisode = {
                    onNextEpisodeCallback()
                }
            }

            if let onRestoreFromPiPCallback {
                pipManager.onRestoreUI = onRestoreFromPiPCallback
            }

            if let onPlaybackSpeedChangeCallback {
                engine.onPlaybackSpeedChange = onPlaybackSpeedChangeCallback
            }

            setAudioSession()
            engine.activate()
            controlsVisibility.show()

            // Hand the engine to the host app so it can observe state and
            // route remote commands (e.g. from a watchOS companion).
            onEngineReadyCallback?(engine)

            // Load external subtitle if provided.
            if let externalSubtitleContent {
                engine.externalSubtitleState.loadSubtitle(content: externalSubtitleContent)
            }

            if let nowPlayingMetadata {
                var artwork = nowPlayingMetadata.artwork
                if artwork == nil, let artworkURL = nowPlayingMetadata.artworkURL {
                    if let (data, _) = try? await URLSession.shared.data(from: artworkURL),
                       let image = UIImage(data: data) {
                        artwork = image
                    }
                }
                nowPlayingManager.configure(
                    engine: engine,
                    title: nowPlayingMetadata.title,
                    artist: nowPlayingMetadata.artist,
                    artwork: artwork
                )
            }
        }
        .onDisappear {
            engine.deactivate()
            pipManager.tearDown()
            nowPlayingManager.tearDown()
            restoreAudioSession()
        }
        // Audio picker sheet
        .sheet(isPresented: $showAudioPicker) {
            audioPickerSheet
        }
        // Subtitle picker sheet
        .sheet(isPresented: $showSubtitlePicker) {
            subtitlePickerSheet
        }
        // React to external subtitle content changes (e.g. after user downloads from search sheet)
        .onChange(of: externalSubtitleContent) { _, newContent in
            if let newContent {
                engine.externalSubtitleState.loadSubtitle(content: newContent)
            } else {
                engine.externalSubtitleState.clear()
            }
        }
    }

    // MARK: - Track Pickers

    @ViewBuilder
    private var audioPickerSheet: some View {
        AudioTrackPicker(
            tracks: engine.trackState.audioTracks,
            selectedIndex: engine.trackState.selectedAudioIndex,
            localization: engine.configuration.localization,
            onSelect: { index in
                engine.trackState.selectedAudioIndex = index
                onAudioTrackSelectedCallback?(index)
                showAudioPicker = false
                controlsVisibility.resetTimer()
            },
            onDismiss: {
                showAudioPicker = false
                controlsVisibility.resetTimer()
            }
        )
    }

    @ViewBuilder
    private var subtitlePickerSheet: some View {
        SubtitleTrackPicker(
            tracks: engine.trackState.subtitleTracks,
            selectedIndex: engine.trackState.selectedSubtitleIndex,
            subtitlesOff: engine.trackState.subtitlesOff,
            localization: engine.configuration.localization,
            onSelect: { index in
                engine.trackState.selectedSubtitleIndex = index
                engine.trackState.subtitlesOff = false
                showSubtitlePicker = false
                controlsVisibility.resetTimer()
            },
            onDisable: {
                engine.trackState.disableSubtitles()
                showSubtitlePicker = false
                controlsVisibility.resetTimer()
            },
            onDismiss: {
                showSubtitlePicker = false
                controlsVisibility.resetTimer()
            },
            onSearchOnline: onSearchSubtitlesCallback.map { callback in
                {
                    showSubtitlePicker = false
                    callback()
                }
            },
            hasExternalSubtitle: hasExternalSubtitle,
            onRemoveExternal: onRemoveExternalSubtitlesCallback.map { callback in
                {
                    showSubtitlePicker = false
                    callback()
                }
            }
        )
    }

    // MARK: - Audio Session

    private func setAudioSession() {
        AudioSessionCoordinator.shared.activate()
    }

    private func restoreAudioSession() {
        AudioSessionCoordinator.shared.deactivate()
    }
}

/// Reference-counts audio-session ownership across `CinePlayerView` instances.
///
/// When SwiftUI replaces one `CinePlayerView` with another (e.g. advancing to the
/// next episode via a changing `.id()`), the new view's `.task` can fire before
/// the old view's `.onDisappear`. Without coordination, the disappearing view
/// would tear the session down with `.ambient` + `setActive(false)` *after* the
/// new view had already set `.playback` + `setActive(true)`, leaving the new
/// player with no audio until the user quit and reopened the player.
///
/// The coordinator only applies the underlying `AVAudioSession` changes on the
/// first activation and last deactivation; intermediate transitions are no-ops.
@MainActor
private final class AudioSessionCoordinator {
    static let shared = AudioSessionCoordinator()

    private var refCount = 0

    private init() {}

    func activate() {
        refCount += 1
        guard refCount == 1 else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("[CinePlayer] Audio session setup failed: \(error)")
            #endif
        }
    }

    func deactivate() {
        refCount = max(0, refCount - 1)
        guard refCount == 0 else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            #if DEBUG
            print("[CinePlayer] Audio session restore failed: \(error)")
            #endif
        }
    }
}

// MARK: - View Modifiers

extension CinePlayerView {
    /// Sets audio tracks for the custom picker (filtered + rich labels).
    public func audioTracks(_ tracks: [any PlayerAudioTrack]) -> CinePlayerView {
        var view = self
        view.engine.trackState.audioTracks = tracks
        return view
    }

    /// Sets subtitle tracks for the custom picker.
    public func subtitleTracks(_ tracks: [any PlayerSubtitleTrack]) -> CinePlayerView {
        var view = self
        view.engine.trackState.subtitleTracks = tracks
        return view
    }

    /// Sets the start time for playback resume.
    public func startTime(_ seconds: TimeInterval) -> CinePlayerView {
        var view = self
        view.engine.configuration.startTime = seconds
        return view
    }

    /// Sets the progress update callback (called every 500ms).
    public func onProgressUpdate(_ callback: @escaping (TimeInterval, TimeInterval) -> Void) -> CinePlayerView {
        var view = self
        view.onProgressUpdateCallback = callback
        return view
    }

    /// Sets the playback end callback.
    public func onPlaybackEnd(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onPlaybackEndCallback = callback
        return view
    }

    /// Sets a simple title displayed above the progress bar.
    public func title(_ title: String) -> CinePlayerView {
        var view = self
        view.titleInfo = PlayerTitleInfo(title)
        return view
    }

    /// Sets rich title info with optional original title and metadata.
    public func titleInfo(_ info: PlayerTitleInfo) -> CinePlayerView {
        var view = self
        view.titleInfo = info
        return view
    }

    /// Sets the video gravity.
    public func videoGravity(_ gravity: VideoGravity) -> CinePlayerView {
        var view = self
        view.engine.configuration.gravity = gravity
        return view
    }

    /// Sets the skip forward/backward interval in seconds (default 10).
    /// SF Symbols exist for 5, 10, 15, 30, 45.
    public func skipInterval(_ seconds: TimeInterval) -> CinePlayerView {
        var view = self
        view.engine.configuration.skipInterval = seconds
        return view
    }

    /// Enables or disables loop mode.
    public func loop(_ enabled: Bool) -> CinePlayerView {
        var view = self
        view.engine.configuration.loop = enabled
        return view
    }

    /// Sets HLS audio track metadata for manifest rewriting (online playback).
    public func hlsAudioTracks(_ tracks: [HLSAudioTrackInfo]) -> CinePlayerView {
        var view = self
        view.engine.pendingHLSAudioTracks = tracks
        return view
    }

    /// Enables Now Playing integration for lock screen and control center.
    /// Pass `artwork` for a pre-loaded image or `artworkURL` for async download.
    public func nowPlaying(title: String, artist: String? = nil, artwork: UIImage? = nil, artworkURL: URL? = nil) -> CinePlayerView {
        var view = self
        view.nowPlayingMetadata = NowPlayingMetadata(title: title, artist: artist, artwork: artwork, artworkURL: artworkURL)
        return view
    }

    /// Sets the player UI language by code (e.g. `"en"`, `"ru"`).
    public func language(_ code: String) -> CinePlayerView {
        var view = self
        view.engine.configuration.localization = PlayerLocalization(languageCode: code)
        return view
    }

    /// Sets a custom localization for full control over all player strings.
    public func localization(_ localization: PlayerLocalization) -> CinePlayerView {
        var view = self
        view.engine.configuration.localization = localization
        return view
    }

    /// Enables or disables the subtitle font size control.
    public func subtitleFontSize(_ enabled: Bool) -> CinePlayerView {
        var view = self
        view.engine.configuration.subtitleFontSizeEnabled = enabled
        return view
    }

    /// Sets the up-next item for the "Coming Up Next" banner overlay.
    public func upNext(_ item: UpNextItem?) -> CinePlayerView {
        var view = self
        view.engine.upNextItem = item
        return view
    }

    /// Sets the callback for when the next item should start playing.
    public func onPlayNext(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onPlayNextCallback = callback
        return view
    }

    /// Sets the callback for when the user dismisses the up-next banner.
    public func onDismissNext(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onDismissNextCallback = callback
        return view
    }

    /// Sets the callback for when the user wants to replay the current item.
    public func onReplay(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onReplayCallback = callback
        return view
    }

    /// Sets the callback for when the user taps "Search Online" in the subtitle picker.
    public func onSearchSubtitles(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onSearchSubtitlesCallback = callback
        return view
    }

    /// Loads external subtitle content (WebVTT/SRT string) for overlay rendering.
    public func externalSubtitle(_ content: String?, hasExternal: Bool = false) -> CinePlayerView {
        var view = self
        view.externalSubtitleContent = content
        view.hasExternalSubtitle = hasExternal
        return view
    }

    /// Sets the callback for removing external subtitles.
    public func onRemoveExternalSubtitles(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onRemoveExternalSubtitlesCallback = callback
        return view
    }

    /// Sets the preferred maximum resolution for quality-constrained playback.
    /// AVPlayer will prefer HLS variants at or below this resolution.
    public func preferredResolution(_ size: CGSize?) -> CinePlayerView {
        var view = self
        view.engine.configuration.preferredMaximumResolution = size
        return view
    }

    /// Shows a "next episode" button in the player controls.
    /// The button appears only when this callback is set.
    public func onNextEpisode(_ callback: (() -> Void)?) -> CinePlayerView {
        var view = self
        view.onNextEpisodeCallback = callback
        view.hasNextEpisodeFlag = callback != nil
        return view
    }

    /// Enables or disables swipe-down-to-dismiss gesture.
    public func swipeToDismissEnabled(_ enabled: Bool) -> CinePlayerView {
        var view = self
        view.swipeToDismiss = enabled
        return view
    }

    /// Sets a callback invoked when the user selects an audio track in the in-player picker.
    /// The callback receives the selected track index (in the audioTracks array).
    public func onAudioTrackSelected(_ callback: @escaping (Int) -> Void) -> CinePlayerView {
        var view = self
        view.onAudioTrackSelectedCallback = callback
        return view
    }

    /// Delivers the active `PlayerEngine` to the host app once it has been
    /// activated. Use this to observe playback state and invoke commands
    /// (play/pause/seek/selectAudioTrack/…) from outside the player view —
    /// for example, from a remote-control surface such as a watchOS companion.
    ///
    /// The callback fires once per presentation, on the main actor, after the
    /// engine's internal callbacks have been wired. The host should hold a
    /// weak reference to the engine and drop it when the player dismisses.
    public func onEngineReady(_ callback: @escaping (PlayerEngine) -> Void) -> CinePlayerView {
        var view = self
        view.onEngineReadyCallback = callback
        return view
    }

    /// Callback fired when Picture-in-Picture activates or deactivates.
    /// Use this to hide/restore a host-owned player chrome so the app UI can be used
    /// while PiP is active.
    public func onPiPStateChange(_ callback: @escaping (Bool) -> Void) -> CinePlayerView {
        var view = self
        view.onPiPStateChangeCallback = callback
        return view
    }

    /// Callback fired when the system requests UI restoration from PiP (user tapped
    /// the "expand" button in the floating mini window). The host should re-present
    /// the full-screen player in response.
    public func onRestoreFromPiP(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onRestoreFromPiPCallback = callback
        return view
    }

    /// Overrides the default `Environment(\.dismiss)` close behavior. When set, the
    /// player invokes this callback instead of dismissing a presentation — required
    /// when hosting the player outside a sheet/cover (e.g. as a ZStack overlay).
    public func onClose(_ callback: @escaping () -> Void) -> CinePlayerView {
        var view = self
        view.onCloseCallback = callback
        return view
    }

    /// Sets the initial playback speed applied once playback actually starts.
    /// Use this to carry a user-selected speed across successive items (e.g. episodes).
    public func initialPlaybackSpeed(_ speed: PlaybackSpeed) -> CinePlayerView {
        var view = self
        view.engine.configuration.initialSpeed = speed
        return view
    }

    /// Callback fired when the playback speed changes (user selected a new speed in
    /// the controls or the configured initial speed was applied on first play).
    public func onPlaybackSpeedChange(_ callback: @escaping (Float) -> Void) -> CinePlayerView {
        var view = self
        view.onPlaybackSpeedChangeCallback = callback
        return view
    }
}
