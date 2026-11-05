import MemePuzzleCore
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile = GameProfile.shared
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio & Feedback") {
                    Toggle("Sound Effects", isOn: $profile.soundEnabled)
                        .tint(Theme.neonViolet)
                    Toggle("Background Music", isOn: $profile.musicEnabled)
                        .tint(Theme.neonViolet)
                    Toggle("Haptic Feedback", isOn: $profile.hapticsEnabled)
                        .tint(Theme.neonViolet)

                    Picker("Win Sound Pack", selection: $profile.selectedSoundPack) {
                        ForEach(SoundPack.allCases) { pack in
                            Text(pack.rawValue).tag(pack)
                        }
                    }
                    .tint(Theme.neonGold)

                    Button {
                        if let sound = profile.selectedSoundPack.soundFiles.randomElement() {
                            AudioManager.shared.previewSound(sound)
                        }
                    } label: {
                        HStack {
                            Label("Test Win Sound", systemImage: "speaker.wave.3.fill")
                                .foregroundStyle(Theme.neonGold)
                            Spacer()
                            Text("🔊 Preview")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.neonGold.opacity(0.18))
                                .clipShape(Capsule())
                                .foregroundStyle(Theme.neonGold)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Daily Challenge & Streak Reminders", isOn: $profile.notificationsEnabled)
                        .tint(Theme.neonViolet)
                }

                Section("Default Difficulty") {
                    Picker("Difficulty Mode", selection: $profile.selectedDifficulty) {
                        Text("Easy (6×6)").tag(DifficultyMode.easy)
                        Text("Medium (8×8)").tag(DifficultyMode.medium)
                        Text("Hard (10×10)").tag(DifficultyMode.hard)
                    }
                    .pickerStyle(.menu)
                }

                Section("Player Records") {
                    HStack {
                        Text("Best Blitz Time")
                        Spacer()
                        Text(profile.formattedBestTime)
                            .foregroundStyle(Theme.neonGold)
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("Puzzles Completed")
                        Spacer()
                        Text("\(profile.totalSolvedCount)")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Button("Reset Progress Records", role: .destructive) {
                        showResetConfirm = true
                    }
                }

                Section("Legal & About") {
                    Link(destination: URL(string: "https://jumperk12.github.io/memeblitz/privacy-policy.html")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://jumperk12.github.io/memeblitz/terms-of-service.html")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Meme Blitz)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .tint(Theme.neonViolet)
                }
            }
            .confirmationDialog("Reset Progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset All Records & Best Times", role: .destructive) {
                    profile.resetProgress()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear your personal best times, completed puzzles, and achievements.")
            }
        }
        .preferredColorScheme(.dark)
    }
}
