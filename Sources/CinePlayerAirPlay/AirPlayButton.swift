import AVKit
import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for AVRoutePickerView (AirPlay button).
public struct AirPlayButton: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .white
        picker.activeTintColor = .systemBlue
        return picker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
