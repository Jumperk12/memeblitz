import MemeBlitzCore
import SwiftUI

/// Arcade-style modal popup displayed when every missing tile is correctly placed.
/// Features a compact, vertically and horizontally centered layout,
/// deep charcoal/purple arcade background, three clean stat boxes,
/// prominent yellow "Next Level" action, and side-by-side secondary buttons ("Replay", "Levels").
struct CompletionPopupView: View {
    @Bindable var model: PuzzleViewModel
    let title: String
    var onReplay: () -> Void
    var onLevels: () -> Void
    var onHome: () -> Void
    var onNextLevel: () -> Void

    @State private var appeared = false

    init(
        model: PuzzleViewModel,
        title: String,
        onReplay: @escaping () -> Void,
        onLevels: @escaping () -> Void,
        onHome: @escaping () -> Void,
        onNextLevel: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.onReplay = onReplay
        self.onLevels = onLevels
        self.onHome = onHome
        self.onNextLevel = onNextLevel
    }

    private var durationText: String {
        let seconds = Int((model.finishedAt ?? .now).timeIntervalSince(model.startedAt))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var movesCount: Int {
        model.state?.moveCount ?? 0
    }

    private var accuracyText: String {
        guard let state = model.state, state.moveCount > 0 else { return "100%" }
        let correct = max(0, state.moveCount - state.mistakeCount)
        let percent = Int((Double(correct) / Double(state.moveCount) * 100).rounded())
        return "\(percent)%"
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            statsRow
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
        .accessibilityIdentifier("completion.overlay")
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            // Celebratory Party Popper Badge
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.78, blue: 0.20).opacity(0.16))
                    .frame(width: 48, height: 48)

                Text("🎉")
                    .font(.system(size: 26))
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .rotationEffect(.degrees(appeared ? 0 : -30))
            }

            Text("Meme Restored!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("completion.title")

            Text("The meme is back in one piece.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 8) {
            statCard(value: durationText, label: "Time", icon: "timer", identifier: "completion.time")
            statCard(value: "\(movesCount)", label: "Moves", icon: "hand.tap.fill", identifier: "completion.moves")
            statCard(value: accuracyText, label: "Accuracy", icon: "target", identifier: "completion.accuracy")
        }
    }

    private func statCard(value: String, label: String, icon: String, identifier: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)

            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Actions
    private var actions: some View {
        VStack(spacing: 10) {
            // Next Level → Prominent Yellow Main Action
            Button {
                AudioManager.shared.playTap()
                onNextLevel()
            } label: {
                HStack(spacing: 8) {
                    Text("Next Level")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
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
            .accessibilityIdentifier("completion.nextLevel")
            .accessibilityIdentifier("completion.newMeme")

            // Replay, Levels & Home - Secondary Actions Row
            HStack(spacing: 8) {
                Button {
                    AudioManager.shared.playTap()
                    onReplay()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .bold))
                        Text("Replay")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
                .accessibilityIdentifier("completion.replay")

                Button {
                    AudioManager.shared.playTap()
                    onLevels()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Levels")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
                .accessibilityIdentifier("completion.levels")

                Button {
                    AudioManager.shared.playTap()
                    onHome()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Home")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
                .accessibilityIdentifier("completion.home")
            }

            // Game Center Leaderboard Action
            Button {
                AudioManager.shared.playTap()
                GameCenterManager.shared.showLeaderboards()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.neonGold)
                    Text("Global Rankings")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.neonGold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Theme.neonGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.neonGold.opacity(0.3), lineWidth: 0.8)
                )
            }
            .buttonStyle(ArcadePressableButtonStyle())
            .accessibilityIdentifier("completion.gamecenter")
        }
    }
}
