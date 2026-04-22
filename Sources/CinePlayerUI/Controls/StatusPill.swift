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

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "cineplayer.network.status")

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
                self?.connection = resolved
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// MARK: - Status Pill

/// A glass pill showing the current time and network reception,
/// giving users the status-bar context normally hidden by the player.
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

            Image(systemName: iconName)
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
    }

    private var iconName: String {
        switch network.connection {
        case .wifi, .wired: "wifi"
        case .cellular: "antenna.radiowaves.left.and.right"
        case .offline: "wifi.slash"
        case .unknown: "wifi.exclamationmark"
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
        switch network.connection {
        case .wifi: "Wi-Fi connected"
        case .wired: "Ethernet connected"
        case .cellular: "Cellular connected"
        case .offline: "No network connection"
        case .unknown: "Network status unknown"
        }
    }
}
