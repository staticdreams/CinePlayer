import Foundation
import Darwin

/// Runtime access to private iOS signal-strength APIs.
///
/// **This uses private Apple frameworks and will not pass App Store review.**
/// It is only functional on jailbroken devices or apps signed via TrollStore
/// with the `com.apple.wifi.manager-access` entitlement. On stock iOS the
/// entitlement check fails silently and every method returns `nil`, which
/// is the intended graceful-degradation behavior.
///
/// - Cellular: `CoreTelephony.CTGetSignalStrength()` → bars (1–5).
/// - Wi-Fi: `MobileWiFi` manager/device client → `RSSI` property in dBm.
@MainActor
final class PrivateSignalClient {
    static let shared = PrivateSignalClient()

    // MARK: - C function typealiases

    private typealias CTGetSignalStrengthFn = @convention(c) () -> Int32
    private typealias WiFiManagerCreateFn = @convention(c) (CFAllocator?, UInt32) -> Unmanaged<AnyObject>?
    private typealias WiFiCopyDevicesFn = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias WiFiCopyPropertyFn = @convention(c) (AnyObject, CFString) -> Unmanaged<CFTypeRef>?

    // MARK: - Resolved symbols

    private let ctGetSignalStrength: CTGetSignalStrengthFn?
    private let wifiManager: AnyObject?
    private let wifiCopyDevices: WiFiCopyDevicesFn?
    private let wifiCopyProperty: WiFiCopyPropertyFn?

    // MARK: - Init

    private init() {
        // --- CoreTelephony (public framework, private symbol) ---
        var ctFn: CTGetSignalStrengthFn?
        if let ct = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY),
           let sym = dlsym(ct, "CTGetSignalStrength") {
            ctFn = unsafeBitCast(sym, to: CTGetSignalStrengthFn.self)
        }
        self.ctGetSignalStrength = ctFn

        // --- MobileWiFi (private framework) ---
        guard let wifi = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY) else {
            self.wifiManager = nil
            self.wifiCopyDevices = nil
            self.wifiCopyProperty = nil
            return
        }

        var manager: AnyObject?
        if let sym = dlsym(wifi, "WiFiManagerClientCreate") {
            let create = unsafeBitCast(sym, to: WiFiManagerCreateFn.self)
            manager = create(nil, 0)?.takeRetainedValue()
        }
        self.wifiManager = manager

        self.wifiCopyDevices = dlsym(wifi, "WiFiManagerClientCopyDevices").map {
            unsafeBitCast($0, to: WiFiCopyDevicesFn.self)
        }
        self.wifiCopyProperty = dlsym(wifi, "WiFiDeviceClientCopyProperty").map {
            unsafeBitCast($0, to: WiFiCopyPropertyFn.self)
        }
    }

    // MARK: - Public

    /// Returns cellular bars in 1...5 if the private symbol is reachable and a cellular
    /// service is active. Returns `nil` when denied (stock iOS) or no cellular signal.
    func cellularBars() -> Int? {
        guard let fn = ctGetSignalStrength else { return nil }
        let value = Int(fn())
        return (1...5).contains(value) ? value : nil
    }

    /// Returns Wi-Fi RSSI in dBm (roughly −30 strong to −90 weak) or `nil` when the
    /// MobileWiFi manager could not be created — typically due to a missing
    /// `com.apple.wifi.manager-access` entitlement on stock iOS.
    func wifiRSSI() -> Int? {
        guard let manager = wifiManager,
              let copyDevices = wifiCopyDevices,
              let copyProperty = wifiCopyProperty
        else { return nil }

        guard let devices = copyDevices(manager)?.takeRetainedValue(),
              CFArrayGetCount(devices) > 0,
              let raw = CFArrayGetValueAtIndex(devices, 0)
        else { return nil }

        let device = Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
        guard let property = copyProperty(device, "RSSI" as CFString)?.takeRetainedValue() else {
            return nil
        }
        return (property as? NSNumber)?.intValue
    }
}
