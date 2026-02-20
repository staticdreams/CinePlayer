# CLAUDE.md

This file provides guidance to Claude Code when working with the CinePlayer Swift Package.

## Project Overview

CinePlayer is a modular, full-featured video player built entirely with SwiftUI and AVFoundation. It replaces `AVPlayerViewController` with custom glass-morphism controls, supporting Picture-in-Picture, AirPlay, Now Playing, HLS manifest rewriting, and live stream detection. It is a standalone Swift Package with no external dependencies.

## Build & Test

```bash
# Build
swift build

# Run tests (Swift Testing framework)
swift test

# Build via Xcode
xcodebuild -scheme CinePlayer -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

- **Platform**: iOS 17.0+
- **Swift tools version**: 5.9
- **Swift language mode**: 6.0 (Strict Concurrency)
- **Test framework**: Swift Testing (`@Test`, `#expect`)
- **No external dependencies** — only AVFoundation, Combine, MediaPlayer, UIKit

## Architecture

Five focused modules with clear dependency boundaries:

```
CinePlayerCore       (no deps)        — Engine, state, config, track protocols, HLS rewriting, localization
CinePlayerUI         (Core, PiP, NP)  — SwiftUI views, controls overlay, pickers, gestures, stats
CinePlayerPiP        (Core)           — AVPictureInPictureController lifecycle
CinePlayerAirPlay    (no deps)        — SwiftUI wrapper for AVRoutePickerView
CinePlayerNowPlaying (Core)           — MPNowPlayingInfoCenter + remote commands
```

### Core Pattern: Observable + @MainActor

All mutable state classes use `@Observable @MainActor`. All public value types conform to `Sendable`.

```swift
@Observable @MainActor public final class PlayerEngine { ... }
@Observable @MainActor public final class TrackState { ... }
@Observable @MainActor public final class PiPManager { ... }
```

### Three-Layer State Model

1. **PlayerState** — Read-only Sendable struct. Holds currentTime, duration, isPlaying, isBuffering, isLive, etc. Owned by PlayerEngine, observed by UI.
2. **TrackState** — @Observable @MainActor class. Manages track discovery, matching protocol tracks to AVMediaSelectionOptions, and applying selections.
3. **PlayerEngine** — @Observable @MainActor class. Owns AVPlayer, orchestrates lifecycle (activate/deactivate), exposes control methods (play, seek, skip, etc.).

## Key Types

| Type | Kind | Role |
|------|------|------|
| `PlayerEngine` | @Observable class | Core playback engine, owns AVPlayer |
| `PlayerState` | Sendable struct | Read-only playback state |
| `TrackState` | @Observable class | Track discovery and selection |
| `PlayerConfiguration` | Sendable struct | Startup config (startTime, autoPlay, loop, speeds, gravity) |
| `PlayerAudioTrack` | Protocol (Sendable) | Custom audio track metadata |
| `PlayerSubtitleTrack` | Protocol (Sendable) | Custom subtitle track metadata |
| `PlayerLocalization` | Sendable struct | 29 user-facing strings |
| `PlayerStats` | Sendable struct | Video/audio/network statistics |
| `PlayerTitleInfo` | Sendable struct | Rich title display (title, subtitle, metadata) |
| `HLSAudioTrackInfo` | Sendable struct | HLS manifest rewriting metadata |
| `CinePlayerView` | SwiftUI View | Main public player view |

## Concurrency Patterns

This package uses **Swift 6 Strict Concurrency**. All code must be data-race safe.

- **@MainActor** on class declarations (not individual methods)
- **Sendable** on all public value types and protocols
- **async/await** for asset loading, track discovery, stats collection
- **MainActor.assumeIsolated { }** in AVPlayer callbacks from background threads
- **@unchecked Sendable** only on `HLSManifestInterceptor` (NSObject subclass requiring it)
- **[weak self]** in all closures; explicit cleanup in `deactivate()` and `deinit`

## HLS Manifest Interception

For HLS streams, CinePlayer can rewrite `#EXT-X-MEDIA` audio track names:

1. Host provides `[HLSAudioTrackInfo]` via `.hlsAudioTracks()` modifier
2. `PlayerEngine` stores them as `pendingHLSAudioTracks`
3. `activate()` creates AVURLAsset via `HLSManifestInterceptor.makeAsset()`
4. Interceptor registers custom URL scheme (`cineplayer-hls://`)
5. When AVPlayer requests master playlist, interceptor fetches it over HTTPS
6. `HLSPlaylistRewriter` rewrites `NAME=` attributes and resolves relative URIs
7. Modified playlist returned to AVPlayer transparently

## Localization

`PlayerLocalization` holds 29 user-facing strings. Ships with English and Russian.

To add a language, create an extension:

