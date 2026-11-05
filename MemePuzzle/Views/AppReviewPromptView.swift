import SwiftUI

/// Friendly arcade rating card presented once the user finishes their first 2 puzzles.
/// Features the user's requested phrasing: "it will help us upgrade what's missing..."
struct AppReviewPromptView: View {
    var onRate: () -> Void
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Star Crown Icon
            ZStack {
                Circle()
                    .fill(Theme.neonGold.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: "star.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.neonGold)
            }

            VStack(spacing: 6) {
                Text("Enjoying Meme Blitz? ⭐")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("You've already restored 2 memes!\nIf you have a quick moment, rating us on the App Store will help us upgrade what's missing and bring you more awesome memes!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 10) {
                // Primary Action: Rate on App Store
                Button {
                    AudioManager.shared.playVictory(customSound: "meme_nice")
                    onRate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.leadinghalf.filled")
                            .font(.system(size: 14, weight: .bold))
                        Text("Rate on App Store")
                    }
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 2)
                }
                .buttonStyle(ArcadePressableButtonStyle())

                // Secondary Action: Maybe Later
                Button {
                    AudioManager.shared.playTap()
                    onDismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .frame(maxWidth: 335)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.11, green: 0.10, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
        )
        .scaleEffect(appeared ? 1.0 : 0.92)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
