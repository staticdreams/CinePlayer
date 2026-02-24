import AVFoundation
import MediaToolbox

/// Applies real audio gain amplification via MTAudioProcessingTap.
/// Intercepts raw audio samples and multiplies by a gain factor,
/// allowing volume beyond the system maximum.
///
/// The gain value is stored in a heap-allocated Float pointer shared
/// between the main thread (writes) and the real-time audio thread (reads).
/// Single-Float access is naturally atomic on ARM64/x86-64.
@MainActor
final class AudioBoostTap {
    /// Heap-allocated gain value shared with the audio processing callback.
    nonisolated(unsafe) private let gainPtr: UnsafeMutablePointer<Float>

    init() {
        gainPtr = .allocate(capacity: 1)
        gainPtr.initialize(to: 1.0)
    }

    deinit {
        gainPtr.deinitialize(count: 1)
        gainPtr.deallocate()
    }

    /// Updates the gain multiplier. 1.0 = normal, 2.0 = double volume.
    func setGain(_ value: Float) {
        gainPtr.pointee = value
    }

    /// Creates an AVAudioMix with an MTAudioProcessingTap that applies gain.
    /// The tap reads the current gain value on each audio buffer callback.
    nonisolated func createAudioMix(for track: AVAssetTrack) -> AVAudioMix? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(gainPtr),
            init: boostTapInit,
            finalize: boostTapFinalize,
            prepare: nil,
            unprepare: nil,
            process: boostTapProcess
        )

        var tap: Unmanaged<MTAudioProcessingTap>?
        let status = MTAudioProcessingTapCreate(
            kCFAllocatorDefault,
            &callbacks,
            kMTAudioProcessingTapCreationFlag_PostEffects,
            &tap
        )

        guard status == noErr, let createdTap = tap else { return nil }

        let params = AVMutableAudioMixInputParameters(track: track)
        params.audioTapProcessor = createdTap.takeRetainedValue()

        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        return mix
    }
}

// MARK: - C Callbacks (called on real-time audio thread)

/// Stores the gain pointer in tap storage for fast access during processing.
private func boostTapInit(
    _ tap: MTAudioProcessingTap,
    _ clientInfo: UnsafeMutableRawPointer?,
    _ tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
    tapStorageOut.pointee = clientInfo
}

/// No-op — the gain pointer is owned by AudioBoostTap, not by the tap.
private func boostTapFinalize(_ tap: MTAudioProcessingTap) {}

/// Reads source audio, then multiplies all samples by the current gain value.
private func boostTapProcess(
    _ tap: MTAudioProcessingTap,
    _ numberFrames: CMItemCount,
    _ flags: MTAudioProcessingTapFlags,
    _ bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    _ numberFramesOut: UnsafeMutablePointer<CMItemCount>,
    _ flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    let status = MTAudioProcessingTapGetSourceAudio(
        tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut
    )
    guard status == noErr else { return }

    let gain = MTAudioProcessingTapGetStorage(tap)
        .assumingMemoryBound(to: Float.self)
        .pointee

    guard gain > 1.0 else { return }

    let buffers = UnsafeMutableAudioBufferListPointer(bufferListInOut)
    for buffer in buffers {
        guard let data = buffer.mData else { continue }
        let samples = data.assumingMemoryBound(to: Float.self)
        let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
        for i in 0..<count {
            samples[i] *= gain
        }
    }
}
