# iOS Competitive Timed Meme Block Puzzle Game & Remote Drop System

A polished, mobile-first competitive timed meme block puzzle game for iOS built with Swift 5.9, SwiftUI, and CoreGraphics. Inspired by photographic block jigsaw puzzles, Candy Crush-style competitive timed mechanics, and a live remote meme drop system.

Playable on iOS devices/simulator and in your browser at `http://localhost:3000/`.

---

## Highlights & Features

1. **Randomly Scattered Blocks Along the Image**
   - Missing pieces are now scattered randomly across the entire grid for every puzzle run.
   - Preserves a natural, well-dispersed distribution across all rows and columns so each puzzle delivers a fresh visual challenge across the whole artwork.

2. **Live Remote Multi-Meme Drop System**
   - **Drop Multiple Memes into `memes_drop/`**: Drop 1, 5, 10, or 50 image files (`.jpg`, `.png`, `.webp`, `.gif`, `.heic`) directly into the folder in macOS Finder. The server daemon detects them instantly via filesystem watch, formats human-readable titles, and adds them to the live catalog.
   - **In-Browser Multi-Drop**: Drag and drop multiple meme images anywhere over `http://localhost:3000/`. A glowing drop overlay lets you release and upload in batch immediately.
   - **Live Real-Time Remote Sync**: Uses Server-Sent Events (`/api/memes/stream`) and REST API (`/api/memes`). Newly dropped memes appear dynamically in the game catalog without requiring a reload.
   - **iOS Remote Feed & Multi-Import**: The iOS app connects to the remote feed via `RemoteMemeService`, badges remote memes with `REMOTE`, caches them locally, and supports multi-photo selection (`PhotosPicker`).

3. **Fixed Competitive Difficulty Modes**
   - **Easy**: 6×6 grid (36 tiles), 8 missing pieces randomly scattered, **90s countdown**.
   - **Medium**: 8×8 grid (64 tiles), 18 missing pieces randomly scattered, **75s countdown**, tray shuffled.
   - **Hard**: 10×10 grid (100 tiles), 32 missing pieces randomly scattered, **60s countdown**, tray shuffled.

4. **Competitive Animated Countdown Timer**
   - Prominent circular countdown ring with numeric digits positioned directly above the board.
   - Wall-clock resilient (pauses on backgrounding, resumes without drift).
   - Dynamic urgency states: green → amber → urgent crimson pulse and haptic/audio beeps under 15s.
   - Board freeze upon timer expiration.

5. **Failure & Rewarded Ad Continue**
   - "Time's Up!" overlay displaying progress percentages and placed piece counts (`14 of 18 pieces placed`).
   - "Try Again" single-tap reset with a fresh timer.
   - "Watch Ad to Continue (+20s)" button with atomic token protection, restoring time and unlocking the board without reshuffling or resetting placed tiles.

6. **10 Bundled Photographic Memes**
   - Original photographic artwork (`shocked_cat`, `office_dog`, `raccoon_ceo`, `side_eye_shiba`, `distracted_doggo`, `this_is_fine_fox`, `dramatic_hamster`, `confused_math_cat`, `success_otter`, `grumpy_bunny`).

---

## How to Drop Many Memes Remotely

### Option A: Drop directly into the local folder in Finder
Drop any number of `.jpg`, `.png`, `.webp` files into:
```
examples/meme-block-puzzle-ios/memes_drop/
```
The server will automatically detect them, format their names (e.g. `galaxy_brain_doggo.jpg` → `Galaxy Brain Doggo`), and broadcast them to both the web client and iOS app.

### Option B: Drag and drop onto the browser window
Open `http://localhost:3000/` and drag any number of images from your desktop over the browser. Release them over the "Drop Memes to Add Live!" card. They will upload in batch and be available to play instantly.

### Option C: API Upload (cURL or scripts)
```bash
curl -X POST http://localhost:3000/api/memes/upload \
  -H "Content-Type: application/json" \
  -d '{"memes": [{"name": "funny_duck.jpg", "data": "<base64_data>", "title": "Funny Duck"}]}'
```

---

## Running Checks & Tests

### 1. Pure Swift Core Tests (SPM)
```bash
cd MemePuzzleCore
swift test
# 28 tests, 0 failures
```

### 2. Full iOS Simulator Test Suite
```bash
xcodebuild test -project MemePuzzle.xcodeproj -scheme MemePuzzle \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
  -derivedDataPath /tmp/memepuzzle-dd CODE_SIGNING_ALLOWED=NO
# 35 tests, 0 failures (All passed)
```

### 3. Localhost Web Server
Running at:
```
http://localhost:3000/
```
Features real-time Server-Sent Events, drag-and-drop file uploader, Candy Crush-style countdown timer, and randomly scattered image blocks.
