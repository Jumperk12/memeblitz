import AudioToolbox
import AVFoundation
import Foundation
import UIKit

public enum SoundPack: String, CaseIterable, Identifiable, Codable, Sendable {
    case randomMix = "Random Meme Mix"
    case memeHype = "MLG & Hype"
    case dramaticGoofy = "Dramatic & Goofy"
    case retroArcade = "8-Bit Arcade"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .randomMix: "Plays a surprise funny meme sound on every win!"
        case .memeHype: "Airhorns, Sheesh, and Oh Baby A Triple!"
        case .dramaticGoofy: "Dramatic Dun-Dun-Dun, Emotional Damage, and Boing"
        case .retroArcade: "Classic 8-bit retro arcade fanfares & chimes"
        }
    }

    public var soundFiles: [String] {
        switch self {
        case .randomMix:
            return [
                "meme_airhorn",
                "meme_damage",
                "meme_sheesh",
                "meme_dramatic",
                "meme_arcade",
                "meme_nice",
                "meme_triple",
                "meme_wow",
                "meme_tada"
            ]
        case .memeHype:
            return ["meme_airhorn", "meme_sheesh", "meme_triple", "meme_nice"]
        case .dramaticGoofy:
            return ["meme_damage", "meme_dramatic", "meme_wow", "meme_tada"]
        case .retroArcade:
            return ["meme_arcade", "meme_wow", "meme_tada"]
        }
    }
}

/// Native sound effects and haptic feedback manager.
@MainActor
public final class AudioManager {
    public static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private var tickPlayer: AVAudioPlayer?
    private var urgentPlayer: AVAudioPlayer?

    private init() {}

    public func playTap() {
        guard GameProfile.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
        triggerHaptic(.light)
    }

    public func playCorrect() {
        guard GameProfile.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Tink / success
        triggerHaptic(.medium)
    }

    public func playWrong() {
        guard GameProfile.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1006) // Low alert / error buzz
        triggerNotificationHaptic(.error)
    }

    /// Plays a funny meme sound bite upon victory based on the player's selected sound pack.
    public func playVictory(customSound: String? = nil) {
        guard GameProfile.shared.soundEnabled else { return }
        triggerNotificationHaptic(.success)

        let soundName: String
        if let customSound {
            soundName = customSound
        } else {
            let candidates = GameProfile.shared.selectedSoundPack.soundFiles
            soundName = candidates.randomElement() ?? "meme_airhorn"
        }

        playSoundFile(named: soundName, fallbackSystemSound: 1025)
    }

    /// Previews a specific meme sound bite (e.g. from Settings).
    public func previewSound(_ soundName: String) {
        guard GameProfile.shared.soundEnabled else { return }
        triggerHaptic(.light)
        playSoundFile(named: soundName, fallbackSystemSound: 1057)
    }

    private func playSoundFile(named name: String, fallbackSystemSound: SystemSoundID) {
        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds"),
            Bundle.main.url(forResource: name, withExtension: "wav"),
            Bundle.main.url(forResource: name, withExtension: "mp3")
        ]

        guard let soundURL = candidateURLs.compactMap({ $0 }).first else {
            AudioServicesPlaySystemSound(fallbackSystemSound)
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.prepareToPlay()
            player?.play()
        } catch {
            AudioServicesPlaySystemSound(fallbackSystemSound)
        }
    }

    public func playFailure() {
        guard GameProfile.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1053) // Descending alert
        triggerNotificationHaptic(.warning)
    }

    public func playWarningTick(isUrgent: Bool = false) {
        guard GameProfile.shared.soundEnabled else { return }
        triggerHaptic(isUrgent ? .rigid : .medium)

        let soundName = isUrgent ? "timer_urgent" : "timer_tick"
        let fallbackSoundID: SystemSoundID = isUrgent ? 1052 : 1104

        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: soundName, withExtension: "wav", subdirectory: "Sounds"),
            Bundle.main.url(forResource: soundName, withExtension: "wav")
        ]

        if let soundURL = candidateURLs.compactMap({ $0 }).first {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                let newPlayer = try AVAudioPlayer(contentsOf: soundURL)
                newPlayer.volume = isUrgent ? 1.0 : 0.85
                newPlayer.prepareToPlay()
                newPlayer.play()
                if isUrgent {
                    urgentPlayer = newPlayer
                } else {
                    tickPlayer = newPlayer
                }
                return
            } catch {
                // Fall back to system alert sound below
            }
        }

        AudioServicesPlayAlertSound(fallbackSoundID)
    }

    public func playWarningTick() {
        playWarningTick(isUrgent: false)
    }

    public func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard GameProfile.shared.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard GameProfile.shared.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
