import Foundation

/// Metadata for an audio track used during HLS playlist rewriting.
/// This is CinePlayer's internal representation — host apps bridge to this
/// via `PlayerAudioTrack` protocol or by providing metadata directly.
public struct HLSAudioTrackInfo: Sendable {
    public let index: Int?
    public let languageCode: String?
    public let displayName: String

    public init(index: Int?, languageCode: String?, displayName: String) {
        self.index = index
        self.languageCode = languageCode
        self.displayName = displayName
    }
}

/// Pure helpers to rewrite HLS master playlists.
/// Ported from Cinepub's HLSMasterPlaylistRewriter, decoupled from app-specific types.
public enum HLSPlaylistRewriter {

    /// Rewrites an HLS master playlist:
    /// - Updates `#EXT-X-MEDIA:TYPE=AUDIO` `NAME` attributes with rich display names.
    /// - Makes all playlist URIs absolute.
    ///
    /// - Parameters:
    ///   - playlistText: The master playlist content.
    ///   - masterURL: The original URL (for resolving relative URIs).
    ///   - audioTracks: Rich audio track metadata.
    /// - Returns: Rewritten playlist text.
    public static func rewriteMasterPlaylist(
        playlistText: String,
        masterURL: URL,
        audioTracks: [HLSAudioTrackInfo]
    ) -> String {
        let tracksByLangKey = buildTracksByLanguageKey(audioTracks)
        var countersByGroupAndLang: [String: Int] = [:]

        let lines = playlistText.split(whereSeparator: \.isNewline).map(String.init)

        let variantAudioGroups = collectVariantAudioGroups(from: lines)
        let canonicalAudioGroupId = selectCanonicalAudioGroupId(
            from: lines,
            referencedVariantAudioGroups: variantAudioGroups
        )

        var outputLines: [String] = []
        var previousWasStreamInf = false

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                outputLines.append(rawLine)
                continue
            }

            if previousWasStreamInf, !line.hasPrefix("#") {
                outputLines.append(makeAbsoluteURIString(line, relativeTo: masterURL))
                previousWasStreamInf = false
                continue
            }

            if line.hasPrefix("#EXT-X-STREAM-INF") {
                outputLines.append(
                    rewriteStreamInf(line: rawLine, canonicalAudioGroupId: canonicalAudioGroupId))
                previousWasStreamInf = true
                continue
            }

            if line.hasPrefix("#EXT-X-I-FRAME-STREAM-INF") {
                outputLines.append(rewriteIFrameStreamInf(line: rawLine, masterURL: masterURL))
                continue
            }

            if line.hasPrefix("#EXT-X-MEDIA") {
                if let rewritten = rewriteExtXMedia(
                    line: rawLine,
                    masterURL: masterURL,
                    tracksByLangKey: tracksByLangKey,
                    allTracksSorted: tracksByLangKey["*"] ?? [],
                    countersByGroupAndLang: &countersByGroupAndLang,
                    canonicalAudioGroupId: canonicalAudioGroupId,
                    referencedVariantAudioGroups: variantAudioGroups.unique
                ) {
                    outputLines.append(rewritten)
                }
                continue
            }

            if !line.hasPrefix("#") {
                outputLines.append(makeAbsoluteURIString(line, relativeTo: masterURL))
                continue
            }

