import Network
import SwiftUI

// MARK: - Network Status

@Observable @MainActor
final class PlayerNetworkStatus {
    enum Connection: Sendable {
        case wifi
        case cellular
        case wired
        case offline
        case unknown
    }

    var connection: Connection = .unknown
    /// 0.0 – 1.0 signal strength, or `nil` when unavailable (stock iOS, airplane mode, offline).
    var signalLevel: Double?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "cineplayer.network.status")
    // Timer is thread-safe to invalidate; flagged nonisolated so deinit can reach it.
    private nonisolated(unsafe) var pollTimer: Timer?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let resolved: Connection = {
                guard path.status == .satisfied else { return .offline }
                if path.usesInterfaceType(.wifi) { return .wifi }
                if path.usesInterfaceType(.cellular) { return .cellular }
                if path.usesInterfaceType(.wiredEthernet) { return .wired }
                return .unknown
            }()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.connection = resolved
                self.refreshSignal()
            }
        }
        monitor.start(queue: queue)

        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshSignal() }
        }
    }

    deinit {
        pollTimer?.invalidate()
        monitor.cancel()
    }

    // MARK: - Signal polling

    private func refreshSignal() {
        switch connection {
        case .wifi, .wired:
            if let rssi = PrivateSignalClient.shared.wifiRSSI() {
                signalLevel = Self.normalize(rssi: rssi)
            } else {
                signalLevel = nil
            }
        case .cellular:
            if let bars = PrivateSignalClient.shared.cellularBars() {
                signalLevel = Double(bars) / 5.0
            } else {
                signalLevel = nil
            }
        case .offline, .unknown:
            signalLevel = nil
        }
    }

    /// Maps RSSI (dBm) into a 0…1 scale. −30 dBm and stronger → 1.0; −90 dBm and weaker → 0.0.
    private static func normalize(rssi: Int) -> Double {
        let clamped = max(-90, min(-30, rssi))
        return Double(clamped + 90) / 60.0
    }
}

// MARK: - Status Pill

/// Glass pill showing the current time and network reception,
/// surfacing status-bar context that the full-screen player obscures.
struct StatusPill: View {
    @State private var network = PlayerNetworkStatus()

    private let pillHeight: CGFloat = 48

    var body: some View {
        HStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 15)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 1, height: 14)

            signalIcon
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityLabel(accessibilityLabel)
        }
        .padding(.horizontal, 14)
        .frame(height: pillHeight)
        .pillGlass()
        .animation(.easeInOut(duration: 0.2), value: network.connection)
        .animation(.easeInOut(duration: 0.2), value: network.signalLevel)
    }

    private var signalIcon: Image {
        // Variable-value symbols fill bars according to the 0…1 level.
        // Falls back to a solid icon when no signal data is available.
        switch network.connection {
        case .wifi, .wired:
            return Image(systemName: "wifi", variableValue: network.signalLevel ?? 1.0)
        case .cellular:
            return Image(systemName: "cellularbars", variableValue: network.signalLevel ?? 1.0)
        case .offline:
            return Image(systemName: "wifi.slash")
        case .unknown:
            return Image(systemName: "wifi.exclamationmark")
        }
    }

    private var iconColor: Color {
        switch network.connection {
        case .wifi, .wired, .cellular: .white
        case .offline: .red
        case .unknown: .white.opacity(0.6)
        }
    }

    private var accessibilityLabel: String {
        let base: String = switch network.connection {
        case .wifi: "Wi-Fi"
        case .wired: "Ethernet"
        case .cellular: "Cellular"
        case .offline: "Offline"
        case .unknown: "Network unknown"
        }
        if let level = network.signalLevel {
            return "\(base), signal \(Int(level * 100)) percent"
        }
        return base
    }
}
