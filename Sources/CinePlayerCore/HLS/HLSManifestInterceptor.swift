import AVFoundation

/// AVAssetResourceLoaderDelegate that intercepts the HLS master playlist request,
/// rewrites it with rich audio track names, and returns the rewritten data to AVPlayer.
///
/// Usage:
/// 1. Create an interceptor with the original master URL and audio metadata.
/// 2. Swap the URL scheme to `HLSInterceptorScheme.scheme`.
/// 3. Assign the interceptor as the AVURLAsset's resourceLoader delegate.
public final class HLSManifestInterceptor: NSObject, AVAssetResourceLoaderDelegate, @unchecked Sendable {
    private let originalMasterURL: URL
    private let originalScheme: String
    private let audioTracks: [HLSAudioTrackInfo]

    private let lock = NSLock()
    private var tasks: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var cachedOriginalData: Data?
    private var cachedRewrittenData: Data?

    public init(originalMasterURL: URL, audioTracks: [HLSAudioTrackInfo]) {
        self.originalMasterURL = originalMasterURL
        self.originalScheme = originalMasterURL.scheme ?? "https"
        self.audioTracks = audioTracks
        super.init()
    }

    /// Convenience: Creates an AVURLAsset with the interceptor configured.
    ///
    /// - Parameters:
    ///   - url: The original HLS master playlist URL.
    ///   - audioTracks: Audio track metadata for rewriting.
    ///   - queue: DispatchQueue for the resource loader (defaults to a new queue).
    /// - Returns: A tuple of (asset, interceptor). Keep the interceptor alive while the asset is in use.
    @MainActor
    public static func makeAsset(
        url: URL,
        audioTracks: [HLSAudioTrackInfo],
        queue: DispatchQueue? = nil
    ) -> (asset: AVURLAsset, interceptor: HLSManifestInterceptor) {
        let interceptor = HLSManifestInterceptor(originalMasterURL: url, audioTracks: audioTracks)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.scheme = HLSInterceptorScheme.scheme
        let customURL = components.url ?? url

        let asset = AVURLAsset(url: customURL)
        let loaderQueue = queue ?? DispatchQueue(
            label: "com.cineplayer.hls.resourceLoader",
            qos: .userInitiated
        )
        asset.resourceLoader.setDelegate(interceptor, queue: loaderQueue)

        return (asset, interceptor)
    }

    // MARK: - AVAssetResourceLoaderDelegate

    public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        let key = ObjectIdentifier(loadingRequest)

        let task = Task { [weak self] in
            guard let self else { return }
            await self.handleLoadingRequest(loadingRequest)
            self.lock.withLock { self.tasks.removeValue(forKey: key) }
        }

        lock.withLock { tasks[key] = task }
        return true
    }

    public func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        let key = ObjectIdentifier(loadingRequest)
        lock.withLock {
            tasks[key]?.cancel()
            tasks.removeValue(forKey: key)
        }
    }

    // MARK: - Core handling

    private func handleLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) async {
        guard let requestURL = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: URLError(.badURL))
            return
        }

        let isM3U8 = requestURL.pathExtension.lowercased() == "m3u8"
        guard isM3U8 else {
            loadingRequest.finishLoading(with: URLError(.unsupportedURL))
            return
        }

        // Serve from cache.
        if let data = lock.withLock({ cachedRewrittenData }) {
            respond(loadingRequest, with: data)
            return
        }

        do {
            let sourceURL = try mapToOriginalScheme(url: requestURL)

            let data: Data
            let response: URLResponse?

            if sourceURL.isFileURL {
                data = try Data(contentsOf: sourceURL)
                response = nil
            } else {
                let result = try await URLSession.shared.data(from: sourceURL)
                data = result.0
                response = result.1
            }

            if Task.isCancelled { return }

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                loadingRequest.finishLoading(with: URLError(.badServerResponse))
                return
            }

            lock.withLock { cachedOriginalData = data }

            guard let text = String(data: data, encoding: .utf8) else {
                respond(loadingRequest, with: data)
                return
            }

            let rewritten = HLSPlaylistRewriter.rewriteMasterPlaylist(
                playlistText: text,
                masterURL: sourceURL,
                audioTracks: audioTracks
            )

            let outData = Data(rewritten.utf8)
            lock.withLock { cachedRewrittenData = outData }

            respond(loadingRequest, with: outData)
        } catch {
            if let fallback = lock.withLock({ cachedOriginalData }) {
                respond(loadingRequest, with: fallback)
                return
            }
            loadingRequest.finishLoading(with: error)
        }
    }

    private func mapToOriginalScheme(url: URL) throws -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if components.scheme == HLSInterceptorScheme.scheme {
            components.scheme = originalScheme
        }
        guard let out = components.url else { throw URLError(.badURL) }
        return out
    }

    private func respond(_ loadingRequest: AVAssetResourceLoadingRequest, with data: Data) {
        if let contentInfo = loadingRequest.contentInformationRequest {
            contentInfo.contentType = "application/vnd.apple.mpegurl"
            contentInfo.contentLength = Int64(data.count)
            contentInfo.isByteRangeAccessSupported = true
        }

        guard let dataRequest = loadingRequest.dataRequest else {
            loadingRequest.finishLoading()
            return
        }

        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength

        if requestedLength > 0 {
            let end = min(requestedOffset + requestedLength, data.count)
            if requestedOffset < end {
                dataRequest.respond(with: data.subdata(in: requestedOffset..<end))
            } else {
                dataRequest.respond(with: Data())
            }
        } else {
            dataRequest.respond(with: data)
        }

        loadingRequest.finishLoading()
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
