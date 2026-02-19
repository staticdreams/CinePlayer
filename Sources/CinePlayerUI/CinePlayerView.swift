import AVFoundation
import CinePlayerCore
import CinePlayerPiP
import SwiftUI

/// The main public view for CinePlayer. Hosts the video surface and controls overlay.
public struct CinePlayerView: View {
    @State private var engine: PlayerEngine
    @State private var controlsVisibility = ControlsVisibility()
    @State private var pipManager = PiPManager()
    @State private var showAudioPicker = false
    @State private var showSubtitlePicker = false
    @State private var showStats = false
    @Environment(\.dismiss) private var dismiss

    // Configurable via modifiers
    private var titleInfo = PlayerTitleInfo("")
    private var onProgressUpdateCallback: ((TimeInterval, TimeInterval) -> Void)?
    private var onPlaybackEndCallback: (() -> Void)?

    public init(url: URL, configuration: PlayerConfiguration = PlayerConfiguration()) {
        self._engine = State(initialValue: PlayerEngine(url: url, configuration: configuration))
    }

    public var body: some View {
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
                titleInfo: titleInfo,
                showingStats: showStats,
                onClose: {
                    engine.deactivate()
                    dismiss()
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

            // Stats overlay (top-left)
            if showStats {
                VStack {
                    HStack {
                        StatsOverlayView(stats: engine.stats)
                            .padding(15)
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task {
            // Wire up callbacks before activating.
            engine.onProgressUpdate = onProgressUpdateCallback
            engine.onPlaybackEnd = { [onPlaybackEndCallback] in
                onPlaybackEndCallback?()
            }

            setAudioSession()
            engine.activate()
            controlsVisibility.show()
        }
        .onDisappear {
            engine.deactivate()
            pipManager.tearDown()
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
    }

    // MARK: - Track Pickers

    @ViewBuilder
    private var audioPickerSheet: some View {
        AudioTrackPicker(
            tracks: engine.trackState.audioTracks,
            selectedIndex: engine.trackState.selectedAudioIndex,
            onSelect: { index in
                engine.trackState.selectedAudioIndex = index
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
            }
        )
    }

    // MARK: - Audio Session

    private func setAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("[CinePlayer] Audio session setup failed: \(error)")
            #endif
        }
    }

    private func restoreAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
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
}
