import CinePlayerCore
import SwiftUI

/// "Coming Up Next" banner that appears near the end of an episode,
/// or standalone "Watch Again" banner when no next item is available.
/// Positioned at bottom-trailing, above the progress bar area.
struct UpNextOverlay: View {
    let item: UpNextItem?          // nil = standalone Watch Again mode
    let countdown: TimeInterval
    let countdownDuration: TimeInterval
    let localization: PlayerLocalization
    let onTap: () -> Void
    let onDismiss: () -> Void
    let onReplay: (() -> Void)?    // secondary replay action (shown on Up Next banner)

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Group {
                    if item != nil {
                        bannerContent
                    } else {
                        watchAgainBanner
                    }
                }
                .padding(.trailing, isLandscape ? 60 : 16)
                .padding(.bottom, isLandscape ? 80 : 100)
            }
        }
        .allowsHitTesting(true)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    // MARK: - Up Next Banner

    private var bannerContent: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Main banner
            HStack(spacing: 10) {
                // Thumbnail
                AsyncImage(url: item?.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 56)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(localization.upNext.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    if let title = item?.title {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: 140, alignment: .leading)

                // Countdown ring
                countdownRing
            }
            .padding(10)
            .roundedGlass(cornerRadius: 16)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture(perform: onTap)
            .overlay(alignment: .topTrailing) {
                // Dismiss button — separate hit target, not inside the tap area
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                        .glassCircle(size: 24)
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }

            // Replay label below the banner
            if let onReplay {
                Button(action: onReplay) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text(localization.watchAgain)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Watch Again Banner

    private var watchAgainBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text(localization.watchAgain.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            countdownRing
        }
        .padding(10)
        .roundedGlass(cornerRadius: 16)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .glassCircle(size: 24)
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }

    // MARK: - Countdown Ring

    private var countdownRing: some View {
        let progress = countdownDuration > 0
            ? countdown / countdownDuration
            : 0

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            Text("\(Int(ceil(countdown)))")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(width: 36, height: 36)
    }
}