            outputLines.append(rawLine)
        }

        return outputLines.joined(separator: "\n")
    }

    // MARK: - EXT-X-MEDIA

    private static func rewriteExtXMedia(
        line: String,
        masterURL: URL,
        tracksByLangKey: [String: [HLSAudioTrackInfo]],
        allTracksSorted: [HLSAudioTrackInfo],
        countersByGroupAndLang: inout [String: Int],
        canonicalAudioGroupId: String?,
        referencedVariantAudioGroups: Set<String>
    ) -> String? {
        guard let range = line.range(of: ":") else { return line }
        let prefix = String(line[..<range.lowerBound])
        let rawAttributes = String(line[range.upperBound...])

        var attrs = parseAttributeList(rawAttributes)

        if let uri = attrs["URI"], !uri.isEmpty {
            let unquoted = unquoteAttributeValue(uri)
            let abs = makeAbsoluteURIString(unquoted, relativeTo: masterURL)
            attrs["URI"] = quoteAttributeValue(abs)
        }

        let type = unquoteAttributeValue(attrs["TYPE"] ?? "")
        guard type.uppercased() == "AUDIO" else {
            return "\(prefix):\(serializeAttributeList(attrs))"
        }

        let groupIdRaw = unquoteAttributeValue(attrs["GROUP-ID"] ?? "_")
        let groupKey = normalizeGroupKey(groupIdRaw)
        let originalName = unquoteAttributeValue(attrs["NAME"] ?? "")

        if let canonicalAudioGroupId, referencedVariantAudioGroups.contains(groupKey),
            groupKey != canonicalAudioGroupId
        {
            return nil
        }

        let langRawOriginal = unquoteAttributeValue(attrs["LANGUAGE"] ?? "")
        let inferredLangKey = inferLanguageKey(
            languageAttribute: langRawOriginal, originalName: originalName)
        let langKey = inferredLangKey.isEmpty ? "und" : inferredLangKey

        let counterKey = "\(groupKey)|\(langKey)"
        let position = countersByGroupAndLang[counterKey, default: 0]
        countersByGroupAndLang[counterKey] = position + 1

        let matchedByIndex = matchTrackByIndex(
            fromOriginalName: originalName, allTracksSorted: allTracksSorted)
        let matchedByLangAndPosition: HLSAudioTrackInfo? = {
            guard matchedByIndex == nil else { return nil }
            return pickTrack(tracksByLangKey: tracksByLangKey, languageKey: langKey, position: position)
        }()
        let matched = matchedByIndex ?? matchedByLangAndPosition

        attrs.removeValue(forKey: "LANGUAGE")
        attrs.removeValue(forKey: "ASSOC-LANGUAGE")

        if let matched {
            attrs["NAME"] = quoteAttributeValue(matched.displayName)
        }

        return "\(prefix):\(serializeAttributeList(attrs))"
    }

    // MARK: - I-FRAME

    private static func rewriteIFrameStreamInf(line: String, masterURL: URL) -> String {
        guard let range = line.range(of: ":") else { return line }
        let prefix = String(line[..<range.lowerBound])
        let rawAttributes = String(line[range.upperBound...])
        var attrs = parseAttributeList(rawAttributes)

        if let uri = attrs["URI"], !uri.isEmpty {
            let unquoted = unquoteAttributeValue(uri)
            let abs = makeAbsoluteURIString(unquoted, relativeTo: masterURL)
            attrs["URI"] = quoteAttributeValue(abs)
        }

        return "\(prefix):\(serializeAttributeList(attrs))"
    }

    // MARK: - STREAM-INF

    private static func rewriteStreamInf(line: String, canonicalAudioGroupId: String?) -> String {
        guard let range = line.range(of: ":") else { return line }
        let prefix = String(line[..<range.lowerBound])
        let rawAttributes = String(line[range.upperBound...])
        var attrs = parseAttributeList(rawAttributes)

        if let canonicalAudioGroupId, attrs["AUDIO"] != nil {
            let old = unquoteAttributeValue(attrs["AUDIO"] ?? "")
            if old != canonicalAudioGroupId {
                attrs["AUDIO"] = quoteAttributeValue(canonicalAudioGroupId)
            }
        }

        return "\(prefix):\(serializeStreamInfAttributeList(attrs))"
    }

    // MARK: - Track mapping

    private static func pickTrack(
        tracksByLangKey: [String: [HLSAudioTrackInfo]],
        languageKey: String,
        position: Int
    ) -> HLSAudioTrackInfo? {
        if let list = tracksByLangKey[languageKey], position < list.count {
            return list[position]
        }
        if let primary = languageKey.split(separator: "-").first.map(String.init),
            let list = tracksByLangKey[primary], position < list.count
        {
            return list[position]
        }
        if languageKey == "und" {
            let all = tracksByLangKey["*"] ?? []
            if position < all.count { return all[position] }
        }
        return nil
    }

    private static func buildTracksByLanguageKey(_ tracks: [HLSAudioTrackInfo]) -> [String: [HLSAudioTrackInfo]] {
        let sorted = tracks.enumerated().sorted { a, b in
            let ia = a.element.index ?? Int.max
            let ib = b.element.index ?? Int.max
            if ia != ib { return ia < ib }
            return a.offset < b.offset
        }.map(\.element)

        var dict: [String: [HLSAudioTrackInfo]] = [:]
        var all: [HLSAudioTrackInfo] = []

        for track in sorted {
            all.append(track)
            let keys = languageKeys(for: track)
            for key in keys {
                dict[key, default: []].append(track)
            }
        }

        dict["*"] = all
        return dict
    }

    private struct VariantAudioGroups {
        let ordered: [String]
        let unique: Set<String>
    }

    private static func selectCanonicalAudioGroupId(
        from lines: [String],
        referencedVariantAudioGroups: VariantAudioGroups
    ) -> String? {
        guard !referencedVariantAudioGroups.ordered.isEmpty else { return nil }

        var counts: [String: Int] = [:]
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#EXT-X-MEDIA"), let range = line.range(of: ":") else { continue }
            let attrs = parseAttributeList(String(line[range.upperBound...]))
            let type = unquoteAttributeValue(attrs["TYPE"] ?? "").uppercased()
            guard type == "AUDIO" else { continue }
            let group = normalizeGroupKey(unquoteAttributeValue(attrs["GROUP-ID"] ?? "_"))
            counts[group, default: 0] += 1
        }

        var best: String = referencedVariantAudioGroups.ordered.first ?? "_"
        var bestCount = counts[best] ?? -1
        for group in referencedVariantAudioGroups.ordered {
            let c = counts[group] ?? 0
            if c > bestCount { best = group; bestCount = c }
        }
        return best
    }

    private static func collectVariantAudioGroups(from lines: [String]) -> VariantAudioGroups {
        var ordered: [String] = []
        var unique: Set<String> = []
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#EXT-X-STREAM-INF"), let range = line.range(of: ":") else { continue }
            let attrs = parseAttributeList(String(line[range.upperBound...]))
            guard let audioValue = attrs["AUDIO"] else { continue }
            let groupId = normalizeGroupKey(unquoteAttributeValue(audioValue))
            ordered.append(groupId)
            unique.insert(groupId)
        }
        return VariantAudioGroups(ordered: ordered, unique: unique)
    }

    private static func languageKeys(for track: HLSAudioTrackInfo) -> [String] {
        guard let lang = track.languageCode?.lowercased(), !lang.isEmpty else { return ["und"] }

        var keys: [String] = [lang]

        let isoMap: [String: String] = [
            "rus": "ru", "eng": "en", "ukr": "uk", "deu": "de", "fra": "fr",
            "spa": "es", "ita": "it", "jpn": "ja", "kor": "ko", "zho": "zh",
            "por": "pt", "pol": "pl", "tur": "tr",
        ]
        let reverseMap: [String: String] = [
            "ru": "rus", "en": "eng", "uk": "ukr", "de": "deu", "fr": "fra",
            "es": "spa", "it": "ita", "ja": "jpn", "ko": "kor", "zh": "zho",
            "pt": "por", "pl": "pol", "tr": "tur",
        ]

        if let alt = isoMap[lang] { keys.append(alt) }
        else if let alt = reverseMap[lang] { keys.append(alt) }

        return Array(Set(keys))
    }

    private static func normalizeGroupKey(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "_" : trimmed
    }

    private static func inferLanguageKey(languageAttribute: String, originalName: String) -> String {
        let attr = languageAttribute.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !attr.isEmpty { return attr }
        if let guessed = guessLanguageKey(fromName: originalName) { return guessed }
        return "und"
    }

    private static func guessLanguageKey(fromName name: String) -> String? {
        let s = name.lowercased()
        if s.contains("(rus)") || s.contains(" rus") || s.contains("russian") { return "ru" }
        if s.contains("(eng)") || s.contains(" eng") || s.contains("english") { return "en" }
        if s.contains("(ukr)") || s.contains(" ukr") || s.contains("ukrain") { return "uk" }
        return nil
    }

    private static func matchTrackByIndex(
        fromOriginalName name: String, allTracksSorted: [HLSAudioTrackInfo]
    ) -> HLSAudioTrackInfo? {
        guard let explicit = parseLeadingIndex(from: name) else { return nil }
        let candidates = [explicit, explicit - 1].filter { $0 >= 0 }
        for idx in candidates {
            if let match = allTracksSorted.first(where: { $0.index == idx }) { return match }
        }
        return nil
    }

    private static func parseLeadingIndex(from name: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var digits = ""
        for c in trimmed {
            if c.isNumber { digits.append(c); if digits.count > 3 { return nil }; continue }
            if c == "." || c == ")" || c == ":" { break }
            return nil
        }
        guard !digits.isEmpty, let value = Int(digits), value <= 255 else { return nil }
        return value
    }

    // MARK: - URI resolution

    private static func makeAbsoluteURIString(_ uri: String, relativeTo masterURL: URL) -> String {
        let trimmed = uri.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return uri }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        if trimmed.hasPrefix("//") {
            return "\(masterURL.scheme ?? "https"):\(trimmed)"
        }
        let base = masterURL.deletingLastPathComponent()
        if let resolved = URL(string: trimmed, relativeTo: base)?.absoluteURL {
            return resolved.absoluteString
        }
        return trimmed
    }

    // MARK: - Attribute parsing

    private static func parseAttributeList(_ text: String) -> [String: String] {
        var result: [String: String] = [:]
        var i = text.startIndex

        func skipSeparators() {
            while i < text.endIndex {
                let c = text[i]
                if c == "," || c == " " { i = text.index(after: i) } else { break }
            }
        }

        while i < text.endIndex {
            skipSeparators()
            if i >= text.endIndex { break }
            let keyStart = i
            while i < text.endIndex, text[i] != "=" { i = text.index(after: i) }
            if i >= text.endIndex { break }
            let key = String(text[keyStart..<i]).trimmingCharacters(in: .whitespacesAndNewlines)
            i = text.index(after: i)

            if i < text.endIndex, text[i] == "\"" {
                var value = "\""
                i = text.index(after: i)
                var isEscaped = false
                while i < text.endIndex {
                    let c = text[i]
                    value.append(c)
                    i = text.index(after: i)
                    if isEscaped { isEscaped = false; continue }
                    if c == "\\" { isEscaped = true; continue }
                    if c == "\"" { break }
                }
                result[key] = value
            } else {
                let valueStart = i
                while i < text.endIndex, text[i] != "," { i = text.index(after: i) }
                let value = String(text[valueStart..<i]).trimmingCharacters(in: .whitespacesAndNewlines)
                result[key] = value
            }

            if i < text.endIndex, text[i] == "," { i = text.index(after: i) }
        }
        return result
    }

    private static func serializeAttributeList(_ attrs: [String: String]) -> String {
        let preferredOrder = [
            "TYPE", "GROUP-ID", "NAME", "LANGUAGE", "DEFAULT", "AUTOSELECT",
            "FORCED", "CHARACTERISTICS", "CHANNELS", "URI",
        ]
        var keys = Array(attrs.keys)
        keys.sort { a, b in
            let ia = preferredOrder.firstIndex(of: a) ?? Int.max
            let ib = preferredOrder.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
        return keys.compactMap { key in
            guard let value = attrs[key] else { return nil }
            return "\(key)=\(value)"
        }.joined(separator: ",")
    }

    private static func serializeStreamInfAttributeList(_ attrs: [String: String]) -> String {
        let preferredOrder = [
            "BANDWIDTH", "AVERAGE-BANDWIDTH", "RESOLUTION", "FRAME-RATE", "CODECS",
            "VIDEO-RANGE", "HDCP-LEVEL", "AUDIO", "SUBTITLES", "CLOSED-CAPTIONS", "VIDEO",
        ]
        var keys = Array(attrs.keys)
        keys.sort { a, b in
            let ia = preferredOrder.firstIndex(of: a) ?? Int.max
            let ib = preferredOrder.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
        return keys.compactMap { key in
            guard let value = attrs[key] else { return nil }
            return "\(key)=\(value)"
        }.joined(separator: ",")
    }

    private static func unquoteAttributeValue(_ value: String) -> String {
        var v = value
        if v.hasPrefix("\"") && v.hasSuffix("\"") && v.count >= 2 {
            v.removeFirst()
            v.removeLast()
        }
        v = v.replacingOccurrences(of: "\\\"", with: "\"")
        v = v.replacingOccurrences(of: "\\\\", with: "\\")
        return v
    }

    private static func quoteAttributeValue(_ value: String) -> String {
        var v = value
        v = v.replacingOccurrences(of: "\\", with: "\\\\")
        v = v.replacingOccurrences(of: "\"", with: "\\\"")
        v = v.replacingOccurrences(of: "\n", with: " ")
        v = v.replacingOccurrences(of: "\r", with: " ")
        return "\"\(v)\""
    }
}
