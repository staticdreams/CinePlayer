import Foundation

/// Typed errors for CinePlayer.
public enum PlayerError: LocalizedError, Sendable {
    case invalidURL
    case playerItemFailed(underlying: Error)
    case assetLoadFailed(underlying: Error)
    case seekFailed
    case trackSelectionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .playerItemFailed(let error):
            return "Player item failed: \(error.localizedDescription)"
        case .assetLoadFailed(let error):
            return "Asset load failed: \(error.localizedDescription)"
        case .seekFailed:
            return "Seek operation failed"
        case .trackSelectionFailed:
            return "Track selection failed"
        }
    }
}
