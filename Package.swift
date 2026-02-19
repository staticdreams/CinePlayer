// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CinePlayer",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "CinePlayer",
            targets: [
                "CinePlayerCore", "CinePlayerUI", "CinePlayerPiP",
                "CinePlayerAirPlay", "CinePlayerNowPlaying",
            ]
        ),
        .library(name: "CinePlayerCore", targets: ["CinePlayerCore"]),
        .library(name: "CinePlayerUI", targets: ["CinePlayerUI"]),
    ],
    targets: [
        .target(name: "CinePlayerCore"),
        .target(name: "CinePlayerUI", dependencies: ["CinePlayerCore", "CinePlayerPiP"]),
        .target(name: "CinePlayerPiP", dependencies: ["CinePlayerCore"]),
        .target(name: "CinePlayerAirPlay"),
        .target(name: "CinePlayerNowPlaying", dependencies: ["CinePlayerCore"]),
        .testTarget(name: "CinePlayerCoreTests", dependencies: ["CinePlayerCore"]),
    ]
)
