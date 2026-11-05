import Foundation
import MemePuzzleCore
import Observation

/// Durable player progress, personal best records, settings, and achievements.
@Observable
public final class GameProfile: @unchecked Sendable {
    public static let shared = GameProfile()

    public var bestTime: Double? {
        didSet { save() }
    }

    public var bestTimesByMode: [String: Double] = [:] {
        didSet { save() }
    }

    public var soundEnabled: Bool = true {
        didSet { save() }
    }

    public var musicEnabled: Bool = true {
        didSet {
            save()
            Task { @MainActor in
                AudioManager.shared.updateMusicState()
            }
        }
    }

    public var hapticsEnabled: Bool = true {
        didSet { save() }
    }

    public var notificationsEnabled: Bool = true {
        didSet {
            save()
            if notificationsEnabled {
                NotificationManager.shared.scheduleInactivityReminders()
            } else {
                NotificationManager.shared.cancelAllReminders()
            }
        }
    }

    public var selectedSoundPack: SoundPack = .randomMix {
        didSet {
            UserDefaults.standard.set(selectedSoundPack.rawValue, forKey: "settings.soundPack")
        }
    }

    public var selectedDifficulty: DifficultyMode = .easy {
        didSet {
            UserDefaults.standard.set(selectedDifficulty.rawValue, forKey: "settings.difficulty")
        }
    }

    public var completedMemeIDs: Set<String> = [] {
        didSet { save() }
    }

    public var completedModes: Set<String> = [] {
        didSet { save() }
    }

    /// Highest unlocked level index (0-based) for each difficulty mode. Level 0 is unlocked by default.
    public var unlockedLevelByMode: [String: Int] = ["easy": 0, "medium": 0, "hard": 0, "extreme": 0] {
        didSet { save() }
    }

    public var unlockedAchievementIDs: Set<String> = [] {
        didSet { save() }
    }

    public var achievementUnlockDates: [String: Date] = [:] {
        didSet { save() }
    }

    public var totalSolvedCount: Int = 0 {
        didSet { save() }
    }

    public var totalMistakesCount: Int = 0 {
        didSet { save() }
    }

    public var totalXP: Int = 0 {
        didSet { save() }
    }

    public var currentStreak: Int = 0 {
        didSet { save() }
    }

    public var highestStreak: Int = 0 {
        didSet { save() }
    }

    public var bestTimesByMeme: [String: Double] = [:] {
        didSet { save() }
    }

    public var lastCompletedDailyDate: String? {
        didSet { save() }
    }

    public var dailyStreak: Int = 0 {
        didSet { save() }
    }

    public var highestDailyStreak: Int = 0 {
        didSet { save() }
    }

    public var isTodayDailyCompleted: Bool {
        lastCompletedDailyDate == DailyBlitzManager.todayDateKey
    }

    public func recordDailyCompletion(duration: Double, mistakes: Int, usedAd: Bool = false) {
        let today = DailyBlitzManager.todayDateKey
        let yesterday = DailyBlitzManager.yesterdayDateKey

        if lastCompletedDailyDate != today {
            if lastCompletedDailyDate == yesterday {
                dailyStreak += 1
            } else {
                dailyStreak = 1
            }
            if dailyStreak > highestDailyStreak {
                highestDailyStreak = dailyStreak
            }
            lastCompletedDailyDate = today
            // Daily Blitz bonus XP (+300 XP)
            addXP(300)

            Task { @MainActor in
                GameCenterManager.shared.submitDailyStreak(self.dailyStreak)
                GameCenterManager.shared.submitDailySolveTime(duration)
            }
        }

        recordCompletion(
            mode: .hard,
            memeID: "daily_\(String(format: "%03d", DailyBlitzManager.currentDayNumber))",
            duration: duration,
            mistakes: mistakes,
            usedAd: usedAd
        )
    }

    public var playerLevel: Int {
        max(1, 1 + totalXP / 250)
    }

