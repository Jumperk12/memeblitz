import MemeBlitzCore
import SwiftUI

/// Arcade-style modal popup displayed when the countdown timer expires.
/// Features a compact, vertically and horizontally centered layout,
/// deep charcoal/purple arcade background, high-contrast yellow ad continuation,
/// secondary navigation buttons (Levels, Change Mode), and a full-width Try Again button.
struct TimeUpPopupView: View {
    @Bindable var model: PuzzleViewModel
    var onTryAgain: () -> Void
    var onLevels: () -> Void
    var onChangeMode: () -> Void

    @State private var appeared = false

    init(
        model: PuzzleViewModel,
        onTryAgain: @escaping () -> Void,
        onLevels: @escaping () -> Void,
        onChangeMode: @escaping () -> Void
    ) {
        self.model = model
        self.onTryAgain = onTryAgain
        self.onLevels = onLevels
        self.onChangeMode = onChangeMode
    }

    private var progressPlaced: Int {
        guard let state = model.state else { return 0 }
        return state.layout.trayOrder.count - state.tray.count
    }

    private var totalPieces: Int {
        model.state?.layout.trayOrder.count ?? 0
    }

    private var remainingPieces: Int {
        model.state?.tray.count ?? 0
    }

    private var progressPercentage: Int {
        guard totalPieces > 0 else { return 0 }
        return Int((Double(progressPlaced) / Double(totalPieces)) * 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            progressBox

            if let error = model.adErrorMessage {
                Text(error)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.38))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }

            actions
        }
        .padding(20)
        .frame(maxWidth: 352)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.10, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 10)
        )
        .scaleEffect(appeared ? 1.0 : 0.93)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("failure.overlay")
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            // Slashed / Red Timer Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.35).opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.32, blue: 0.38))
            }

            Text("Time’s Up!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("failure.title")

            Text("The countdown reached zero before the meme was restored.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Progress Box
    private var progressBox: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("YOUR PROGRESS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(1.0)

                Text("\(progressPlaced) of \(totalPieces) pieces placed")
                    .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("failure.progress")

                Text("\(remainingPieces) piece\(remainingPieces == 1 ? "" : "s") remaining")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer(minLength: 8)

            // Circular Progress Indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: totalPieces > 0 ? CGFloat(progressPlaced) / CGFloat(totalPieces) : 0)
                    .stroke(
                        Theme.accent,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(progressPercentage)%")
                    .font(.system(size: 11, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Actions
    private var actions: some View {
        VStack(spacing: 10) {
            // Watch Ad to Continue (+20s) - Prominent Yellow Main Action
            Button {
                AudioManager.shared.playTap()
                model.continueWithRewardedAd()
            } label: {
                HStack(spacing: 8) {
                    if model.isWatchingAd {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.black)
                        Text("Loading Ad…")
                    } else {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Watch Ad to Continue (+20s)")
                    }
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 2)
            }
            .buttonStyle(ArcadePressableButtonStyle())
            .disabled(model.isWatchingAd)
            .accessibilityIdentifier("failure.watchAd")

            // Levels & Change Mode - Secondary Actions Side-by-Side
            HStack(spacing: 10) {
                Button {
                    AudioManager.shared.playTap()
                    onLevels()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Levels")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(ArcadePressableButtonStyle())
                .accessibilityIdentifier("failure.levels")

                Button {
                    AudioManager.shared.playTap()
                    onChangeMode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                        Text("Change Mode")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(ArcadePressableButtonStyle())
                .accessibilityIdentifier("failure.changeDifficulty")
            }

            // Try Again - Clearly Visible Full-Width Action
            Button {
                AudioManager.shared.playTap()
                onTryAgain()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                    Text("Try Again")
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.22, green: 0.20, blue: 0.32))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(ArcadePressableButtonStyle())
            .accessibilityIdentifier("failure.tryAgain")
        }
    }
}

/// Responsive spring tap effect for arcade modal buttons.
struct ArcadePressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

