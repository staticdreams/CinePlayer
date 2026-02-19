import Foundation

/// Manages auto-hide timer for player controls.
@Observable
@MainActor
public final class ControlsVisibility {
    /// Whether controls are currently visible.
    public var isVisible: Bool = true

    /// How long to wait before auto-hiding (seconds).
    public var autoHideDelay: TimeInterval = 6.0

    private var hideTask: Task<Void, Never>?

    public init() {}

    /// Toggles visibility and resets the auto-hide timer.
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    /// Shows controls and starts the auto-hide timer.
    public func show() {
        isVisible = true
        resetTimer()
    }

    /// Hides controls immediately.
    public func hide() {
        isVisible = false
        cancelTimer()
    }

    /// Resets the auto-hide timer (call on user interaction).
    public func resetTimer() {
        cancelTimer()
        hideTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.autoHideDelay))
            guard !Task.isCancelled else { return }
            self.isVisible = false
        }
    }

    /// Cancels the auto-hide timer.
    public func cancelTimer() {
        hideTask?.cancel()
        hideTask = nil
    }
}
