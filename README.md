<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png" width="80" height="80" alt="SwiftUI">
</p>

<h1 align="center">CinePlayer</h1>

<p align="center">
  <strong>A modular, Apple-style video player for SwiftUI</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS_17+-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square" alt="Swift">
  <img src="https://img.shields.io/badge/Swift_6-Strict_Concurrency-green?style=flat-square" alt="Concurrency">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="License">
</p>

---

CinePlayer is a Swift Package that delivers a full-featured video player with glass-morphism controls inspired by Apple's native player. Built entirely with SwiftUI and AVFoundation, it provides a drop-in player view with rich track selection, HLS manifest rewriting, Picture-in-Picture, AirPlay, Now Playing integration, and more.

## Features

- **Apple-style glass UI** — `ultraThinMaterial` backgrounds on all controls, gradient overlays, smooth animations
- **Playback controls** — Play/pause, skip forward/back (10s), seekable progress bar with drag interaction
- **Playback speed** — 0.5x to 2x with customizable speed options, visual indicator for non-standard rates
- **Audio track picker** — Protocol-based, supports rich display names (e.g. "Russian — Dubbing (LostFilm) AAC 2ch")
- **Subtitle picker** — Protocol-based with on/off toggle and language labels
- **HLS manifest interception** — Rewrites `#EXT-X-MEDIA` names in master playlists for human-readable audio track labels
- **Picture-in-Picture** — Full PiP lifecycle management via `PiPManager`
- **AirPlay** — Native `AVRoutePickerView` wrapped for SwiftUI
- **Now Playing** — Lock screen / Control Center integration with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`
- **Auto-hide controls** — Configurable timeout (default 4s), tap to show/hide
- **Double-tap zoom** — Toggle between aspect fit and aspect fill
- **Debug stats overlay** — Resolution, bitrate, codecs, buffer, dropped frames, stall count
- **Loop mode** — Seamless looping for short-form content
- **Resume playback** — Start from any position with `startTime`
- **Callbacks** — Progress updates (every 500ms) and playback end notifications
- **Modular architecture** — Import only the modules you need
- **Swift 6 ready** — Full Strict Concurrency compliance with `@MainActor`, `Sendable`, and `@Observable`

## Architecture

CinePlayer is split into five focused modules:

```
CinePlayer (umbrella)
├── CinePlayerCore      — Engine, state, configuration, track protocols, HLS rewriting
├── CinePlayerUI        — SwiftUI views, controls overlay, track pickers, stats
├── CinePlayerPiP       — Picture-in-Picture manager
├── CinePlayerAirPlay   — AirPlay route picker
└── CinePlayerNowPlaying — Now Playing info & remote commands
```

| Module | Dependencies | Description |
|--------|-------------|-------------|
| `CinePlayerCore` | — | Player engine, state management, track protocols, HLS interceptor |
| `CinePlayerUI` | `CinePlayerCore` | Full player view with controls, pickers, gestures |
| `CinePlayerPiP` | `CinePlayerCore` | `AVPictureInPictureController` lifecycle |
| `CinePlayerAirPlay` | — | SwiftUI wrapper for `AVRoutePickerView` |
| `CinePlayerNowPlaying` | `CinePlayerCore` | `MPNowPlayingInfoCenter` + remote commands |

## Installation

### Swift Package Manager

Add CinePlayer to your Xcode project:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select the version or branch

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/CinePlayer.git", from: "1.0.0")
]
```

Then add the products to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        // Full package (all modules)
        .product(name: "CinePlayer", package: "CinePlayer"),

        // Or pick individual modules
        .product(name: "CinePlayerCore", package: "CinePlayer"),
        .product(name: "CinePlayerUI", package: "CinePlayer"),
    ]
)
```

### Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 17.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |

## Quick Start

The simplest way to use CinePlayer — a single line of SwiftUI:

```swift
import CinePlayerUI

struct PlayerScreen: View {
    var body: some View {
        CinePlayerView(url: URL(string: "https://example.com/video.mp4")!)
    }
}
```

Present it fullscreen:

```swift
.fullScreenCover(isPresented: $showPlayer) {
    CinePlayerView(url: videoURL)
        .title("My Video")
}
```

## Usage

### Configuration

Customize the player with `PlayerConfiguration`:

```swift
let config = PlayerConfiguration(
    startTime: 120,                     // Resume at 2 minutes
    autoPlay: true,                     // Start playing immediately
    loop: false,                        // Don't loop
    speeds: PlaybackSpeed.standard,     // 0.5x - 2x
    gravity: .resizeAspect              // Letterbox (default)
)

