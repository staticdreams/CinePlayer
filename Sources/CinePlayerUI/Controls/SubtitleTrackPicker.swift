import CinePlayerCore
import SwiftUI

/// Dedicated subtitle track picker sheet.
public struct SubtitleTrackPicker: View {
    let tracks: [any PlayerSubtitleTrack]
    let selectedIndex: Int?
    let subtitlesOff: Bool
    let onSelect: (Int) -> Void
    let onDisable: () -> Void
    let onDismiss: () -> Void

    public init(
        tracks: [any PlayerSubtitleTrack],
        selectedIndex: Int?,
        subtitlesOff: Bool,
        onSelect: @escaping (Int) -> Void,
        onDisable: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.tracks = tracks
        self.selectedIndex = selectedIndex
        self.subtitlesOff = subtitlesOff
        self.onSelect = onSelect
        self.onDisable = onDisable
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            List {
                // Off option
                Button {
                    onDisable()
                } label: {
                    HStack {
                        Text("Off")
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
            }
            .navigationTitle("Subtitles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
