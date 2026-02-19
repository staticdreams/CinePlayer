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

CinePlayer is a Swift Package that delivers a full-featured video player built entirely with SwiftUI and AVFoundation. It replaces `AVPlayerViewController` with custom glass-morphism controls, giving you complete control over track selection, title display, and UI layout while supporting Picture-in-Picture, AirPlay, and Now Playing integration out of the box.

## Features

- **Glass-morphism controls** — `ultraThinMaterial` backgrounds with iOS 26 `glassEffect` support, smooth fade animations
- **Adaptive layout** — Portrait shows a compact menu; landscape shows all controls inline in a pill
- **Playback controls** — Play/pause, skip forward/back (10s), seekable progress bar with drag interaction
- **Playback speed** — 0.5x to 2x in 0.25x increments, inline speed picker
- **Audio track picker** — Protocol-based with rich display names (e.g. "Russian -- Dubbing (LostFilm) AAC 2ch")
- **Subtitle picker** — Protocol-based with on/off toggle; auto-discovers subtitles from media when none provided
- **Rich title display** — Up to three lines: primary title, subtitle, metadata components joined with " . "
- **HLS manifest interception** — Rewrites `#EXT-X-MEDIA` names in master playlists for human-readable audio labels
- **Picture-in-Picture** — Built into the player view, also available as standalone `PiPManager`
- **AirPlay** — Native `AVRoutePickerView` integrated in the top bar
- **Volume control** — Expandable volume slider with mute toggle in the top bar
- **Now Playing** — Lock screen / Control Center integration via `NowPlayingManager`
- **Auto-hide controls** — 4-second timeout, tap to show/hide, timer resets on interaction
- **Double-tap zoom** — Toggle between aspect fit and aspect fill
- **Stats overlay** — Toggleable via button; shows resolution, codecs, FPS, bitrate, buffer, stalls, active tracks
- **Loop mode** — Seamless looping for short-form content
- **Resume playback** — Start from any position with `startTime`
- **Callbacks** — Progress updates (every 500ms) and playback end notifications
- **Modular architecture** — Import only the modules you need
- **Swift 6 ready** — Full Strict Concurrency compliance with `@MainActor`, `Sendable`, and `@Observable`

## Architecture

CinePlayer is split into five focused modules:

```
CinePlayer (umbrella)
+-- CinePlayerCore       -- Engine, state, configuration, track protocols, HLS rewriting
+-- CinePlayerUI         -- SwiftUI views, controls overlay, track pickers, stats
+-- CinePlayerPiP        -- Picture-in-Picture manager
+-- CinePlayerAirPlay    -- AirPlay route picker
+-- CinePlayerNowPlaying -- Now Playing info & remote commands
```

| Module                 | Dependencies                  | Description                                                       |
| ---------------------- | ----------------------------- | ----------------------------------------------------------------- |
| `CinePlayerCore`       | --                            | Player engine, state management, track protocols, HLS interceptor |
| `CinePlayerUI`         | `CinePlayerCore`, `CinePlayerPiP` | Full player view with controls, pickers, gestures, stats     |
| `CinePlayerPiP`        | `CinePlayerCore`              | `AVPictureInPictureController` lifecycle                          |
| `CinePlayerAirPlay`    | --                            | SwiftUI wrapper for `AVRoutePickerView`                           |
| `CinePlayerNowPlaying` | `CinePlayerCore`              | `MPNowPlayingInfoCenter` + remote commands                        |

## Installation

### Swift Package Manager

Add CinePlayer to your Xcode project:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select the version or branch

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/staticdreams/CinePlayer.git", from: "1.0.0")
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
| ----------- | ------- |
| iOS         | 17.0+   |
| Swift       | 5.9+    |
| Xcode       | 15.0+   |

## Quick Start

The simplest way to use CinePlayer -- a single line of SwiftUI:

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

### View Modifiers

CinePlayer provides a SwiftUI-native modifier API:

```swift
CinePlayerView(url: videoURL)
    .titleInfo(PlayerTitleInfo(
        title: "Episode Title",
        subtitle: "Original Title",
        metadata: ["S1E5", "2024", "Drama"]
    ))
    .startTime(savedPosition)
    .videoGravity(.resizeAspectFill)
    .loop(true)
    .onProgressUpdate { currentTime, duration in
        savedPosition = currentTime
    }
    .onPlaybackEnd {
        showPlayer = false
    }
```

