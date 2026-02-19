import CinePlayerCore
import SwiftUI

/// Dedicated audio track picker sheet with rich labels.
/// Shows only the tracks provided by the host app.
public struct AudioTrackPicker: View {
    let tracks: [any PlayerAudioTrack]
    let selectedIndex: Int?
    let localization: PlayerLocalization
    let onSelect: (Int) -> Void
    let onDismiss: () -> Void

    public init(
        tracks: [any PlayerAudioTrack],
        selectedIndex: Int?,
        localization: PlayerLocalization = .english,
        onSelect: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.tracks = tracks
        self.selectedIndex = selectedIndex
        self.localization = localization
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            List {
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

                            if selectedIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(localization.audio)
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
