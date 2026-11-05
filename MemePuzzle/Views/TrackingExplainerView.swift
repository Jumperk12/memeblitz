import SwiftUI

/// Arcade-styled pre-permission explainer for App Tracking Transparency.
/// Explains that ads keep the game 100% free of charge before the native iOS permission dialog appears.
struct TrackingExplainerView: View {
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            // Megaphone / Gift icon
            ZStack {
                Circle()
                    .fill(Theme.neonViolet.opacity(0.18))
                    .frame(width: 54, height: 54)

                Image(systemName: "gift.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.neonGold)
            }

            VStack(spacing: 6) {
                Text("Help Keep Meme Blitz Free!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("We use ads to keep all memes and Daily Blitz puzzles 100% free of charge for everyone.\n\nOn the next screen, you can choose whether to allow tracking for more relevant ads.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)
            }

            Button {
                AudioManager.shared.playTap()
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
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
