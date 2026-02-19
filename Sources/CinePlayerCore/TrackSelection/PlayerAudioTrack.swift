import Foundation

/// Protocol for audio track metadata, decoupled from any app-specific types.
///
/// Conformers provide rich display names and language info that CinePlayer
/// uses for its custom audio track picker and for matching to AVMediaSelectionOption.
public protocol PlayerAudioTrack: Sendable, Identifiable where ID == String {
    /// Unique identifier for this track (e.g., index as string).
    var id: String { get }

    /// ISO-639 language code: "rus", "eng", "ru", "en", etc.
    var language: String? { get }

    /// Rich display name shown in the track picker.
    /// Example: "Русский — Дубляж (LostFilm) • AAC 2ch"
    var displayName: String { get }

    /// Whether this track should be selected by default.
    var isDefault: Bool { get }
}