### Title Display

CinePlayer renders up to three lines of title information:

```swift
// Simple -- single line
CinePlayerView(url: url)
    .title("My Movie")

// Rich -- up to three lines
CinePlayerView(url: url)
    .titleInfo(PlayerTitleInfo(
        title: "My Movie",                        // Line 1: bold, largest
        subtitle: "Original Title",                // Line 2: medium weight, smaller (optional)
        metadata: ["S1E5", "2024", "Drama"]        // Line 3: regular, smallest, joined with " . " (optional)
    ))
```

`PlayerTitleInfo` is generic -- `title`, `subtitle`, and `metadata` can hold any content your app needs.

### Configuration

Customize the player with `PlayerConfiguration`:

```swift
let config = PlayerConfiguration(
    startTime: 120,                     // Resume at 2 minutes
    autoPlay: true,                     // Start playing immediately (default)
    loop: false,                        // Don't loop (default)
    speeds: PlaybackSpeed.standard,     // 0.5x - 2x in 0.25x increments
    gravity: .resizeAspect              // Letterbox (default)
)

CinePlayerView(url: videoURL, configuration: config)
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
    MyAudioTrack(id: "0", language: "en", displayName: "English -- Original", isDefault: false),
    MyAudioTrack(id: "1", language: "ru", displayName: "Russian -- Dubbing (LostFilm) AAC 2ch", isDefault: true),
]

CinePlayerView(url: videoURL)
    .audioTracks(tracks)
```

CinePlayer matches your tracks to `AVMediaSelectionOption` entries by language code and position within each language group, with built-in ISO 639-1/639-2 cross-mapping (e.g. `"rus"` matches `"ru"`).

### Subtitle Tracks

Conform to `PlayerSubtitleTrack` for custom subtitle labels:

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

If you don't provide subtitle tracks, CinePlayer auto-discovers them from the media's `AVMediaSelectionGroup` and displays them with their native `displayName`.

### HLS Manifest Rewriting

For HLS streams, CinePlayer can intercept the master playlist and rewrite `#EXT-X-MEDIA` audio track names with your rich labels:

```swift
let hlsTracks = [
    HLSAudioTrackInfo(index: 0, languageCode: "en", displayName: "English -- Original"),
    HLSAudioTrackInfo(index: 1, languageCode: "ru", displayName: "Russian -- Dubbing"),
]

CinePlayerView(url: hlsURL)
    .hlsAudioTracks(hlsTracks)
```

The interceptor uses a custom URL scheme (`cineplayer-hls://`) with `AVAssetResourceLoaderDelegate` to transparently rewrite the manifest before AVPlayer processes it. It also resolves all relative URIs to absolute paths to prevent playback issues.

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

This registers remote commands: play, pause, skip forward/backward (10s), and seek to position.

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
engine.toggleMute()

// State observation (via @Observable)
engine.state.currentTime     // TimeInterval
engine.state.duration        // TimeInterval
engine.state.progress        // Double (0...1)
engine.state.remainingTime   // TimeInterval
engine.state.isPlaying       // Bool
engine.state.isBuffering     // Bool
engine.state.isMuted         // Bool
engine.state.rate            // Float
engine.state.status          // .unknown | .readyToPlay | .failed
engine.state.error           // PlayerError?

// Track selection
engine.trackState.audioTracks       // [any PlayerAudioTrack]
engine.trackState.subtitleTracks    // [any PlayerSubtitleTrack]
engine.selectAudioTrack(myTrack)
engine.selectSubtitleTrack(mySubtitle)

// Swap video source
engine.replaceURL(newVideoURL)

// Callbacks
engine.onProgressUpdate = { currentTime, duration in ... }
engine.onPlaybackEnd = { ... }
```

### Playback Stats

Enable stats collection for a debug overlay:

```swift
engine.isCollectingStats = true
```

Stats are organized into three sections:

**Video**: resolution, video codec, frame rate, playback rate, dropped frames

**Audio / Subtitles**: audio codec, active audio track, active subtitle

**Network**: average bitrate, current bitrate, observed bitrate, throughput, buffer duration, stall count, network type, stream type, source URI

Use the built-in overlay view:

```swift
import CinePlayerUI