```swift
extension PlayerLocalization {
    public static let ukrainian = PlayerLocalization(
        playbackSpeed: "Швидкість",
        audio: "Аудіо",
        // ... all 29 properties
    )
}
```

Then add a case in `PlayerLocalization.init(languageCode:)`.

## File Organization

```
Sources/
├── CinePlayerCore/
│   ├── PlayerEngine.swift              # Main engine (@Observable, @MainActor)
│   ├── PlayerState.swift               # Read-only playback state (Sendable)
│   ├── PlayerConfiguration.swift       # Configuration (Sendable)
│   ├── Types/
│   │   ├── PlayerError.swift           # Error enum (LocalizedError)
│   │   ├── PlaybackSpeed.swift         # Speed options
│   │   ├── PlayerStats.swift           # Statistics collection
│   │   ├── PlayerTitleInfo.swift        # Title display metadata
│   │   ├── SubtitleFontSize.swift       # Font size options
│   │   ├── UpNextItem.swift            # "Coming up next" data
│   │   └── VideoGravity.swift          # Display modes
│   ├── TrackSelection/
│   │   ├── PlayerAudioTrack.swift      # Audio track protocol
│   │   ├── PlayerSubtitleTrack.swift   # Subtitle track protocol
│   │   ├── TrackState.swift            # Track management (@Observable)
│   │   └── TrackMatcher.swift          # Language + position matching
│   ├── HLS/
│   │   ├── HLSManifestInterceptor.swift # AVAssetResourceLoaderDelegate
│   │   ├── HLSPlaylistRewriter.swift    # Playlist manipulation
│   │   └── HLSInterceptorScheme.swift   # Custom scheme constant
│   ├── Localization/
│   │   ├── PlayerLocalization.swift     # Base struct (29 strings)
│   │   ├── PlayerLocalization+en.swift  # English
│   │   └── PlayerLocalization+ru.swift  # Russian
│   └── Observation/
│       ├── PlayerItemObserver.swift     # KVO + NotificationCenter
│       ├── TimeObserver.swift           # Periodic time updates
│       └── AccessLogObserver.swift      # Access log stats
├── CinePlayerUI/
│   ├── CinePlayerView.swift            # Main public view
│   ├── Controls/
│   │   ├── ControlsOverlay.swift       # Controls container + auto-hide
│   │   ├── TopBar.swift                # Close, PiP, AirPlay, volume
│   │   ├── BottomBar.swift             # Title, menu, progress bar
│   │   ├── CenterControls.swift        # Skip, play/pause
│   │   ├── ProgressBar.swift           # Seekable timeline
│   │   ├── VolumeControl.swift         # Volume slider + mute
│   │   ├── AudioTrackPicker.swift      # Audio selection sheet
│   │   ├── SubtitleTrackPicker.swift   # Subtitle selection sheet
│   │   ├── SpeedPicker.swift           # Speed selection
│   │   ├── ControlsVisibility.swift    # Auto-hide timer
│   │   └── GlassBackground.swift       # Glass morphism effect
│   ├── VideoSurface/
│   │   ├── VideoSurfaceView.swift      # UIViewRepresentable
│   │   └── VideoSurfaceUIView.swift    # UIView with AVPlayerLayer
│   ├── Gestures/
│   │   └── PlayerGestureHandler.swift  # Tap, double-tap gestures
│   ├── Stats/
│   │   └── StatsOverlayView.swift      # Debug stats overlay
│   └── UpNext/
│       └── UpNextOverlay.swift         # "Coming up next" banner
├── CinePlayerPiP/
│   └── PiPManager.swift                # PiP lifecycle
├── CinePlayerAirPlay/
│   └── AirPlayButton.swift             # AVRoutePickerView wrapper
└── CinePlayerNowPlaying/
    └── NowPlayingManager.swift         # Lock screen + remote commands

Tests/
└── CinePlayerCoreTests/
    └── CinePlayerCoreTests.swift       # Swift Testing (@Test, #expect)
```

## Code Style

- **Indentation**: 4 spaces
- **Types**: `UpperCamelCase` — files match primary type
- **Variables/methods**: `lowerCamelCase`
- **Booleans**: `is`/`did` prefix (`isPlaying`, `didFinishPlaying`)
- **Callbacks**: `on` prefix (`onProgressUpdate`, `onPlaybackEnd`)
- **Sections**: `// MARK: - Section Name`
- **Public before private** within each section
- **Doc comments** (`///`) on public types and methods; minimal internal comments
- **Memory management**: `[weak self]` in closures, explicit cleanup in `deactivate()`/`deinit`, stored observation tokens for deallocation
- **Error handling**: early `guard` returns, associated-value errors with `LocalizedError`
- **No external dependencies** — keep it that way
