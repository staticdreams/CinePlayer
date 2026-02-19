import AVFoundation

/// Wraps AVLayerVideoGravity for the public API.
public enum VideoGravity: Sendable, Hashable {
    case resizeAspect
    case resizeAspectFill
    case resize

    public var avGravity: AVLayerVideoGravity {
        switch self {
        case .resizeAspect: return .resizeAspect
        case .resizeAspectFill: return .resizeAspectFill
        case .resize: return .resize
        }
    }

    /// Returns the toggled zoom state (aspect fit <-> aspect fill).
    public var toggled: VideoGravity {
        switch self {
        case .resizeAspect: return .resizeAspectFill
        case .resizeAspectFill: return .resizeAspect
        case .resize: return .resizeAspect
        }
    }
}