StatsOverlayView(stats: engine.stats)
```

When using `CinePlayerView`, the stats overlay is accessible via the stats button in the bottom bar controls (chart icon).

## Controls Layout

The built-in `CinePlayerView` provides an adaptive control overlay:

### Portrait

```
+-------------------------------------------+
| [X] [PiP|AirPlay]           [Volume/Mute] |  <- Top bar
|                                            |
|           [<<]  [>]  [>>]                  |  <- Center controls
|                                            |
|  Episode Title                     [...]   |  <- Title + menu button
|  Original Title                            |
|  S1E5 . 2024 . Drama                      |
|  +--------------------------------------+  |
|  | 0:12:34  ----*---------- -0:45:26    |  |  <- Progress bar
|  +--------------------------------------+  |
+-------------------------------------------+
```

The `...` button opens a menu with: Playback Speed, Audio, Subtitles, Stats.

### Landscape

```
+--------------------------------------------------------------+
| [X] [PiP|AirPlay]                              [Volume/Mute] |
|                                                               |
|                  [<<]  [>]  [>>]                              |
|                                                               |
|  Episode Title            [Audio|1x|Subs|Stats]              |
|  Original Title                                               |
|  +----------------------------------------------------------+ |
|  | 0:12:34  -------*------------------------- -0:45:26      | |
|  +----------------------------------------------------------+ |
+--------------------------------------------------------------+
```

All controls are inline in landscape -- audio, speed, subtitles, and stats are individual buttons in a glass pill.

### Interactions

| Action               | Effect                              |
| -------------------- | ----------------------------------- |
| Tap anywhere         | Show/hide controls                  |
| Double-tap           | Toggle zoom (aspect fit/fill)       |
| Drag progress bar    | Seek to position                    |
| Skip buttons         | Jump forward/back 10 seconds        |
| Speed picker         | Select 0.5x - 2x playback rate     |
| Audio button         | Open audio track picker sheet       |
| Subtitles button     | Open subtitle picker sheet          |
| Stats button         | Toggle debug stats overlay          |
| PiP button           | Enter Picture-in-Picture            |
| Volume slider        | Adjust volume, tap icon to mute     |
| Close button         | Dismiss the player                  |

Controls auto-hide after 4 seconds of inactivity. Any interaction resets the timer. Opening a sheet or menu pauses the timer.

## Modifier Reference

| Modifier | Type | Description |
|----------|------|-------------|
| `.title(_:)` | `String` | Simple single-line title |
| `.titleInfo(_:)` | `PlayerTitleInfo` | Rich multi-line title with subtitle and metadata |
| `.audioTracks(_:)` | `[any PlayerAudioTrack]` | Audio tracks with rich display names |
| `.subtitleTracks(_:)` | `[any PlayerSubtitleTrack]` | Subtitle tracks (auto-discovered if omitted) |
| `.hlsAudioTracks(_:)` | `[HLSAudioTrackInfo]` | HLS manifest rewriting metadata |
| `.startTime(_:)` | `TimeInterval` | Resume position in seconds |
| `.videoGravity(_:)` | `VideoGravity` | Aspect fit, fill, or stretch |
| `.loop(_:)` | `Bool` | Loop video at end |
| `.onProgressUpdate(_:)` | `(TimeInterval, TimeInterval) -> Void` | Called every 500ms with (currentTime, duration) |
| `.onPlaybackEnd(_:)` | `() -> Void` | Called when video reaches the end |

## Type Reference

### PlayerTitleInfo

| Property   | Type       | Default | Description                                              |
| ---------- | ---------- | ------- | -------------------------------------------------------- |
| `title`    | `String`   | --      | Primary title (line 1), always shown                     |
| `subtitle` | `String?`  | `nil`   | Secondary line (line 2), hidden when nil or empty        |
| `metadata` | `[String]` | `[]`    | Tertiary detail components (line 3), joined with " . "   |

### PlayerConfiguration

| Property    | Type              | Default                  | Description                |
| ----------- | ----------------- | ------------------------ | -------------------------- |
| `startTime` | `TimeInterval`    | `0`                      | Resume position in seconds |
| `autoPlay`  | `Bool`            | `true`                   | Start playback when ready  |
| `loop`      | `Bool`            | `false`                  | Loop video at end          |
| `speeds`    | `[PlaybackSpeed]` | `PlaybackSpeed.standard` | Available speed options    |
| `gravity`   | `VideoGravity`    | `.resizeAspect`          | Video display mode         |

### PlayerState

| Property           | Type           | Description                             |
| ------------------ | -------------- | --------------------------------------- |
| `currentTime`      | `TimeInterval` | Current position in seconds             |
| `duration`         | `TimeInterval` | Total duration (0 for live)             |
| `progress`         | `Double`       | Position as fraction (0...1)            |
| `remainingTime`    | `TimeInterval` | Time remaining                          |
| `isPlaying`        | `Bool`         | Currently playing                       |
| `isBuffering`      | `Bool`         | Currently buffering                     |
| `isMuted`          | `Bool`         | Audio is muted                          |
| `didFinishPlaying` | `Bool`         | Reached the end                         |
| `rate`             | `Float`        | Current playback rate                   |
| `status`           | `ItemStatus`   | `.unknown` / `.readyToPlay` / `.failed` |
| `error`            | `PlayerError?` | Last error, if any                      |

### PlayerStats

| Property           | Section       | Description                              |
| ------------------ | ------------- | ---------------------------------------- |
| `resolution`       | Video         | Video dimensions (e.g. "1920x1080")      |
| `videoCodec`       | Video         | Video codec (e.g. "avc1", "hvc1")        |
| `videoFPS`         | Video         | Frame rate (e.g. "23.976 fps")           |
| `playbackRate`     | Video         | Current playback speed                   |
| `droppedFrames`    | Video         | Number of dropped video frames           |
| `audioCodec`       | Audio / Subs  | Audio codec (e.g. "mp4a")               |
| `audioTrack`       | Audio / Subs  | Active audio track name                  |
| `subtitleTrack`    | Audio / Subs  | Active subtitle track name               |
| `avgBitrate`       | Network       | Average indicated bitrate                |
| `currentBitrate`   | Network       | Current indicated bitrate                |
| `observedBitrate`  | Network       | Measured download bitrate                |
| `throughput`       | Network       | Network throughput                       |
| `bufferedDuration` | Network       | Seconds of buffered content              |
| `stallCount`       | Network       | Number of playback stalls                |
| `networkType`      | Network       | Connection type                          |
| `streamType`       | Network       | HLS / Local file                         |
| `uri`              | Network       | Source URL or file path                  |

### PlayerError

| Case                             | Description                    |
| -------------------------------- | ------------------------------ |
| `.invalidURL`                    | The provided URL is invalid    |
| `.playerItemFailed(underlying:)` | AVPlayerItem failed with error |
| `.assetLoadFailed(underlying:)`  | Asset loading failed           |
| `.seekFailed`                    | Seek operation failed          |
| `.trackSelectionFailed`          | Track selection failed         |

### VideoGravity

| Case                | AVFoundation Equivalent | Description         |
| ------------------- | ----------------------- | ------------------- |
| `.resizeAspect`     | `.resizeAspect`         | Letterbox (default) |
| `.resizeAspectFill` | `.resizeAspectFill`     | Fill, may crop      |
| `.resize`           | `.resize`               | Stretch to fill     |

### PlaybackSpeed

| Property        | Type     | Description                             |
| --------------- | -------- | --------------------------------------- |
| `rate`          | `Float`  | Playback rate multiplier                |
| `localizedName` | `String` | Display string (e.g. "1.5x")           |

`PlaybackSpeed.standard` provides: 0.5x, 0.75x, 1x, 1.25x, 1.5x, 1.75x, 2x.

### HLSAudioTrackInfo

| Property       | Type      | Description                                |
| -------------- | --------- | ------------------------------------------ |
| `index`        | `Int?`    | Track index in the manifest (for matching) |
| `languageCode` | `String?` | ISO-639 language code                      |
| `displayName`  | `String`  | Rich name to write into the playlist       |

## License

MIT License. See [LICENSE](LICENSE) for details.
