import SwiftUI

/// Arcade-styled pre-permission card requesting the player to either allow or deny notifications.
/// Transparently explains the competitive benefits (streak protection, leaderboard alerts).
struct NotificationPromptView: View {
    var onAllow: () -> Void
    var onDeny: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Glowing Bell & Flame Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.neonViolet.opacity(0.25), Theme.neonGold.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.neonGold, Theme.neonOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("Never Lose Your Streak! 🔥")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Enable notifications to receive daily challenge alerts and competitive quotes when rivals threaten your leaderboard rank.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 6)
            }

            VStack(spacing: 10) {
                // Primary Action: Allow Notifications
                Button {
                    AudioManager.shared.playTap()
                    onAllow()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Allow Notifications")
                    }
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        LinearGradient(
                            colors: [Theme.neonGold, Theme.neonOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Theme.neonGold.opacity(0.35), radius: 8, y: 2)
                }
                .buttonStyle(ArcadePressableButtonStyle())

                // Secondary Action: Don't Allow / Maybe Later
                Button {
                    AudioManager.shared.playTap()
                    onDeny()
                } label: {
                    Text("Don't Allow")
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
