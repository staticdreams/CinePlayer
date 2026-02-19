import AVFoundation
import Combine

/// Observes AVPlayerItem status changes and end-of-playback using modern KVO + NotificationCenter.
@MainActor
final class PlayerItemObserver {
    private var statusObservation: NSKeyValueObservation?
    private var endNotificationToken: NSObjectProtocol?
    private var failedToPlayToEndToken: NSObjectProtocol?

    var onStatusChanged: (@MainActor (AVPlayerItem.Status) -> Void)?
    var onPlaybackEnded: (@MainActor () -> Void)?
    var onPlaybackFailed: (@MainActor (Error?) -> Void)?

    func observe(_ item: AVPlayerItem) {
        stopObserving()

        statusObservation = item.observe(\.status, options: [.new, .initial]) {
            [weak self] item, _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.onStatusChanged?(item.status)
            }
        }

        endNotificationToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.onPlaybackEnded?()
            }
        }

        failedToPlayToEndToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            MainActor.assumeIsolated {
                self.onPlaybackFailed?(error)
            }
        }
    }

    func stopObserving() {
        statusObservation?.invalidate()
        statusObservation = nil

        if let token = endNotificationToken {
            NotificationCenter.default.removeObserver(token)
            endNotificationToken = nil
        }

        if let token = failedToPlayToEndToken {
            NotificationCenter.default.removeObserver(token)
            failedToPlayToEndToken = nil
        }
    }

    deinit {
        statusObservation?.invalidate()
        if let token = endNotificationToken {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = failedToPlayToEndToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
