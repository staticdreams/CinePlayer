import AVFoundation

/// Maps protocol-based track metadata to AVMediaSelectionOption by language + position.
///
/// Groups both protocol tracks and AV options by normalized language code, then matches
/// by position within each group. This mirrors the algorithm in the existing AudioTrackMapper.
public enum TrackMatcher {

    /// Result of matching a protocol track to an AVMediaSelectionOption.
    public struct MatchedAudioTrack: Sendable {
        public let protocolTrack: any PlayerAudioTrack
        public let option: AVMediaSelectionOption?

        public init(protocolTrack: any PlayerAudioTrack, option: AVMediaSelectionOption?) {
            self.protocolTrack = protocolTrack
            self.option = option
        }
    }

    /// Matches protocol audio tracks to AVMediaSelectionOptions by language + position.
    ///
    /// - Parameters:
    ///   - tracks: The protocol tracks provided by the host app (determines what appears in the picker).
    ///   - options: The AVMediaSelectionOptions discovered from the asset.
    /// - Returns: Array of matched pairs. Each protocol track gets at most one option.
    @MainActor
    public static func matchAudioTracks(
        _ tracks: [any PlayerAudioTrack],
        to options: [AVMediaSelectionOption]
    ) -> [MatchedAudioTrack] {
        // Group options by normalized language.
        var optionsByLang: [String: [AVMediaSelectionOption]] = [:]
        for option in options {
            let lang = normalizeLanguage(option.extendedLanguageTag
                ?? option.locale?.language.languageCode?.identifier)
            optionsByLang[lang, default: []].append(option)
        }

        // Track how many protocol tracks we've consumed per language.
        var counters: [String: Int] = [:]

        return tracks.map { track in
            let lang = normalizeLanguage(track.language)
            let position = counters[lang, default: 0]
            counters[lang] = position + 1

            // Try exact language match first.
            if let langOptions = optionsByLang[lang], position < langOptions.count {
                return MatchedAudioTrack(protocolTrack: track, option: langOptions[position])
            }

            // Fallback: try ISO-639 cross-mapping (e.g., "rus" <-> "ru").
            let alt = alternateLanguageCode(lang)
            if let altOptions = optionsByLang[alt], position < altOptions.count {
                return MatchedAudioTrack(protocolTrack: track, option: altOptions[position])
            }

            return MatchedAudioTrack(protocolTrack: track, option: nil)
        }
    }

    /// Matches protocol subtitle tracks to AVMediaSelectionOptions.
    @MainActor
    public static func matchSubtitleTracks(
        _ tracks: [any PlayerSubtitleTrack],
        to options: [AVMediaSelectionOption]
    ) -> [(track: any PlayerSubtitleTrack, option: AVMediaSelectionOption?)] {
        var optionsByLang: [String: [AVMediaSelectionOption]] = [:]
        for option in options {
            let lang = normalizeLanguage(option.extendedLanguageTag
                ?? option.locale?.language.languageCode?.identifier)
            optionsByLang[lang, default: []].append(option)
        }

        var counters: [String: Int] = [:]

        return tracks.map { track in
            let lang = normalizeLanguage(track.language)
            let position = counters[lang, default: 0]
            counters[lang] = position + 1

            if let langOptions = optionsByLang[lang], position < langOptions.count {
                return (track: track, option: langOptions[position])
            }

            let alt = alternateLanguageCode(lang)
            if let altOptions = optionsByLang[alt], position < altOptions.count {
                return (track: track, option: altOptions[position])
            }

            return (track: track, option: nil)
        }
    }

    // MARK: - Language normalization

    private static func normalizeLanguage(_ code: String?) -> String {
        guard let code, !code.isEmpty else { return "und" }
        // Take the primary subtag (before any hyphen), lowercase.
        let primary = code.split(separator: "-").first.map(String.init) ?? code
        return primary.lowercased()
    }

    /// Common ISO-639-2 <-> ISO-639-1 mappings.
    private static func alternateLanguageCode(_ code: String) -> String {
        let map: [String: String] = [
            "rus": "ru", "ru": "rus",
            "eng": "en", "en": "eng",
            "ukr": "uk", "uk": "ukr",
            "deu": "de", "de": "deu",
            "fra": "fr", "fr": "fra",
            "spa": "es", "es": "spa",
            "ita": "it", "it": "ita",
            "jpn": "ja", "ja": "jpn",
            "kor": "ko", "ko": "kor",
            "zho": "zh", "zh": "zho",
            "por": "pt", "pt": "por",
            "pol": "pl", "pl": "pol",
            "tur": "tr", "tr": "tur",
        ]
        return map[code] ?? code
    }
}
