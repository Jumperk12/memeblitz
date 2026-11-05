import MemeBlitzCore
import SwiftUI

struct StatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile = GameProfile.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.neonGold, Theme.neonOrange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Theme.neonGold.opacity(0.4), radius: 10, y: 4)

                        Text("Personal Best Blitz")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(profile.formattedBestTime)
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .arcadeGlass(stroke: Theme.neonGold.opacity(0.4), cornerRadius: 24, fillOpacity: 0.12)

                    // Best Times By Mode
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Records by Mode")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        modeRow(
                            title: "Easy (6×6)",
                            icon: "leaf.fill",
                            color: Theme.easyEmerald,
                            time: profile.bestTime(for: .easy)
                        )

                        modeRow(
                            title: "Medium (8×8)",
                            icon: "bolt.fill",
                            color: Theme.mediumAmber,
                            time: profile.bestTime(for: .medium)
                        )

                        modeRow(
                            title: "Hard (10×10)",
                            icon: "flame.fill",
                            color: Theme.hardMagenta,
                            time: profile.bestTime(for: .hard)
                        )
                    }
                    .padding(18)
                    .arcadeGlass(stroke: Color.white.opacity(0.12), cornerRadius: 20)

                    // Overall Lifetime Stats
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Lifetime Progression")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        HStack {
                            statBox(label: "Solved", value: "\(profile.totalSolvedCount)", icon: "checkmark.seal.fill", color: Theme.success)
                            statBox(label: "Memes", value: "\(profile.completedMemeIDs.count)/\(MemeCatalog.bundled.count)", icon: "photo.stack.fill", color: Theme.neonViolet)
                            statBox(label: "Badges", value: "\(profile.unlockedAchievementIDs.count)/7", icon: "star.fill", color: Theme.neonGold)
                        }
                    }
                    .padding(18)
                    .arcadeGlass(stroke: Color.white.opacity(0.12), cornerRadius: 20)
                }
                .padding(18)
            }
            .background(Theme.background)
            .navigationTitle("Hall of Fame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .fontWeight(.bold)
                        .tint(Theme.neonGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func modeRow(title: String, icon: String, color: Color, time: Double?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.2))
                .clipShape(Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            if let time {
                Text(GameProfile.formatTime(time))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
            } else {
                Text("--:--")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }

    private func statBox(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
