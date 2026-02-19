import AVFoundation

/// Wraps AVPlayer's addPeriodicTimeObserver with a clean lifecycle.
@MainActor
final class TimeObserver {
    private var token: Any?
    private weak var player: AVPlayer?

    let interval: CMTime
    let callback: @MainActor (CMTime) -> Void

    init(
        interval: CMTime = CMTimeMake(value: 1, timescale: 2),
        callback: @MainActor @escaping (CMTime) -> Void
    ) {
        self.interval = interval
        self.callback = callback
    }

    func attach(to player: AVPlayer) {
        detach()
        self.player = player
        token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.callback(time)
            }
        }
    }

    func detach() {
        if let token, let player {
            player.removeTimeObserver(token)
        }
        token = nil
        player = nil
    }

    deinit {
        if let token, let player {
            player.removeTimeObserver(token)
        }
    }
}