CinePlayerView(url: videoURL, configuration: config)
```

### View Modifiers

CinePlayer provides a SwiftUI-native modifier API:

```swift
CinePlayerView(url: videoURL)
    .title("Episode 1 — The Beginning")
    .startTime(savedPosition)
    .videoGravity(.resizeAspectFill)
    .loop(true)
    .onProgressUpdate { currentTime, duration in
        // Save position for resume, update UI, etc.
        savedPosition = currentTime
    }
    .onPlaybackEnd {
        // Play next episode, dismiss player, etc.
        showPlayer = false
    }
```

### Audio Tracks

Provide rich audio track metadata by conforming to `PlayerAudioTrack`:

```swift
import CinePlayerCore

struct MyAudioTrack: PlayerAudioTrack {
    var id: String
    var language: String?
    var displayName: String
    var isDefault: Bool
}

let tracks = [
    MyAudioTrack(id: "0", language: "en", displayName: "English — Original", isDefault: false),
    MyAudioTrack(id: "1", language: "ru", displayName: "Russian — Dubbing (LostFilm) AAC 2ch", isDefault: true),
    MyAudioTrack(id: "2", language: "ru", displayName: "Russian — Dubbing (Kuraj-Bambey) AAC 2ch", isDefault: false),
]

CinePlayerView(url: videoURL)
    .audioTracks(tracks)
```

CinePlayer automatically matches your tracks to `AVMediaSelectionOption` entries by language code and position, with built-in ISO 639-1/639-2 cross-mapping (e.g. `"rus"` matches `"ru"`).

### Subtitle Tracks

Similarly, conform to `PlayerSubtitleTrack`:

```swift
struct MySubtitleTrack: PlayerSubtitleTrack {
    var id: String
    var language: String?
    var displayName: String
    var isForced: Bool
}

CinePlayerView(url: videoURL)
    .subtitleTracks([
        MySubtitleTrack(id: "0", language: "en", displayName: "English", isForced: false),
        MySubtitleTrack(id: "1", language: "ru", displayName: "Russian", isForced: false),
    ])
```

### HLS Manifest Rewriting

For HLS streams, CinePlayer can intercept the master playlist and rewrite `#EXT-X-MEDIA` audio track names with your rich labels. This makes the native system picker (and any custom picker) display meaningful names instead of raw codec identifiers:

```swift
let hlsTracks = [
    HLSAudioTrackInfo(index: 0, languageCode: "en", displayName: "English — Original"),
    HLSAudioTrackInfo(index: 1, languageCode: "ru", displayName: "Russian — Dubbing"),
]

CinePlayerView(url: hlsURL)
    .hlsAudioTracks(hlsTracks)
```

The interceptor uses a custom URL scheme (`cineplayer-hls://`) with `AVAssetResourceLoaderDelegate` to transparently rewrite the manifest before AVPlayer processes it.

### Picture-in-Picture

Use `PiPManager` for Picture-in-Picture support:

```swift
import CinePlayerPiP

@State private var pipManager = PiPManager()

// Configure after player layer is ready
pipManager.configure(with: playerLayer, canStartAutomatically: true)

// Toggle PiP
pipManager.toggle()

// Observe state
if pipManager.isPiPActive { ... }
if pipManager.isPiPPossible { ... }

// Clean up
pipManager.tearDown()
```

### AirPlay

Drop in the AirPlay button anywhere in your UI:

```swift
import CinePlayerAirPlay

AirPlayButton()
    .frame(width: 44, height: 44)
```

### Now Playing (Lock Screen / Control Center)

Integrate with the system media controls:

```swift
import CinePlayerNowPlaying

let nowPlaying = NowPlayingManager()

// Configure with player engine and metadata
nowPlaying.configure(
    engine: playerEngine,
    title: "Episode Title",
    artist: "Show Name",
    artwork: posterImage
)

// Update periodically (e.g. in onProgressUpdate callback)
nowPlaying.updateNowPlayingInfo(
    title: "Episode Title",
    artist: "Show Name",
    engine: playerEngine
)

// Clean up when done
nowPlaying.tearDown()
```

This automatically registers remote commands: play, pause, skip forward/backward (10s), and scrub/seek.

### Using PlayerEngine Directly

For full control, use `PlayerEngine` without `CinePlayerView`:

```swift
import CinePlayerCore

@State private var engine = PlayerEngine(
    url: videoURL,
    configuration: PlayerConfiguration(startTime: 60)
)

// Lifecycle
engine.activate()    // Call in .onAppear or .task
engine.deactivate()  // Call in .onDisappear

// Playback
engine.play()
engine.pause()
engine.togglePlayPause()
engine.seek(to: 90.0)
engine.skipForward(15)
engine.skipBackward(15)
engine.setSpeed(PlaybackSpeed(rate: 1.5, localizedName: "1.5x"))
engine.toggleZoom()

// State observation (via @Observable)
engine.state.currentTime     // TimeInterval
engine.state.duration        // TimeInterval
engine.state.progress        // Double (0...1)
engine.state.remainingTime   // TimeInterval
engine.state.isPlaying       // Bool
engine.state.isBuffering     // Bool
engine.state.status          // .unknown | .readyToPlay | .failed
engine.state.error           // PlayerError?

// Track selection
engine.selectAudioTrack(myTrack)
engine.selectSubtitleTrack(mySubtitle)

// Swap video source on the fly
engine.replaceURL(newVideoURL)

// Callbacks
engine.onProgressUpdate = { currentTime, duration in ... }
engine.onPlaybackEnd = { ... }
```

### Playback Stats (Debug)

Enable stats collection for debugging:

```swift
engine.isCollectingStats = true

// Read stats
engine.stats.resolution       // "1920x1080"
engine.stats.videoCodec        // "avc1"
engine.stats.audioCodec        // "mp4a"
engine.stats.avgBitrate        // "4.2 Mbps"
engine.stats.currentBitrate    // "5.1 Mbps"
engine.stats.bufferedDuration  // "12.34 s"
engine.stats.droppedFrames     // "0"
engine.stats.stallCount        // "0"
```

Or use the built-in overlay view:

```swift
import CinePlayerUI

StatsOverlayView(stats: engine.stats)
```

## UI Controls Overview

The built-in `CinePlayerView` includes a complete Apple-style control overlay:

```
┌─────────────────────────────────────────────────┐
│ [X]  [PiP][AirPlay]                            │  <- Top bar (glass)
│                                                  │
│                                                  │
│          [ << ]   [ ▶ ]   [ >> ]                │  <- Center controls (glass circles)
│                                                  │
│                                                  │
│  Episode Title              [Speed][🎵][CC]     │  <- Bottom bar
│  ┌──────────────────────────────────────────┐   │
│  │ 0:12:34  ━━━━━━━━●━━━━━━━━  -0:45:26   │   │  <- Progress bar (glass pill)
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

| Control | Action |
|---------|--------|
| **X** button | Dismiss player |
| **PiP** button | Enter Picture-in-Picture |
| **AirPlay** button | Show AirPlay picker |
| **Skip back** | Jump back 10 seconds |
| **Play/Pause** | Toggle playback |
| **Skip forward** | Jump forward 10 seconds |
| **Speed** icon | Menu picker (0.5x - 2x) |
| **Audio** icon | Audio track picker sheet |
| **Subtitles** icon | Subtitle picker sheet |
| **Progress bar** | Drag to seek, shows elapsed/remaining time |
| **Tap anywhere** | Show/hide controls |
| **Double-tap** | Toggle zoom (fit/fill) |

Controls auto-hide after 4 seconds of inactivity and reappear on any interaction.

## Type Reference

### PlayerConfiguration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `startTime` | `TimeInterval` | `0` | Resume position in seconds |
| `autoPlay` | `Bool` | `true` | Start playback when ready |
| `loop` | `Bool` | `false` | Loop video at end |
| `speeds` | `[PlaybackSpeed]` | `PlaybackSpeed.standard` | Available speed options |
| `gravity` | `VideoGravity` | `.resizeAspect` | Video display mode |

### PlayerState

| Property | Type | Description |
|----------|------|-------------|
| `currentTime` | `TimeInterval` | Current position in seconds |
| `duration` | `TimeInterval` | Total duration (0 for live) |
| `progress` | `Double` | Position as fraction (0...1) |
| `remainingTime` | `TimeInterval` | Time remaining |
| `isPlaying` | `Bool` | Currently playing |
| `isBuffering` | `Bool` | Currently buffering |
| `didFinishPlaying` | `Bool` | Reached the end |
| `rate` | `Float` | Current playback rate |
| `status` | `ItemStatus` | `.unknown` / `.readyToPlay` / `.failed` |
| `error` | `PlayerError?` | Last error, if any |

### PlayerError

| Case | Description |
|------|-------------|
| `.invalidURL` | The provided URL is invalid |
| `.playerItemFailed(underlying:)` | AVPlayerItem failed with error |
| `.assetLoadFailed(underlying:)` | Asset loading failed |
| `.seekFailed` | Seek operation failed |
| `.trackSelectionFailed` | Track selection failed |

### VideoGravity

| Case | AVFoundation Equivalent | Description |
|------|------------------------|-------------|
| `.resizeAspect` | `.resizeAspect` | Letterbox (default) |
| `.resizeAspectFill` | `.resizeAspectFill` | Fill, may crop |
| `.resize` | `.resize` | Stretch to fill |

## License

MIT License. See [LICENSE](LICENSE) for details.
