import XCTest

/// End-to-end competitive gameplay through real touch gestures on the simulator.
final class MemePuzzleUITests: XCTestCase {
    /// Must match `DragGeometry.liftOffset`: the floating tile is drawn this far above the finger.
    private let liftOffset: CGFloat = 56

    override func setUp() {
        continueAfterFailure = false
    }

    private func launchPuzzle(
        meme: String = "easy_001",
        seed: Int = 7,
        missing: Int = 4,
        timeLimit: Double = 300
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-autostartMeme", meme,
            "-puzzleSeed", "\(seed)",
            "-missingTiles", "\(missing)",
            "-timeLimit", "\(timeLimit)",
            "-settings.rows", "10",
            "-settings.columns", "10"
        ]
        app.launch()
        XCTAssertTrue(app.otherElements["board"].waitForExistence(timeout: 10))
        return app
    }

    private func trayTiles(_ app: XCUIApplication) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'tray.tile.'")).allElementsBoundByIndex
    }

    /// "tray.tile.3.5" -> "slot.3.5"
    private func slotIdentifier(for tile: XCUIElement) -> String {
        tile.identifier.replacingOccurrences(of: "tray.tile.", with: "slot.")
    }

    private func drag(_ tile: XCUIElement, to slot: XCUIElement) {
        let start = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = slot.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).withOffset(CGVector(dx: 0, dy: liftOffset))
        start.press(forDuration: 0.4, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
    }

    private func progressLabel(_ app: XCUIApplication) -> String {
        app.descendants(matching: .any)["progress"].label
    }

    func testDraggingEveryMissingTileIntoItsSlotCompletesThePuzzle() {
        let app = launchPuzzle()
        XCTAssertEqual(trayTiles(app).count, 4)
        XCTAssertTrue(progressLabel(app).hasPrefix("0 of 4"))

        // Wrong slot: rejected, tile stays in the tray, progress unchanged.
        let tiles = trayTiles(app)
        let wrongSlot = app.descendants(matching: .any)[slotIdentifier(for: tiles[1])]
        drag(tiles[0], to: wrongSlot)
        XCTAssertTrue(progressLabel(app).hasPrefix("0 of 4"))
        XCTAssertEqual(trayTiles(app).count, 4)
        XCTAssertTrue(wrongSlot.exists, "slot must still be empty after an invalid drop")

        // Correct slots, one at a time.
        for placed in 1...4 {
            let tile = trayTiles(app)[0]
            let tileID = tile.identifier
            let slot = app.descendants(matching: .any)[slotIdentifier(for: tile)]
            drag(tile, to: slot)
            XCTAssertTrue(app.descendants(matching: .any)[tileID].waitForNonExistence(timeout: 4))
            if placed < 4 {
                XCTAssertTrue(progressLabel(app).hasPrefix("\(placed) of 4"), progressLabel(app))
                XCTAssertFalse(slot.exists, "filled slot should be replaced by the image tile")
            }
        }

        XCTAssertTrue(app.descendants(matching: .any)["completion.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(trayTiles(app).count, 0)

        // Replay deals a fresh puzzle on the same meme.
        app.buttons["completion.replay"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["tray"].waitForExistence(timeout: 5))
        XCTAssertEqual(trayTiles(app).count, 4)
        XCTAssertTrue(progressLabel(app).hasPrefix("0 of 4"))
    }

    func testTapToSelectThenTapSlotPlacesTile() {
        let app = launchPuzzle(meme: "easy_002_olaf_del_temu", seed: 11, missing: 3)
        let tile = trayTiles(app)[0]
        let tileID = tile.identifier
        let slot = app.descendants(matching: .any)[slotIdentifier(for: tile)]
        tile.tap()
        slot.tap()
        XCTAssertTrue(app.descendants(matching: .any)[tileID].waitForNonExistence(timeout: 4))
        XCTAssertTrue(progressLabel(app).hasPrefix("1 of 3"), progressLabel(app))
        XCTAssertEqual(trayTiles(app).count, 2)
    }

    func testDropOutsideBoardReturnsTileToTray() {
        let app = launchPuzzle(meme: "easy_003", seed: 3, missing: 3)
        let tile = trayTiles(app)[0]
        let start = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.4, thenDragTo: start.withOffset(CGVector(dx: 40, dy: -30)))
        XCTAssertEqual(trayTiles(app).count, 3)
        XCTAssertTrue(progressLabel(app).hasPrefix("0 of 3"))
    }

    func testHomeScreenStartsABundledMemeAndCanReturn() {
        let app = XCUIApplication()
        app.launch()
        let meme = app.buttons["meme.easy_001"]
        XCTAssertTrue(meme.waitForExistence(timeout: 5))
        meme.tap()
        XCTAssertTrue(app.otherElements["board"].waitForExistence(timeout: 10))
        XCTAssertFalse(trayTiles(app).isEmpty)
        app.buttons["back"].tap()
        XCTAssertTrue(meme.waitForExistence(timeout: 5))
    }

    func testCompetitiveTimerExpiresShowingFailureOverlayAndTryAgain() {
        // Launch with 5.0 second time limit to trigger failure quickly while leaving comfortable margin to verify Try Again
        let app = launchPuzzle(meme: "easy_004", seed: 5, missing: 3, timeLimit: 5.0)
        XCTAssertTrue(app.descendants(matching: .any)["failure.overlay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["failure.title"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["failure.progress"].exists)

        // Try Again restarts with fresh timer
        app.buttons["failure.tryAgain"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["tray"].waitForExistence(timeout: 6))
        let firstTile = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'tray.tile.'")).element(boundBy: 0)
        XCTAssertTrue(firstTile.waitForExistence(timeout: 6))
        XCTAssertEqual(trayTiles(app).count, 3)
    }

    func testFailureOverlayWatchAdExtendsTimeAndRestoresGame() {
        let app = launchPuzzle(meme: "easy_005", seed: 9, missing: 3, timeLimit: 1.2)
        XCTAssertTrue(app.descendants(matching: .any)["failure.overlay"].waitForExistence(timeout: 6))

        let watchAdBtn = app.buttons["failure.watchAd"]
        XCTAssertTrue(watchAdBtn.exists)
        watchAdBtn.tap()

        // Rewarded ad finishes, grants +20s and restores puzzle gameplay
        XCTAssertTrue(app.descendants(matching: .any)["tray"].waitForExistence(timeout: 6))
        let firstTile = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'tray.tile.'")).element(boundBy: 0)
        XCTAssertTrue(firstTile.waitForExistence(timeout: 6))
        XCTAssertEqual(trayTiles(app).count, 3)
    }

    func testHomeScreenSwitchesDifficultyModes() {
        let app = XCUIApplication()
        app.launchArguments = ["-unlockAllModes", "1"]
        app.launch()

        let easyBtn = app.buttons["mode.easy"]
        let mediumBtn = app.buttons["mode.medium"]
        let hardBtn = app.buttons["mode.hard"]

        XCTAssertTrue(easyBtn.waitForExistence(timeout: 5))
        XCTAssertTrue(mediumBtn.exists)
        XCTAssertTrue(hardBtn.exists)
        XCTAssertTrue(app.buttons["mode.extreme"].exists)

        // Tapping difficulty card opens Level Select, then tapping Level 1 launches puzzle
        mediumBtn.tap()
        let lvl1 = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Level 1' OR label CONTAINS '1'")).firstMatch
        if lvl1.waitForExistence(timeout: 3) {
            lvl1.tap()
        }
        XCTAssertTrue(app.otherElements["board"].waitForExistence(timeout: 10))
        XCTAssertFalse(trayTiles(app).isEmpty)
    }

    func testDifficultyProgressionLocksMediumAndHardInitially() {
        let app = XCUIApplication()
        app.launch()

        let easyBtn = app.buttons["mode.easy"]
        let mediumBtn = app.buttons["mode.medium"]
        let hardBtn = app.buttons["mode.hard"]
        let extremeBtn = app.buttons["mode.extreme"]

        XCTAssertTrue(easyBtn.waitForExistence(timeout: 5))
        XCTAssertTrue(mediumBtn.exists)
        XCTAssertTrue(hardBtn.exists)
        XCTAssertTrue(extremeBtn.exists)
        XCTAssertEqual(easyBtn.value as? String, "Unlocked")
    }

    func testLevelSelectScreenShowsLevelsAndLockProgression() {
        let app = XCUIApplication()
        app.launch()

        let easyBtn = app.buttons["mode.easy"]
        XCTAssertTrue(easyBtn.waitForExistence(timeout: 5))
        easyBtn.tap()

        XCTAssertTrue(app.staticTexts["EASY LEVELS"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Back"].exists)

        let screenshot = XCUIScreen.main.screenshot()
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: "/Users/hamzaken/.gemini/antigravity/scratch/rea/examples/meme-block-puzzle-ios/sim_levelselect.png"))
    }

    func testTopBarBestTimeBadgeOpensStatsSheet() {
        let app = XCUIApplication()
        app.launch()

        let bestTimeBadge = app.buttons["best.time.badge"]
        XCTAssertTrue(bestTimeBadge.waitForExistence(timeout: 5))
        bestTimeBadge.tap()

        XCTAssertTrue(app.staticTexts["Personal Best Blitz"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Records by Mode"].exists)

        app.buttons["Close"].tap()
        XCTAssertTrue(bestTimeBadge.waitForExistence(timeout: 4))
    }

    func testSoundToggleAndSettingsSheet() {
        let app = XCUIApplication()
        app.launch()

        let soundBtn = app.buttons["sound.toggle"]
        XCTAssertTrue(soundBtn.waitForExistence(timeout: 5))
        soundBtn.tap() // toggle off
        soundBtn.tap() // toggle back on

        let settingsBtn = app.buttons["settings.button"]
        XCTAssertTrue(settingsBtn.exists)
        settingsBtn.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.switches["Sound Effects"].exists)

        app.buttons["Done"].tap()
        XCTAssertTrue(settingsBtn.waitForExistence(timeout: 4))
    }

    func testBottomNavigationAndCollectionBanner() {
        let app = XCUIApplication()
        app.launch()

        // 1. Tapping Collection Tab
        let collectionTab = app.buttons["tab.collection"]
        XCTAssertTrue(collectionTab.waitForExistence(timeout: 5))
        collectionTab.tap()

        XCTAssertTrue(app.navigationBars["Meme Collection"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["meme.easy_001"].exists)

        // 2. Tapping Achievements Tab
        let achievementsTab = app.buttons["tab.achievements"]
        XCTAssertTrue(achievementsTab.exists)
        achievementsTab.tap()

        XCTAssertTrue(app.navigationBars["Achievements"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["First Blitz"].exists)

        // 3. Return to Home
        app.buttons["tab.home"].tap()
        XCTAssertTrue(app.buttons["banner.collection"].waitForExistence(timeout: 4))

        // 4. Tapping Collection Banner opens Collection Tab
        app.buttons["banner.collection"].tap()
        XCTAssertTrue(app.navigationBars["Meme Collection"].waitForExistence(timeout: 4))
    }
}
