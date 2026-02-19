import Testing
@testable import CinePlayerCore

@Suite("CinePlayerCore Basic Tests")
struct CinePlayerCoreTests {
    @Test("PlayerState defaults")
    func playerStateDefaults() {
        let state = PlayerState()
        #expect(state.currentTime == 0)
        #expect(state.duration == 0)
        #expect(state.isPlaying == false)
        #expect(state.progress == 0)
    }

    @Test("PlayerState progress calculation")
    func playerStateProgress() {
        var state = PlayerState()
        state.currentTime = 30
        state.duration = 120
        #expect(state.progress == 0.25)
    }

    @Test("PlaybackSpeed standard options")
    func playbackSpeedStandard() {
        let speeds = PlaybackSpeed.standard
        #expect(speeds.count == 7)
        #expect(speeds.first?.rate == 0.5)
        #expect(speeds.last?.rate == 2.0)
    }

    @Test("VideoGravity toggle")
    func videoGravityToggle() {
        #expect(VideoGravity.resizeAspect.toggled == .resizeAspectFill)
        #expect(VideoGravity.resizeAspectFill.toggled == .resizeAspect)
    }

    @Test("PlayerConfiguration defaults")
    func configurationDefaults() {
        let config = PlayerConfiguration()
        #expect(config.startTime == 0)
        #expect(config.autoPlay == true)
        #expect(config.loop == false)
        #expect(config.gravity == .resizeAspect)
    }

    @Test("PlayerStats formatBitrate")
    func formatBitrate() {
        #expect(PlayerStats.formatBitrate(0) == "N/A")
        #expect(PlayerStats.formatBitrate(500) == "500 bps")
        #expect(PlayerStats.formatBitrate(5000) == "5.0 kbps")
        #expect(PlayerStats.formatBitrate(5_000_000) == "5.0 Mbps")
    }
}