    public var currentLevelBaseXP: Int {
        (playerLevel - 1) * 250
    }

    public var nextLevelTargetXP: Int {
        playerLevel * 250
    }

    public var levelProgress: Double {
        let xpInLevel = totalXP - currentLevelBaseXP
        return min(1.0, max(0.0, Double(xpInLevel) / 250.0))
    }

    public var xpRemainingForNextLevel: Int {
        max(0, nextLevelTargetXP - totalXP)
    }

    public func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        totalXP += amount
    }

    public func bestTime(forMeme memeID: String) -> Double? {
        bestTimesByMeme[memeID]
    }

    public func isSolved(_ memeID: String) -> Bool {
        completedMemeIDs.contains(memeID)
    }

    private let defaults: UserDefaults
    private var isLoading = false

    private var backupFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("memeblitz_profile_backup.json")
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()

        // Listen for iCloud external changes across devices or background sync
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithCloudStorage()
        }
    }

    public var formattedBestTime: String {
        guard let bestTime else { return "--:--" }
        return Self.formatTime(bestTime)
    }

    public static func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public func bestTime(for mode: DifficultyMode) -> Double? {
        bestTimesByMode[mode.rawValue]
    }

    /// Checks whether all levels in a difficulty mode have been solved.
    public func isModeFullyCompleted(_ mode: DifficultyMode) -> Bool {
        let templates = MemeCatalog.templates(for: mode)
        guard !templates.isEmpty else { return false }
        return templates.allSatisfy { completedMemeIDs.contains($0.id) }
    }

    /// Competitive progression: Easy is open by default.
    /// Medium unlocks ONLY after Easy mode is 100% completed.
    /// Hard unlocks ONLY after Medium mode is 100% completed.
    /// Extreme unlocks ONLY after Hard mode is 100% completed.
    public func isModeUnlocked(_ mode: DifficultyMode) -> Bool {
        if CommandLine.arguments.contains("-unlockAllModes") {
            return true
        }

        switch mode {
        case .easy:
            return true
        case .medium:
            return isModeFullyCompleted(.easy)
        case .hard:
            return isModeFullyCompleted(.medium)
        case .extreme:
            return isModeFullyCompleted(.hard)
        }
    }

    /// Checks if a specific level index (0-based) is unlocked in the given mode.
    public func isLevelUnlocked(mode: DifficultyMode, index: Int) -> Bool {
        guard isModeUnlocked(mode) else { return false }
        if index <= 0 { return true }
        let currentUnlocked = unlockedLevelByMode[mode.rawValue] ?? 0
        return index <= currentUnlocked
    }

    /// Unlocks the next level for the given mode.
    public func unlockNextLevel(mode: DifficultyMode, completedIndex: Int) {
        let current = unlockedLevelByMode[mode.rawValue] ?? 0
        if completedIndex + 1 > current {
            unlockedLevelByMode[mode.rawValue] = completedIndex + 1
            save()
        }
    }

    public func unlockMode(_ mode: DifficultyMode) {
        completedModes.insert(mode.rawValue)
        save()
    }

    public func isCompleted(memeID: String) -> Bool {
        completedMemeIDs.contains(memeID)
    }

    public func recordCompletion(
        mode: DifficultyMode,
        memeID: String,
        duration: Double,
        mistakes: Int,
        usedAd: Bool = false
    ) {
        totalSolvedCount += 1
        totalMistakesCount += mistakes
        completedMemeIDs.insert(memeID)

        // Only mark the mode completed once every meme in that mode has been solved
        if isModeFullyCompleted(mode) {
            completedModes.insert(mode.rawValue)
        }

        // Find index of this meme to unlock the next level
        let templates = MemeCatalog.templates(for: mode)
        if let idx = templates.firstIndex(where: { $0.id == memeID }) {
            unlockNextLevel(mode: mode, completedIndex: idx)
        } else {
            let current = unlockedLevelByMode[mode.rawValue] ?? 0
            unlockedLevelByMode[mode.rawValue] = current + 1
        }

        if let existing = bestTime {
            if duration < existing { bestTime = duration }
        } else {
            bestTime = duration
        }

        let modeKey = mode.rawValue
        if let existingMode = bestTimesByMode[modeKey] {
            if duration < existingMode { bestTimesByMode[modeKey] = duration }
        } else {
            bestTimesByMode[modeKey] = duration
        }

        // Per-meme personal best time
        if let existingMeme = bestTimesByMeme[memeID] {
            if duration < existingMeme { bestTimesByMeme[memeID] = duration }
        } else {
            bestTimesByMeme[memeID] = duration
        }

        // Streak tracking
        currentStreak += 1
        if currentStreak > highestStreak { highestStreak = currentStreak }

        // XP Award
        let baseXP: Int
        switch mode {
        case .easy: baseXP = 60
        case .medium: baseXP = 120
        case .hard: baseXP = 250
        case .extreme: baseXP = 450
        }
        let flawlessBonus = mistakes == 0 ? 50 : 0
        let speedBonus = duration <= max(10, mode.timeLimit * 0.5) ? 40 : 0
        addXP(baseXP + flawlessBonus + speedBonus)

        // Achievements check
        unlock("first_blitz")

        if duration <= max(10, mode.timeLimit - 30) {
            unlock("speed_demon")
        }

        if duration <= 45 {
            unlock("speed_sub45")
        }

        if (mode == .medium || mode == .hard || mode == .extreme) && duration <= 20 {
            unlock("speed_sub20")
        }

        if mode == .hard {
            unlock("galaxy_brain")
        }

        if mode == .extreme {
            unlock("extreme_champion")
        }

        if mistakes == 0 {
            unlock("flawless")
        }

        if mistakes == 0 && currentStreak >= 3 {
            unlock("surgical_precision")
        }

        let bundledCount = MemeCatalog.bundled.count
        if completedMemeIDs.count >= bundledCount {
            unlock("meme_master")
        }

        if usedAd {
            unlock("second_wind")
        }

        // Evaluate dynamic achievements via engine
        AchievementEngine.shared.evaluateProgress(profile: self)

        save()

        Task { @MainActor in
            GameCenterManager.shared.submitTotalSolved(self.totalSolvedCount)
            GameCenterManager.shared.submitPlayerXP(self.totalXP)
            if mode == .hard {
                GameCenterManager.shared.submitHardSolveTime(duration)
            }
        }
    }

    public func unlock(_ id: String) {
        guard !unlockedAchievementIDs.contains(id) else { return }
        unlockedAchievementIDs.insert(id)
        achievementUnlockDates[id] = Date()
        save()

        Task { @MainActor in
            GameCenterManager.shared.reportAchievement(id: id, percentComplete: 100.0)
        }
    }

    public func resetProgress() {
        bestTime = nil
        bestTimesByMode = [:]
        bestTimesByMeme = [:]
        completedMemeIDs = []
        completedModes = []
        unlockedLevelByMode = ["easy": 0, "medium": 0, "hard": 0, "extreme": 0]
        unlockedAchievementIDs = []
        achievementUnlockDates = [:]
        totalSolvedCount = 0
        totalMistakesCount = 0
        totalXP = 0
        currentStreak = 0
        highestStreak = 0
        lastCompletedDailyDate = nil
        dailyStreak = 0
        highestDailyStreak = 0

        // Remove all persisted keys from user defaults
        let keys = [
            "profile.bestTime",
            "profile.bestTimesByMode",
            "profile.bestTimesByMeme",
            "profile.unlockedLevelByMode",
            "profile.completedMemeIDs",
            "profile.completedModes",
            "profile.unlockedAchievements",
            "profile.achievementDates",
            "profile.totalSolvedCount",
            "profile.totalMistakesCount",
            "profile.totalXP",
            "profile.currentStreak",
            "profile.highestStreak",
            "profile.lastCompletedDailyDate",
            "profile.dailyStreak",
            "profile.highestDailyStreak",
            "unlockAllModes",
            "autostartMeme",
            "autostartDifficulty"
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
            NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
        }
        defaults.synchronize()
        NSUbiquitousKeyValueStore.default.synchronize()
        try? FileManager.default.removeItem(at: backupFileURL)
        save()
    }

    private func load() {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            // Run a clean flush once everything is merged
            save()
        }

        // 1. Load from local UserDefaults
        if defaults.object(forKey: "profile.bestTime") != nil {
            bestTime = defaults.double(forKey: "profile.bestTime")
        }
        if let dict = defaults.dictionary(forKey: "profile.bestTimesByMode") as? [String: Double] {
            bestTimesByMode = dict
        }
        if let memeDict = defaults.dictionary(forKey: "profile.bestTimesByMeme") as? [String: Double] {
            bestTimesByMeme = memeDict
        }
        if defaults.object(forKey: "profile.soundEnabled") != nil {
            soundEnabled = defaults.bool(forKey: "profile.soundEnabled")
        }
        if defaults.object(forKey: "profile.musicEnabled") != nil {
            musicEnabled = defaults.bool(forKey: "profile.musicEnabled")
        }
        if defaults.object(forKey: "profile.hapticsEnabled") != nil {
            hapticsEnabled = defaults.bool(forKey: "profile.hapticsEnabled")
        }
        if defaults.object(forKey: "profile.notificationsEnabled") != nil {
            notificationsEnabled = defaults.bool(forKey: "profile.notificationsEnabled")
        }
        if let diffRaw = defaults.string(forKey: "settings.difficulty"),
           let diff = DifficultyMode(rawValue: diffRaw) {
            selectedDifficulty = diff
        }
        if let soundPackRaw = defaults.string(forKey: "settings.soundPack"),
           let pack = SoundPack(rawValue: soundPackRaw) {
            selectedSoundPack = pack
        }
        if let completed = defaults.stringArray(forKey: "profile.completedMemeIDs") {
            completedMemeIDs = Set(completed)
        }
        if let achievements = defaults.stringArray(forKey: "profile.unlockedAchievements") {
            unlockedAchievementIDs = Set(achievements)
        }
        if let dates = defaults.dictionary(forKey: "profile.achievementDates") as? [String: Double] {
            achievementUnlockDates = dates.mapValues { Date(timeIntervalSince1970: $0) }
        }
        if let unlocked = defaults.dictionary(forKey: "profile.unlockedLevelByMode") as? [String: Int] {
            unlockedLevelByMode = unlocked
        }
        totalSolvedCount = defaults.integer(forKey: "profile.totalSolvedCount")
        totalMistakesCount = defaults.integer(forKey: "profile.totalMistakesCount")

        if defaults.object(forKey: "profile.totalXP") != nil {
            totalXP = defaults.integer(forKey: "profile.totalXP")
        }
        currentStreak = defaults.integer(forKey: "profile.currentStreak")
        highestStreak = defaults.integer(forKey: "profile.highestStreak")
        lastCompletedDailyDate = defaults.string(forKey: "profile.lastCompletedDailyDate")
        dailyStreak = defaults.integer(forKey: "profile.dailyStreak")
        highestDailyStreak = defaults.integer(forKey: "profile.highestDailyStreak")

        // 2. Multi-tier Merge from iCloud and Local Documents Backup (survives app deletion & reinstall)
        syncWithCloudStorage()
        mergeFromLocalBackup()

        // 3. Re-evaluate completed modes cleanly
        for mode in DifficultyMode.allCases {
            if isModeFullyCompleted(mode) {
                completedModes.insert(mode.rawValue)
            }
        }

        if totalXP == 0 && !completedMemeIDs.isEmpty {
            totalXP = completedMemeIDs.count * 100 + unlockedAchievementIDs.count * 150
        }
    }

    /// Syncs and merges progress from Apple iCloud Key-Value Storage (preserves data after app re-installation).
    public func syncWithCloudStorage() {
        let cloud = NSUbiquitousKeyValueStore.default
        cloud.synchronize()

        if let cloudMemes = cloud.array(forKey: "profile.completedMemeIDs") as? [String] {
            completedMemeIDs.formUnion(cloudMemes)
        }
        if let cloudAchievements = cloud.array(forKey: "profile.unlockedAchievements") as? [String] {
            unlockedAchievementIDs.formUnion(cloudAchievements)
        }
        if let cloudUnlocked = cloud.dictionary(forKey: "profile.unlockedLevelByMode") as? [String: Int] {
            for (m, lvl) in cloudUnlocked {
                let existing = unlockedLevelByMode[m] ?? 0
                unlockedLevelByMode[m] = max(existing, lvl)
            }
        }
        let cloudSolved = Int(cloud.longLong(forKey: "profile.totalSolvedCount"))
        if cloudSolved > totalSolvedCount {
            totalSolvedCount = cloudSolved
        }
        let cloudXP = Int(cloud.longLong(forKey: "profile.totalXP"))
        if cloudXP > totalXP {
            totalXP = cloudXP
        }
        let cloudStreak = Int(cloud.longLong(forKey: "profile.dailyStreak"))
        if cloudStreak > dailyStreak {
            dailyStreak = cloudStreak
        }
        let cloudHighStreak = Int(cloud.longLong(forKey: "profile.highestDailyStreak"))
        if cloudHighStreak > highestDailyStreak {
            highestDailyStreak = cloudHighStreak
        }
        if let cloudDailyDate = cloud.string(forKey: "profile.lastCompletedDailyDate"), lastCompletedDailyDate == nil {
            lastCompletedDailyDate = cloudDailyDate
        }
    }

    /// Restores unlocked achievements and leaderboards from Apple Game Center account.
    public func restoreFromGameCenter(achievements: [String], totalSolved: Int? = nil, xp: Int? = nil, dailyStreak: Int? = nil) {
        let previousCount = unlockedAchievementIDs.count
        unlockedAchievementIDs.formUnion(achievements)
        for id in achievements where achievementUnlockDates[id] == nil {
            achievementUnlockDates[id] = Date()
        }
        if let totalSolved, totalSolved > totalSolvedCount {
            totalSolvedCount = totalSolved
        }
        if let xp, xp > totalXP {
            totalXP = xp
        }
        if let dailyStreak, dailyStreak > self.dailyStreak {
            self.dailyStreak = dailyStreak
        }
        if unlockedAchievementIDs.count > previousCount || totalSolved != nil {
            save()
        }
    }

    /// Explicit flush called on app backgrounding or termination to guarantee zero data loss.
    public func saveNow() {
        save()
    }

    private func save() {
        guard !isLoading else { return }

        // 1. Save to local UserDefaults
        if let bestTime {
            defaults.set(bestTime, forKey: "profile.bestTime")
        } else {
            defaults.removeObject(forKey: "profile.bestTime")
        }
        defaults.set(bestTimesByMode, forKey: "profile.bestTimesByMode")
        defaults.set(bestTimesByMeme, forKey: "profile.bestTimesByMeme")
        defaults.set(unlockedLevelByMode, forKey: "profile.unlockedLevelByMode")
        defaults.set(soundEnabled, forKey: "profile.soundEnabled")
        defaults.set(musicEnabled, forKey: "profile.musicEnabled")
        defaults.set(hapticsEnabled, forKey: "profile.hapticsEnabled")
        defaults.set(notificationsEnabled, forKey: "profile.notificationsEnabled")
        defaults.set(Array(completedMemeIDs), forKey: "profile.completedMemeIDs")
        defaults.set(Array(completedModes), forKey: "profile.completedModes")
        defaults.set(Array(unlockedAchievementIDs), forKey: "profile.unlockedAchievements")
        let datesMap = achievementUnlockDates.mapValues { $0.timeIntervalSince1970 }
        defaults.set(datesMap, forKey: "profile.achievementDates")
        defaults.set(totalSolvedCount, forKey: "profile.totalSolvedCount")
        defaults.set(totalMistakesCount, forKey: "profile.totalMistakesCount")
        defaults.set(totalXP, forKey: "profile.totalXP")
        defaults.set(currentStreak, forKey: "profile.currentStreak")
        defaults.set(highestStreak, forKey: "profile.highestStreak")
        defaults.set(lastCompletedDailyDate, forKey: "profile.lastCompletedDailyDate")
        defaults.set(dailyStreak, forKey: "profile.dailyStreak")
        defaults.set(highestDailyStreak, forKey: "profile.highestDailyStreak")
        defaults.synchronize()

        // 2. Mirror to Apple iCloud Key-Value Store (persists across device swaps and app reinstalls)
        let cloud = NSUbiquitousKeyValueStore.default
        cloud.set(Array(completedMemeIDs), forKey: "profile.completedMemeIDs")
        cloud.set(Array(unlockedAchievementIDs), forKey: "profile.unlockedAchievements")
        cloud.set(unlockedLevelByMode, forKey: "profile.unlockedLevelByMode")
        cloud.set(Int64(totalSolvedCount), forKey: "profile.totalSolvedCount")
        cloud.set(Int64(totalXP), forKey: "profile.totalXP")
        cloud.set(Int64(dailyStreak), forKey: "profile.dailyStreak")
        cloud.set(Int64(highestDailyStreak), forKey: "profile.highestDailyStreak")
        if let lastCompletedDailyDate {
            cloud.set(lastCompletedDailyDate, forKey: "profile.lastCompletedDailyDate")
        }
        cloud.synchronize()

        // 3. Write Atomic JSON backup in Documents sandbox
        writeBackupFile()
    }

    private func writeBackupFile() {
        let snapshot: [String: Any] = [
            "completedMemeIDs": Array(completedMemeIDs),
            "unlockedAchievementIDs": Array(unlockedAchievementIDs),
            "unlockedLevelByMode": unlockedLevelByMode,
            "totalSolvedCount": totalSolvedCount,
            "totalXP": totalXP,
            "dailyStreak": dailyStreak,
            "highestDailyStreak": highestDailyStreak,
            "bestTimesByMeme": bestTimesByMeme
        ]
        if let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted]) {
            try? data.write(to: backupFileURL, options: [.atomic])
        }
    }

    private func mergeFromLocalBackup() {
        guard let data = try? Data(contentsOf: backupFileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let memes = json["completedMemeIDs"] as? [String] {
            completedMemeIDs.formUnion(memes)
        }
        if let ach = json["unlockedAchievementIDs"] as? [String] {
            unlockedAchievementIDs.formUnion(ach)
        }
        if let unlocked = json["unlockedLevelByMode"] as? [String: Int] {
            for (m, lvl) in unlocked {
                let existing = unlockedLevelByMode[m] ?? 0
                unlockedLevelByMode[m] = max(existing, lvl)
            }
        }
        if let solved = json["totalSolvedCount"] as? Int, solved > totalSolvedCount {
            totalSolvedCount = solved
        }
        if let xp = json["totalXP"] as? Int, xp > totalXP {
            totalXP = xp
        }
        if let streak = json["dailyStreak"] as? Int, streak > dailyStreak {
            dailyStreak = streak
        }
        if let highStreak = json["highestDailyStreak"] as? Int, highStreak > highestDailyStreak {
            highestDailyStreak = highStreak
        }
        if let times = json["bestTimesByMeme"] as? [String: Double] {
            for (meme, time) in times {
                if let existing = bestTimesByMeme[meme] {
                    if time < existing { bestTimesByMeme[meme] = time }
                } else {
                    bestTimesByMeme[meme] = time
                }
            }
        }
    }
}
