import CinePlayerCore
import SwiftUI

/// Dedicated subtitle track picker sheet.
public struct SubtitleTrackPicker: View {
    let tracks: [any PlayerSubtitleTrack]
    let selectedIndex: Int?
    let subtitlesOff: Bool
    let localization: PlayerLocalization
    let onSelect: (Int) -> Void
    let onDisable: () -> Void
    let onDismiss: () -> Void
    var onSearchOnline: (() -> Void)?
    var hasExternalSubtitle: Bool = false
    var onRemoveExternal: (() -> Void)?

    public init(
        tracks: [any PlayerSubtitleTrack],
        selectedIndex: Int?,
        subtitlesOff: Bool,
        localization: PlayerLocalization = .english,
        onSelect: @escaping (Int) -> Void,
        onDisable: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onSearchOnline: (() -> Void)? = nil,
        hasExternalSubtitle: Bool = false,
        onRemoveExternal: (() -> Void)? = nil
    ) {
        self.tracks = tracks
        self.selectedIndex = selectedIndex
        self.subtitlesOff = subtitlesOff
        self.localization = localization
        self.onSelect = onSelect
        self.onDisable = onDisable
        self.onDismiss = onDismiss
        self.onSearchOnline = onSearchOnline
        self.hasExternalSubtitle = hasExternalSubtitle
        self.onRemoveExternal = onRemoveExternal
    }

    public var body: some View {
        NavigationStack {
            List {
                // Off option
                Button {
                    onDisable()
                } label: {
                    HStack {
                        Text(localization.off)
                            .foregroundStyle(.primary)
                        Spacer()
                        if subtitlesOff {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }

                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Button {
                        onSelect(index)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.displayName)
                                    .foregroundStyle(.primary)

                                if let lang = track.language {
                                    Text(lang.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if !subtitlesOff && selectedIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                // Active external subtitle
                if hasExternalSubtitle {
                    Section {
                        HStack {
                            Label(localization.externalSubtitleActive, systemImage: "globe")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }

                        Button(role: .destructive) {
                            onRemoveExternal?()
                        } label: {
                            Label(localization.removeExternalSubtitles, systemImage: "xmark.circle")
                        }
                    }
                }

                if let onSearchOnline {
                    Section {
                        Button {
                            onSearchOnline()
                        } label: {
                            Label(localization.searchOnlineSubtitles, systemImage: "magnifyingglass")
                        }
                    }
                }
            }
            .navigationTitle(localization.subtitles)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.done, action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
