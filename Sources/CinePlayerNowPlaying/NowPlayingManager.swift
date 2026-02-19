import CinePlayerCore
import MediaPlayer
import UIKit

/// Manages MPNowPlayingInfoCenter and MPRemoteCommandCenter.
@MainActor
public final class NowPlayingManager {
    private var engine: PlayerEngine?

    public init() {}

    /// Configures now playing info and remote commands.
    public func configure(
        engine: PlayerEngine,
        title: String,
        artist: String? = nil,
        artwork: UIImage? = nil
    ) {
        self.engine = engine
        setupRemoteCommands(engine: engine)
        updateNowPlayingInfo(title: title, artist: artist, artwork: artwork, engine: engine)
    }

    /// Updates the now playing info center with current playback state.
    public func updateNowPlayingInfo(
        title: String,
        artist: String? = nil,
        artwork: UIImage? = nil,
        engine: PlayerEngine
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: engine.state.currentTime,
            MPMediaItemPropertyPlaybackDuration: engine.state.duration,
            MPNowPlayingInfoPropertyPlaybackRate: engine.state.isPlaying ? Double(engine.state.rate) : 0.0,
        ]

        if let artist {
            info[MPMediaItemPropertyArtist] = artist
        }

        if let artwork {
            let artworkItem = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
            info[MPMediaItemPropertyArtwork] = artworkItem
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Tears down now playing and remote commands.
    public func tearDown() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)
        engine = nil
    }

    private func setupRemoteCommands(engine: PlayerEngine) {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak engine] _ in
            guard let engine else { return .commandFailed }
            MainActor.assumeIsolated { engine.play() }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak engine] _ in
            guard let engine else { return .commandFailed }
            MainActor.assumeIsolated { engine.pause() }
            return .success
        }

        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.addTarget { [weak engine] event in
            guard let engine else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            MainActor.assumeIsolated { engine.skipForward(interval) }
            return .success
        }

        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.addTarget { [weak engine] event in
            guard let engine else { return .commandFailed }
            let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 10
            MainActor.assumeIsolated { engine.skipBackward(interval) }
            return .success
        }

        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak engine] event in
            guard let engine, let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            MainActor.assumeIsolated { engine.seek(to: posEvent.positionTime) }
            return .success
        }
    }
}
