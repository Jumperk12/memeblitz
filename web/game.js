// MEME BLITZ Web Edition — Solve Memes. Beat the Clock.

function getStandardMemeTitle(meme, fallbackIndex) {
  if (!meme) return 'Meme #001';
  const source = meme.id || meme.filename || meme.src || meme.title || '';
  const match = source.match(/(easy|medium|hard|extreme)_(\d+)/i);
  if (match) {
    const padded = String(match[2]).padStart(3, '0');
    return `Meme #${padded}`;
  }
  const titleMatch = meme.title ? meme.title.match(/^(Easy|Medium|Hard|Extreme)\s+(?:Meme|Level)\s+(\d+)$/i) : null;
  if (titleMatch) {
    const padded = String(titleMatch[2]).padStart(3, '0');
    return `Meme #${padded}`;
  }
  if (meme.title && !meme.title.toLowerCase().includes('meme ')) {
    return meme.title;
  }
  const num = (fallbackIndex != null ? fallbackIndex + 1 : 1);
  return `Meme #${String(num).padStart(3, '0')}`;
}

function getMemeUnlockRequirement(meme, fallbackIndex) {
  if (!meme) return { isSolved: false, isPlayable: true, reqText: '', prevTitle: '' };

  const isSolved = Array.isArray(profile.solvedMemeIds) && profile.solvedMemeIds.includes(meme.id);
  if (isSolved) {
    return {
      isSolved: true,
      isPlayable: true,
      reqText: 'Restored & Collected',
      prevTitle: ''
    };
  }

  const mode = meme.mode || 'easy';
  const pool = MEMES.filter(m => m.mode === mode);
  let modeIndex = pool.findIndex(m => m.id === meme.id);
  if (modeIndex < 0 && fallbackIndex != null) {
    modeIndex = fallbackIndex;
  }

  // Extract meme number
  let memeNum = null;
  const match = (meme.id || meme.src || '').match(/(easy|medium|hard|extreme)_(\d+)/i);
  if (match) {
    memeNum = parseInt(match[2], 10);
  } else if (modeIndex >= 0) {
    memeNum = modeIndex + 1;
  }

  // Identify the prerequisite meme title that must be unlocked
  let prevTitle = '';
  if (modeIndex > 0 && pool[modeIndex - 1]) {
    prevTitle = getStandardMemeTitle(pool[modeIndex - 1], modeIndex - 1);
  } else if (memeNum != null && memeNum > 1) {
    prevTitle = `Meme #${String(memeNum - 1).padStart(3, '0')}`;
  } else {
    // Mode entry meme (Level 1 of mode)
    if (mode === 'medium') {
      const easyPool = MEMES.filter(m => m.mode === 'easy');
      prevTitle = easyPool.length > 0 ? getStandardMemeTitle(easyPool[easyPool.length - 1], easyPool.length - 1) : 'Easy Mode';
    } else if (mode === 'hard') {
      const medPool = MEMES.filter(m => m.mode === 'medium');
      prevTitle = medPool.length > 0 ? getStandardMemeTitle(medPool[medPool.length - 1], medPool.length - 1) : 'Medium Mode';
    } else if (mode === 'extreme') {
      const hardPool = MEMES.filter(m => m.mode === 'hard');
      prevTitle = hardPool.length > 0 ? getStandardMemeTitle(hardPool[hardPool.length - 1], hardPool.length - 1) : 'Hard Mode';
    }
  }

  const isPlayable = isLevelUnlocked(mode, modeIndex >= 0 ? modeIndex : 0);

  if (!isPlayable) {
    const targetTitle = prevTitle || (memeNum != null && memeNum > 1 ? `Meme #${String(memeNum - 1).padStart(3, '0')}` : 'Meme #001');
    return {
      isSolved: false,
      isPlayable: false,
      prevTitle: targetTitle,
      reqText: `Must unlock ${targetTitle} to play this one`
    };
  }

  return {
    isSolved: false,
    isPlayable: true,
    prevTitle: prevTitle,
    reqText: 'Solve puzzle to unlock artwork'
  };
}

// Background Music (Meme Style Arcade Loop) Engine
let bgmAudio = null;
let crazyMuted = false;

function initBGM() {
  if (!bgmAudio) {
    bgmAudio = new Audio('sounds/bgm_meme_loop.m4a');
    bgmAudio.loop = true;
    bgmAudio.volume = 0.35;
  }
}

function playBGM() {
  if (crazyMuted || profile.musicEnabled === false) return;
  const launchOverlay = document.getElementById('launch-screen');
  if (launchOverlay && !launchOverlay.classList.contains('launch-dismissed') && launchOverlay.style.display !== 'none') {
    return;
  }
  initBGM();
  if (bgmAudio && bgmAudio.paused) {
    bgmAudio.play().catch(() => {});
  }
}

function pauseBGM() {
  if (bgmAudio && !bgmAudio.paused) {
    bgmAudio.pause();
  }
}

function resumeBGM() {
  if (profile.musicEnabled !== false) {
    playBGM();
  }
}

// CrazyGames SDK v3 Integration Module
const CrazySDK = {
  initialized: false,
  sdk: null,

  async init() {
    try {
      if (window.CrazyGames && window.CrazyGames.SDK) {
        this.sdk = window.CrazyGames.SDK;
        await this.sdk.init();
        this.initialized = true;
        console.log('[CrazyGames] SDK v3 initialized successfully');

        // CrazyGames SDK Audio Muting Support
        if (this.sdk?.game?.settings?.muteAudio) {
          crazyMuted = true;
          pauseBGM();
        }
        if (this.sdk?.game?.addSettingsChangeListener) {
          this.sdk.game.addSettingsChangeListener((newSettings) => {
            if (newSettings && typeof newSettings.muteAudio === 'boolean') {
              crazyMuted = newSettings.muteAudio;
              if (crazyMuted) {
                pauseBGM();
              } else if (profile.musicEnabled !== false) {
                resumeBGM();
              }
            }
          });
        }
      }
    } catch (e) {
      console.warn('[CrazyGames] Init failed or running outside CrazyGames:', e);
    }
  },

  loadingStart() {
    try {
      if (this.initialized && this.sdk?.game?.loadingStart) {
        this.sdk.game.loadingStart();
      }
    } catch (e) {}
  },

  loadingStop() {
    try {
      if (this.initialized && this.sdk?.game?.loadingStop) {
        this.sdk.game.loadingStop();
      }
    } catch (e) {}
  },

  gameplayStart() {
    try {
      if (this.initialized && this.sdk?.game?.gameplayStart) {
        this.sdk.game.gameplayStart();
      }
    } catch (e) {}
  },

  gameplayStop() {
    try {
      if (this.initialized && this.sdk?.game?.gameplayStop) {
        this.sdk.game.gameplayStop();
      }
    } catch (e) {}
  },

  happytime() {
    try {
      if (this.initialized && this.sdk?.game?.happytime) {
        this.sdk.game.happytime();
      }
    } catch (e) {}
  },

  requestMidgame(onComplete) {
    if (!this.initialized || !this.sdk?.ad?.requestAd) {
      if (onComplete) onComplete();
      return;
    }
    const previousSound = profile.soundEnabled;
    pauseBGM();
    this.sdk.ad.requestAd('midgame', {
      adStarted: () => {
        profile.soundEnabled = false;
        pauseBGM();
      },
      adFinished: () => {
        profile.soundEnabled = previousSound;
        resumeBGM();
        if (onComplete) onComplete();
      },
      adError: (err, errData) => {
        profile.soundEnabled = previousSound;
        resumeBGM();
        if (onComplete) onComplete();
      }
    });
  },

  requestRewarded(onReward, onError) {
    if (!this.initialized || !this.sdk?.ad?.requestAd) {
      if (onReward) onReward();
      return;
    }
    const previousSound = profile.soundEnabled;
    pauseBGM();
    this.sdk.ad.requestAd('rewarded', {
      adStarted: () => {
        profile.soundEnabled = false;
        pauseBGM();
      },
      adFinished: () => {
        profile.soundEnabled = previousSound;
        resumeBGM();
        if (onReward) onReward();
      },
      adError: (err, errData) => {
        profile.soundEnabled = previousSound;
        resumeBGM();
        if (onError) onError(errData);
      }
    });
  }
};

let MEMES = (window.MEMES_CATALOG && Array.isArray(window.MEMES_CATALOG) && window.MEMES_CATALOG.length > 0)
  ? window.MEMES_CATALOG
  : [
  { id: 'easy_001', title: 'Easy Meme 1', src: 'memes/easy_001.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_002', title: 'Easy Meme 2', src: 'memes/easy_002.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_003', title: 'Easy Meme 3', src: 'memes/easy_003.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_004', title: 'Easy Meme 4', src: 'memes/easy_004.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_005', title: 'Easy Meme 5', src: 'memes/easy_005.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_006', title: 'Easy Meme 6', src: 'memes/easy_006.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_007', title: 'Easy Meme 7', src: 'memes/easy_007.jpg', mode: 'easy', topText: '', bottomText: '' },
  { id: 'easy_008', title: 'Easy Meme 8', src: 'memes/easy_008.jpg', mode: 'easy', topText: '', bottomText: '' }
];

// Difficulty definitions
const DIFFICULTIES = {
  easy: { name: 'Easy', rows: 6, cols: 6, missing: 8, time: 90, tag: 'EASY', icon: '🍃', accent: '#10b981' },
  medium: { name: 'Medium', rows: 8, cols: 8, missing: 18, time: 60, tag: 'MEDIUM', icon: '⚡', accent: '#f59e0b' },
  hard: { name: 'Hard', rows: 10, cols: 10, missing: 32, time: 35, tag: 'HARD', icon: '🔥', accent: '#a855f7' },
  extreme: { name: 'Extreme', rows: 10, cols: 10, missing: 48, time: 20, tag: 'EXTREME', icon: '💀', accent: '#ff0055' }
};

// Sound Packs System (matching iOS Build 3)
const SOUND_PACKS = {
  randomMix: {
    id: 'randomMix',
    name: 'Random Meme Mix',
    desc: 'Surprise funny meme sound on every win!',
    sounds: [
      'meme_airhorn', 'meme_damage', 'meme_sheesh', 'meme_dramatic',
      'meme_arcade', 'meme_nice', 'meme_triple', 'meme_wow', 'meme_tada'
    ]
  },
  memeHype: {
    id: 'memeHype',
    name: 'MLG & Hype',
    desc: 'Airhorns, Sheesh, and Oh Baby A Triple!',
    sounds: ['meme_airhorn', 'meme_sheesh', 'meme_triple', 'meme_nice']
  },
  dramaticGoofy: {
    id: 'dramaticGoofy',
    name: 'Dramatic & Goofy',
    desc: 'Dramatic Dun-Dun-Dun, Emotional Damage, and Boing',
    sounds: ['meme_damage', 'meme_dramatic', 'meme_wow', 'meme_tada']
  },
  retroArcade: {
    id: 'retroArcade',
    name: '8-Bit Arcade',
    desc: 'Classic 8-bit retro arcade fanfares & chimes',
    sounds: ['meme_arcade', 'meme_wow', 'meme_tada']
  }
};

// Competitive Challenge Quotes (10 Rotating Rivalry Quotes)
const COMPETITIVE_CHALLENGE_QUOTES = [
  {
    title: "Someone's beating your time! ⏱️",
    body: "Your leaderboard rank is slipping! Jump in now and reclaim your fastest solve time."
  },
  {
    title: "Your Daily Streak is on the line! 🔥",
    body: "Don't let your solving streak reset to 0. One quick puzzle keeps your crown intact!"
  },
  {
    title: "Meme gods don't take days off 👑",
    body: "Think you can conquer today's puzzle in under 20 seconds? Prove it."
  },
  {
    title: "Are your reflexes slipping? ⚡",
    body: "The leaderboards are moving without you. Show them who's boss!"
  },
  {
    title: "Your brain cells miss you 🧠",
    body: "Today's Daily Blitz puzzle just dropped. Go set an unbeatable record!"
  },
  {
    title: "48-Piece Extreme is laughing at you 💀",
    body: "Triumph over the hardest puzzle tier and earn the Apex Legend achievement!"
  },
  {
    title: "A rival just climbed the ranks! 🏆",
    body: "Take back your #1 spot on the global leaderboards before it's too late."
  },
  {
    title: "The memes won't solve themselves! 🧩",
    body: "New puzzles are waiting in the Vault. Flex your lightning blitz speed today."
  },
  {
    title: "Don't let your streak freeze! ❄️",
    body: "You were on a roll! Solve one quick meme to keep your fire burning."
  },
  {
    title: "Speed Demon challenge! 🚀",
    body: "Can you solve a Medium or Hard puzzle before the timer hits 30s?"
  }
];

function rotateCompetitiveChallengeQuote() {
  const quote = COMPETITIVE_CHALLENGE_QUOTES[Math.floor(Math.random() * COMPETITIVE_CHALLENGE_QUOTES.length)];
  const titleEl = document.getElementById('challenge-quote-title');
  const bodyEl = document.getElementById('challenge-quote-body');
  if (titleEl && quote) titleEl.textContent = quote.title;
  if (bodyEl && quote) bodyEl.textContent = quote.body;
}

// Categorized Achievements Catalog (19 True 3D AI Medallions)
const ACHIEVEMENT_CATEGORIES = [
  'Puzzle Master',
  'Speed Demon',
  'Perfectionist',
  'Collector',
  'Streak Hunter',
  'Hardcore'
];

const ACHIEVEMENTS = [
  // 1. Puzzle Master
  { id: 'first_blitz', title: 'First Spark', desc: 'Solve your very first meme puzzle.', category: 'Puzzle Master', icon: 'achievement_icons/01_first_blitz.png', target: 1, xp: 100 },
  { id: 'puzzle_novice', title: 'Novice Solver', desc: 'Complete 5 meme puzzles across any mode.', category: 'Puzzle Master', icon: 'achievement_icons/02_puzzle_novice.png', target: 5, xp: 150 },
  { id: 'puzzle_artisan', title: 'Puzzle Artisan', desc: 'Complete 25 meme puzzles.', category: 'Puzzle Master', icon: 'achievement_icons/03_puzzle_artisan.png', target: 25, xp: 300 },
  { id: 'puzzle_grandmaster', title: 'Grandmaster', desc: 'Conquer 50 puzzles across all difficulty tiers.', category: 'Puzzle Master', icon: 'achievement_icons/04_puzzle_grandmaster.png', target: 50, xp: 600 },

  // 2. Speed Demon
  { id: 'speed_demon', title: 'Speed Demon', desc: 'Complete a puzzle with over 30s remaining.', category: 'Speed Demon', icon: 'achievement_icons/05_speed_demon.png', target: 1, xp: 120 },
  { id: 'speed_sub45', title: 'Lightning Reflexes', desc: 'Solve any puzzle in under 45 seconds.', category: 'Speed Demon', icon: 'achievement_icons/06_speed_sub45.png', target: 1, xp: 180 },
  { id: 'speed_sub20', title: 'Blitz Overdrive', desc: 'Solve a Medium or higher puzzle in under 20 seconds.', category: 'Speed Demon', icon: 'achievement_icons/07_speed_sub20.png', target: 1, xp: 350 },

  // 3. Perfectionist
  { id: 'flawless', title: 'Flawless Victory', desc: 'Complete a puzzle with zero incorrect tile placements.', category: 'Perfectionist', icon: 'achievement_icons/08_flawless.png', target: 1, xp: 150 },
  { id: 'surgical_precision', title: 'Surgical Precision', desc: 'Achieve 3 flawless puzzle solves.', category: 'Perfectionist', icon: 'achievement_icons/09_surgical_precision.png', target: 3, xp: 300 },

  // 4. Collector
  { id: 'vault_explorer', title: 'Vault Explorer', desc: 'Browse the curated Meme Vault collection.', category: 'Collector', icon: 'achievement_icons/10_vault_explorer.png', target: 1, xp: 80 },
  { id: 'collector_10', title: 'Meme Connoisseur', desc: 'Unlock and restore 10 unique meme puzzles.', category: 'Collector', icon: 'achievement_icons/11_collector_10.png', target: 10, xp: 200 },
  { id: 'collector_25', title: 'Culture Curator', desc: 'Unlock and restore 25 unique meme puzzles.', category: 'Collector', icon: 'achievement_icons/12_collector_25.png', target: 25, xp: 400 },
  { id: 'meme_master', title: 'Meme God', desc: 'Restore all curated memes in the entire catalog.', category: 'Collector', icon: 'achievement_icons/13_meme_master.png', target: 100, xp: 1000 },

  // 5. Streak Hunter
  { id: 'streak_3', title: 'On A Roll', desc: 'Achieve a 3-puzzle solving streak.', category: 'Streak Hunter', icon: 'achievement_icons/14_streak_3.png', target: 3, xp: 150 },
  { id: 'streak_5', title: 'Blazing Trail', desc: 'Achieve a 5-puzzle solving streak.', category: 'Streak Hunter', icon: 'achievement_icons/15_streak_5.png', target: 5, xp: 300 },
  { id: 'streak_10', title: 'Unstoppable Force', desc: 'Achieve a 10-puzzle solving streak.', category: 'Streak Hunter', icon: 'achievement_icons/16_streak_10.png', target: 10, xp: 600 },

  // 6. Hardcore
  { id: 'galaxy_brain', title: 'Galaxy Brain', desc: 'Conquer a Hard 10×10 puzzle before time expires.', category: 'Hardcore', icon: 'achievement_icons/17_galaxy_brain.png', target: 1, xp: 250 },
  { id: 'extreme_champion', title: 'Apex Legend', desc: 'Triumph over an Extreme Hard 48-piece puzzle.', category: 'Hardcore', icon: 'achievement_icons/18_extreme_champion.png', target: 1, xp: 500 },
  { id: 'second_wind', title: 'Second Wind', desc: 'Watch a rewarded ad to continue and claim victory.', category: 'Hardcore', icon: 'achievement_icons/19_second_wind.png', target: 1, xp: 100 }
];

// Persistent Player Profile
const profile = {
  soundEnabled: true,
  musicEnabled: true,
  selectedSoundPack: 'randomMix',
  hapticsEnabled: true,
  selectedDifficulty: 'easy',
  bestTimes: { easy: null, medium: null, hard: null, extreme: null },
  totalSolved: 0,
  totalMistakes: 0,
  solvedMemeIds: [],
  achievements: [],
  completedModes: [],
  // Unlocked level index per mode (0-based: Level 1 is index 0, unlocked by default)
  unlockedLevel: { easy: 0, medium: 0, hard: 0, extreme: 0 },
  streak: 0,
  flawlessCount: 0,
  dailyStreak: 0,
  lastCompletedDailyDate: null,
  xp: 0
};

function isModeFullyCompleted(mode) {
  const templates = (typeof MEME_TEMPLATES !== 'undefined' && MEME_TEMPLATES[mode]) || [];
  if (templates.length === 0) return false;
  return templates.every(t => profile.solvedMemeIds.includes(t.id));
}

function isModeUnlocked(mode) {
  if (mode === 'easy') return true;
  if (mode === 'medium') {
    return isModeFullyCompleted('easy');
  }
  if (mode === 'hard') {
    return isModeFullyCompleted('medium');
  }
  if (mode === 'extreme') {
    return isModeFullyCompleted('hard');
  }
  return false;
}

function isLevelUnlocked(mode, levelIndex) {
  if (!isModeUnlocked(mode)) return false;
  if (levelIndex <= 0) return true;
  const maxUnlocked = (profile.unlockedLevel && profile.unlockedLevel[mode]) || 0;
  return levelIndex <= maxUnlocked;
}

function getDailyBlitzInfo() {
  const anchor = new Date(2026, 10, 4); // Anchor Day 1: Nov 4, 2026
  const now = new Date();
  const startOfNow = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfAnchor = new Date(anchor.getFullYear(), anchor.getMonth(), anchor.getDate());
  const diffDays = Math.floor((startOfNow - startOfAnchor) / (1000 * 60 * 60 * 24));
  const dayNumber = ((diffDays % 100 + 100) % 100) + 1;
  const padded = String(dayNumber).padStart(3, '0');
  const todayKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayKey = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, '0')}-${String(yesterday.getDate()).padStart(2, '0')}`;

  const isCompletedToday = (profile.lastCompletedDailyDate === todayKey);

  return {
    dayNumber,
    padded,
    todayKey,
    yesterdayKey,
    isCompletedToday,
    imageSrc: `daily_memes/daily_${padded}.jpg`,
    meme: {
      id: `daily_${padded}`,
      title: `Daily Blitz #${padded}`,
      src: `daily_memes/daily_${padded}.jpg`,
      mode: 'hard',
      topText: 'DAILY BLITZ',
      bottomText: `DAY ${dayNumber}`
    }
  };
}

const PROFILE_STORAGE_KEY = 'meme_blitz_profile_v3';

// Clear any legacy test/mock data from previous development builds
try {
  localStorage.removeItem('meme_blitz_profile_v2');
  localStorage.removeItem('meme_blitz_profile');
  localStorage.removeItem('meme_blitz_profile_v1');
} catch (_) {}

function loadProfile() {
  try {
    let raw = null;
    // 1. Check CrazyGames SDK Data Module (Cloud Sync for logged in players)
    if (window.CrazyGames?.SDK?.data?.getItem) {
      try {
        raw = window.CrazyGames.SDK.data.getItem(PROFILE_STORAGE_KEY);
      } catch (_) {}
    }
    // 2. Fallback to localStorage
    if (!raw) {
      raw = localStorage.getItem(PROFILE_STORAGE_KEY);
    }
    if (raw) {
      const data = JSON.parse(raw);
      Object.assign(profile, data);
      if (!Array.isArray(profile.achievements)) profile.achievements = [];
      if (!Array.isArray(profile.solvedMemeIds)) profile.solvedMemeIds = [];
      if (!Array.isArray(profile.completedModes)) profile.completedModes = [];
      if (!profile.unlockedLevel || typeof profile.unlockedLevel !== 'object') {
        profile.unlockedLevel = { easy: 0, medium: 0, hard: 0, extreme: 0 };
      }
      if (profile.musicEnabled === undefined) profile.musicEnabled = true;
      if (!profile.selectedSoundPack) profile.selectedSoundPack = 'randomMix';
    }
  } catch (e) {
    console.warn('Could not load profile:', e);
  }
}

function saveProfile() {
  const jsonStr = JSON.stringify(profile);
  // 1. Sync to CrazyGames SDK Data Module (Cross-device Cloud Save)
  try {
    if (window.CrazyGames?.SDK?.data?.setItem) {
      window.CrazyGames.SDK.data.setItem(PROFILE_STORAGE_KEY, jsonStr);
    }
  } catch (e) {}
  // 2. Keep local fallback in sync
  try {
    localStorage.setItem(PROFILE_STORAGE_KEY, jsonStr);
  } catch (e) {}
  updateProfileUI();
}

function updateProfileUI() {
  // Top bar best time badge
  const bestTimes = Object.values(profile.bestTimes).filter(t => t != null);
  const homeBadge = document.getElementById('home-best-time');
  if (homeBadge) {
    if (bestTimes.length > 0) {
      const best = Math.min(...bestTimes);
      const m = Math.floor(best / 60);
      const s = Math.floor(best % 60);
      homeBadge.textContent = `⚡ ${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    } else {
      homeBadge.textContent = '⚡ --:--';
    }
  }

  // Stats modal records
  const recEasy = document.getElementById('rec-easy-time');
  const recMed = document.getElementById('rec-medium-time');
  const recHard = document.getElementById('rec-hard-time');
  const recExtreme = document.getElementById('rec-extreme-time');
  if (recEasy) recEasy.textContent = formatTimeSec(profile.bestTimes.easy);
  if (recMed) recMed.textContent = formatTimeSec(profile.bestTimes.medium);
  if (recHard) recHard.textContent = formatTimeSec(profile.bestTimes.hard);
  if (recExtreme) recExtreme.textContent = formatTimeSec(profile.bestTimes.extreme);

  const solvedEl = document.getElementById('stat-total-solved');
  const mistakesEl = document.getElementById('stat-total-mistakes');
  if (solvedEl) solvedEl.textContent = profile.totalSolved;
  if (mistakesEl) mistakesEl.textContent = profile.totalMistakes;

  // Sound toggle button icons
  const iconOn = document.getElementById('icon-sound-on');
  const iconOff = document.getElementById('icon-sound-off');
  if (iconOn && iconOff) {
    iconOn.style.display = profile.soundEnabled ? 'block' : 'none';
    iconOff.style.display = profile.soundEnabled ? 'none' : 'block';
  }

  // Settings toggles
  const soundToggle = document.getElementById('toggle-sound');
  const musicToggle = document.getElementById('toggle-music');
  const hapticsToggle = document.getElementById('toggle-haptics');
  if (soundToggle) soundToggle.checked = profile.soundEnabled;
  if (musicToggle) musicToggle.checked = profile.musicEnabled !== false;
  if (hapticsToggle) hapticsToggle.checked = profile.hapticsEnabled;

  const currentPack = profile.selectedSoundPack || 'randomMix';
  document.querySelectorAll('.sound-pack-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.pack === currentPack);
  });

  document.querySelectorAll('.diff-toggle-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.diff === profile.selectedDifficulty);
  });

  // Difficulty lock & progression state
  ['easy', 'medium', 'hard', 'extreme'].forEach(m => {
    const card = document.getElementById(`card-${m}`);
    const btn = document.querySelector(`.btn-play-pill[data-mode="${m}"]`);
    const unlocked = isModeUnlocked(m);
    if (card) {
      card.classList.toggle('is-locked', !unlocked);
      const thumbImg = card.querySelector('.card-thumb-wrap img');
      const firstMeme = MEMES.find(meme => meme.mode === m);
      if (thumbImg && firstMeme && firstMeme.src) {
        thumbImg.src = firstMeme.src;
      }
      let lockOverlay = card.querySelector('.card-lock-overlay');
      if (!unlocked) {
        if (!lockOverlay) {
          lockOverlay = document.createElement('div');
          lockOverlay.className = 'card-lock-overlay';
          const prev = m === 'medium' ? 'EASY' : (m === 'hard' ? 'MEDIUM' : 'HARD');
          lockOverlay.innerHTML = `<span class="lock-icon">🔒</span><span class="lock-hint">BEAT ${prev}</span>`;
          card.querySelector('.card-thumb-wrap')?.appendChild(lockOverlay);
        }
      } else if (lockOverlay) {
        lockOverlay.remove();
      }
    }
    if (btn) {
      btn.classList.toggle('locked', !unlocked);
      if (!unlocked) {
        btn.innerHTML = `🔒 LOCKED`;
      } else {
        btn.innerHTML = `PLAY <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>`;
      }
    }
  });

  // Sync floating hero cards with active meme collection
  const heroModeMap = {
    'float-tl': 'easy',
    'float-tr': 'medium',
    'float-bl': 'hard',
    'float-br': 'extreme'
  };
  Object.entries(heroModeMap).forEach(([className, mode]) => {
    const cardEl = document.querySelector(`.floating-meme-card.${className}`);
    if (cardEl) {
      const meme = MEMES.find(m => m.mode === mode);
      if (meme) {
        cardEl.dataset.meme = meme.id;
        cardEl.title = meme.title;
        const img = cardEl.querySelector('img');
        if (img) {
          img.src = meme.src;
          img.alt = meme.title;
        }
      }
    }
  });

  // Daily Blitz Hero Card UI
  const dailyInfo = getDailyBlitzInfo();
  const dailyCard = document.getElementById('daily-blitz-card');
  const dailyThumb = document.getElementById('daily-card-thumb');
  const dailyDayPill = document.getElementById('daily-day-pill');
  const dailyStreakPill = document.getElementById('daily-streak-pill');
  const btnDailyPlay = document.getElementById('btn-daily-play');
  const dailyDoneBanner = document.getElementById('daily-completed-banner');

  if (dailyCard) {
    dailyCard.classList.toggle('completed', dailyInfo.isCompletedToday);
    if (dailyThumb) dailyThumb.src = dailyInfo.imageSrc;
    if (dailyDayPill) dailyDayPill.textContent = `DAY ${dailyInfo.dayNumber} OF 100`;

    if (dailyStreakPill) {
      if (profile.dailyStreak > 0) {
        dailyStreakPill.style.display = 'inline-block';
        dailyStreakPill.textContent = `🔥 ${profile.dailyStreak} STREAK`;
      } else {
        dailyStreakPill.style.display = 'none';
      }
    }

    if (btnDailyPlay && dailyDoneBanner) {
      if (dailyInfo.isCompletedToday) {
        btnDailyPlay.style.display = 'none';
        dailyDoneBanner.style.display = 'flex';
      } else {
        btnDailyPlay.style.display = 'flex';
        dailyDoneBanner.style.display = 'none';
      }
    }
  }

  renderAchievements();
}

function formatTimeSec(sec) {
  if (sec == null) return '--:--';
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

// Puzzle state
const state = {
  mode: 'easy',
  currentMeme: MEMES[0],
  customImage: null,
  tiles: [],
  missingPositions: new Set(),
  tray: [],
  placedCount: 0,
  moveCount: 0,
  mistakeCount: 0,
  selectedTile: null,
  isComplete: false,
  isTimeUp: false,
  // Timer
  timeRemaining: 90,
  totalTime: 90,
  timerInterval: null
};

// DOM Elements
const boardEl = document.getElementById('puzzle-board');
const trayGridEl = document.getElementById('tray-grid');
const progressBarEl = document.getElementById('progress-bar');
const progressTextEl = document.getElementById('progress-text');
const memeTitleEl = document.getElementById('meme-title');
const modeBadgeEl = document.getElementById('mode-badge');
const statsLineEl = document.getElementById('stats-line');
const peekOverlayEl = document.getElementById('peek-overlay');
const timerFill = document.getElementById('timer-ring-fill');
const timerDigits = document.getElementById('timer-digits');
const winModal = document.getElementById('win-modal');
const failModal = document.getElementById('fail-modal');
const statsModal = document.getElementById('stats-modal');
const settingsModal = document.getElementById('settings-modal');
const toastEl = document.getElementById('toast-notify');
const bottomBar = document.getElementById('blitz-bottom-bar');

// Screen Switching System
function switchScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById(screenId);
  if (target) target.classList.add('active');

  // Update bottom tab buttons
  document.querySelectorAll('.nav-tab-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === screenId);
  });

  // Keep bottom navigation visible on home, collection, achievements; hide inside active puzzle stage or level select
  if (bottomBar) {
    bottomBar.style.display = (screenId === 'screen-game' || screenId === 'screen-levels') ? 'none' : 'flex';
  }

  // Prevent vertical scrolling during gameplay so everything stays in the same screen
  if (screenId === 'screen-game') {
    document.body.classList.add('in-game');
    setTimeout(() => { if (typeof updateBoardDimensions === 'function') updateBoardDimensions(); }, 15);
  } else {
    document.body.classList.remove('in-game');
  }

  if (screenId === 'screen-home') {
    rotateCompetitiveChallengeQuote();
  }

  if (screenId === 'screen-achievements') {
    renderAchievements();
  }

  if (screenId === 'screen-collection') {
    unlockAchievement('vault_explorer');
    renderCatalog();
  }

  // Scroll to top
  window.scrollTo(0, 0);
}

// Web Audio API
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
function playTone(freq, type = 'sine', duration = 0.12) {
  if (crazyMuted || !profile.soundEnabled) return;
  try {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
    gain.gain.setValueAtTime(0.18, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start();
    osc.stop(audioCtx.currentTime + duration);
  } catch (e) {}
}

function playSuccessSound() {
  playTone(523.25, 'triangle', 0.1);
  setTimeout(() => playTone(659.25, 'triangle', 0.15), 60);
}

function playErrorSound() {
  playTone(220, 'sawtooth', 0.18);
}

function playWarningBeep() {
  playTone(440, 'square', 0.08);
}

function playWarningTick(isUrgent = false) {
  if (crazyMuted || !profile.soundEnabled) return;
  triggerHaptic(isUrgent ? 'heavy' : 'medium');
  try {
    const soundFile = isUrgent ? 'sounds/timer_urgent.wav' : 'sounds/timer_tick.wav';
    const tickAudio = new Audio(soundFile);
    tickAudio.volume = isUrgent ? 0.95 : 0.75;
    tickAudio.play().catch(() => {
      playTone(isUrgent ? 880 : 440, 'square', 0.08);
    });
  } catch (e) {
    playTone(isUrgent ? 880 : 440, 'square', 0.08);
  }
}

function playWinSound(customSoundName) {
  if (crazyMuted || !profile.soundEnabled) return;
  try {
    const pack = SOUND_PACKS[profile.selectedSoundPack] || SOUND_PACKS.randomMix;
    const soundBase = customSoundName || pack.sounds[Math.floor(Math.random() * pack.sounds.length)];
    const audio = new Audio(`sounds/${soundBase}.wav`);
    audio.volume = 0.85;
    audio.play().catch(() => {
      const notes = [523.25, 659.25, 783.99, 1046.5];
      notes.forEach((freq, i) => {
        setTimeout(() => playTone(freq, 'triangle', 0.25), i * 110);
      });
    });
  } catch (e) {
    const notes = [523.25, 659.25, 783.99, 1046.5];
    notes.forEach((freq, i) => {
      setTimeout(() => playTone(freq, 'triangle', 0.25), i * 110);
    });
  }
}

function playFailSound() {
  const notes = [330, 293.66, 261.63, 220];
  notes.forEach((freq, i) => {
    setTimeout(() => playTone(freq, 'sawtooth', 0.22), i * 100);
  });
}

function triggerHaptic(type = 'light') {
  if (!profile.hapticsEnabled || !navigator.vibrate) return;
  if (type === 'light') navigator.vibrate(20);
  else if (type === 'medium') navigator.vibrate(45);
  else if (type === 'heavy') navigator.vibrate([60, 50, 60]);
}

function playPopBounceSound() {
  if (!profile.soundEnabled) return;
  try {
    if (audioCtx.state === 'suspended') audioCtx.resume();
    playTone(587.33, 'sine', 0.08); // D5
    setTimeout(() => playTone(880, 'sine', 0.12), 45); // A5
  } catch (e) {}
}

function spawnCardSparkles(btn) {
  const heroSection = btn.closest('.blitz-hero') || btn.parentElement;
  if (!heroSection) return;

  const sparkles = ['✨', '⭐', '💥', '🐾', '⚡', '🎉', '🌟'];
  const count = 5;
  const btnRect = btn.getBoundingClientRect();
  const parentRect = heroSection.getBoundingClientRect();

  const centerX = btnRect.left - parentRect.left + btnRect.width / 2;
  const centerY = btnRect.top - parentRect.top + btnRect.height / 2;

  for (let i = 0; i < count; i++) {
    const el = document.createElement('span');
    el.className = 'floating-sparkle';
    el.textContent = sparkles[Math.floor(Math.random() * sparkles.length)];
    el.style.left = `${centerX - 10}px`;
    el.style.top = `${centerY - 10}px`;

    const angle = (i / count) * 2 * Math.PI + (Math.random() - 0.5) * 0.6;
    const dist = 32 + Math.random() * 26;
    const dx = Math.cos(angle) * dist;
    const dy = Math.sin(angle) * dist - 12;
    const rot = (Math.random() - 0.5) * 50;

    el.style.setProperty('--dx', `${dx}px`);
    el.style.setProperty('--dy', `${dy}px`);
    el.style.setProperty('--rot', `${rot}deg`);

    heroSection.appendChild(el);
    setTimeout(() => el.remove(), 700);
  }
}

function showToast(message) {
  if (!toastEl) return;
  toastEl.textContent = message;
  toastEl.classList.add('show');
  setTimeout(() => toastEl.classList.remove('show'), 3500);
}

// Player Progression Info
function getPlayerLevelInfo() {
  const xp = profile.xp || (profile.solvedMemeIds.length * 100 + profile.achievements.length * 150);
  const level = Math.max(1, 1 + Math.floor(xp / 250));
  const baseXP = (level - 1) * 250;
  const targetXP = level * 250;
  const xpInLvl = xp - baseXP;
  const progress = Math.min(1, Math.max(0, xpInLvl / 250));
  const remaining = Math.max(0, targetXP - xp);
  return { xp, level, baseXP, targetXP, progress, remaining };
}

let currentTrophyCategory = 'all';

// Achievements Rendering
function renderAchievements() {
  const listEl = document.getElementById('achievements-list');
  const featCard = document.getElementById('featured-trophy-card');
  const catBar = document.getElementById('trophy-category-bar');
  if (!listEl) return;
  listEl.innerHTML = '';

  const info = getPlayerLevelInfo();
  const lvlNum = document.getElementById('player-lvl-num');
  if (lvlNum) lvlNum.textContent = info.level;
  const xpVal = document.getElementById('player-xp-val');
  if (xpVal) xpVal.textContent = `${info.xp} XP`;
  const xpFill = document.getElementById('player-xp-fill');
  if (xpFill) xpFill.style.width = `${Math.round(info.progress * 100)}%`;
  const xpRem = document.getElementById('player-xp-remaining');
  if (xpRem) xpRem.textContent = `${info.remaining} XP to Level ${info.level + 1}`;
  const xpPct = document.getElementById('player-xp-percent');
  if (xpPct) xpPct.textContent = `${Math.round(info.progress * 100)}%`;

  const statSolved = document.getElementById('stat-solved-count');
  if (statSolved) statSolved.textContent = profile.totalSolved || profile.solvedMemeIds.length;
  const statStreak = document.getElementById('stat-streak-count');
  if (statStreak) statStreak.textContent = `${profile.streak || 0} 🔥`;
  const statTrophies = document.getElementById('stat-trophies-count');
  if (statTrophies) statTrophies.textContent = `${profile.achievements.length}/${ACHIEVEMENTS.length}`;

  // Next Featured Achievement
  const pending = ACHIEVEMENTS.filter(a => !profile.achievements.includes(a.id));
  const featured = pending[0] || ACHIEVEMENTS[0];
  if (featCard && featured) {
    const isUnlocked = profile.achievements.includes(featured.id);
    const currProg = Math.min(featured.target, profile.totalSolved || 0);
    const pct = isUnlocked ? 100 : Math.round((currProg / featured.target) * 100);
    featCard.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <span style="font-size:0.68rem; font-weight:900; letter-spacing:0.1em; color:#fbbf24;">✨ NEXT TARGET</span>
        <span style="font-size:0.68rem; font-weight:900; color:#fbbf24; background:rgba(251,191,36,0.18); padding:3px 8px; border-radius:999px;">+${featured.xp || 100} XP</span>
      </div>
      <div style="display:flex; align-items:center; gap:12px;">
        <div style="width:48px; height:48px; display:flex; align-items:center; justify-content:center; border-radius:50%; overflow:hidden; border:1.5px solid rgba(251,191,36,0.5);">
          ${featured.icon && featured.icon.includes('/') ? `<img src="${featured.icon}" class="feat-badge-img" alt="${featured.title}">` : `<div style="font-size:1.8rem;">${featured.icon}</div>`}
        </div>
        <div style="flex:1;">
          <div style="font-size:0.95rem; font-weight:800; color:#fff;">${featured.title}</div>
          <div style="font-size:0.75rem; color:rgba(255,255,255,0.65);">${featured.desc}</div>
        </div>
      </div>
      <div class="xp-progress-track">
        <div class="xp-progress-fill" style="width: ${pct}%;"></div>
      </div>
    `;
  }

  // Category Filter Bar
  if (catBar) {
    catBar.innerHTML = '';
    const allPill = document.createElement('button');
    allPill.className = `trophy-cat-pill ${currentTrophyCategory === 'all' ? 'active' : ''}`;
    allPill.textContent = 'All';
    allPill.onclick = () => { currentTrophyCategory = 'all'; renderAchievements(); };
    catBar.appendChild(allPill);

    ACHIEVEMENT_CATEGORIES.forEach(cat => {
      const pill = document.createElement('button');
      pill.className = `trophy-cat-pill ${currentTrophyCategory === cat ? 'active' : ''}`;
      pill.textContent = cat;
      pill.onclick = () => { currentTrophyCategory = cat; renderAchievements(); };
      catBar.appendChild(pill);
    });
  }

  // Categorized List
  const catsToRender = currentTrophyCategory === 'all' ? ACHIEVEMENT_CATEGORIES : [currentTrophyCategory];
  catsToRender.forEach(cat => {
    const achs = ACHIEVEMENTS.filter(a => a.category === cat);
    if (!achs.length) return;
    const block = document.createElement('div');
    block.className = 'ach-category-block';
    const unlockedCat = achs.filter(a => profile.achievements.includes(a.id)).length;

    block.innerHTML = `
      <div class="ach-cat-header">
        <span>${cat.toUpperCase()}</span>
        <span class="ach-cat-count">${unlockedCat}/${achs.length}</span>
      </div>
    `;

    achs.forEach(ach => {
      const isUnlocked = profile.achievements.includes(ach.id);
      const card = document.createElement('div');
      card.className = `achievement-card ${isUnlocked ? 'unlocked' : ''}`;
      card.innerHTML = `
        <div class="ach-icon">
          ${ach.icon && ach.icon.includes('/') ? `<img src="${ach.icon}" class="ach-badge-img" alt="${ach.title}">` : ach.icon}
        </div>
        <div class="ach-info">
          <span class="ach-title">${ach.title}</span>
          <span class="ach-desc">${ach.desc}</span>
        </div>
        <span class="ach-badge">${isUnlocked ? 'UNLOCKED' : 'LOCKED'}</span>
      `;
      block.appendChild(card);
    });

    listEl.appendChild(block);
  });
}

function unlockAchievement(id) {
  let mappedId = id;
  if (id === 'first_win') mappedId = 'first_blitz';
  if (id === 'hard_core') mappedId = 'galaxy_brain';

  if (!profile.achievements.includes(mappedId)) {
    profile.achievements.push(mappedId);
    const ach = ACHIEVEMENTS.find(a => a.id === mappedId);
    const xpReward = (ach && ach.xp) ? ach.xp : 100;
    profile.xp = (profile.xp || 0) + xpReward;
    saveProfile();
    const targetAch = ach || ACHIEVEMENTS.find(a => a.id === id);
    if (targetAch) {
      showToast(`🏆 Achievement Unlocked: ${targetAch.title}!`);
      playTone(880, 'sine', 0.2);
    }
  }
}

// Dedicated Meme Detail Modal Helpers
let selectedMemeForDetail = null;

function openMemeDetail(meme, fallbackIndex) {
  selectedMemeForDetail = meme;
  const modal = document.getElementById('meme-detail-modal');
  if (!modal) return;
  const req = getMemeUnlockRequirement(meme, fallbackIndex);
  const isSolved = req.isSolved;
  const modeKey = meme.mode || 'easy';
  const diffDef = DIFFICULTIES[modeKey] || DIFFICULTIES.easy;
  const titleText = getStandardMemeTitle(meme, fallbackIndex);

  const artImg = document.getElementById('detail-art-img');
  const lockedArt = document.getElementById('detail-locked-art');
  const lockedChip = document.getElementById('detail-locked-chip');

  if (isSolved) {
    if (artImg) {
      artImg.src = meme.src;
      artImg.style.display = 'block';
    }
    if (lockedArt) lockedArt.style.display = 'none';
  } else {
    // Only show artwork for collected memes!
    if (artImg) {
      artImg.src = '';
      artImg.style.display = 'none';
    }
    if (lockedArt) {
      lockedArt.style.display = 'flex';
      if (lockedChip) {
        lockedChip.textContent = req.isPlayable ? '⚡ UNCOLLECTED' : '🔒 LOCKED';
      }
    }
  }

  document.getElementById('detail-meme-title').textContent = titleText;
  document.getElementById('detail-meme-id').textContent = meme.id;

  const modeBadge = document.getElementById('detail-mode-badge');
  if (modeBadge) {
    modeBadge.textContent = diffDef.tag;
    modeBadge.className = `detail-mode-badge ${modeKey}`;
  }

  const solvedTag = document.getElementById('detail-solved-tag');
  if (solvedTag) solvedTag.style.display = isSolved ? 'inline-flex' : 'none';

  const unlockCallout = document.getElementById('detail-unlock-callout');
  const unlockMsg = document.getElementById('detail-unlock-msg');
  if (!isSolved && unlockCallout && unlockMsg) {
    unlockCallout.style.display = 'flex';
    unlockMsg.textContent = req.reqText;
    unlockCallout.className = `detail-unlock-callout ${req.isPlayable ? 'playable' : 'locked'}`;
  } else if (unlockCallout) {
    unlockCallout.style.display = 'none';
  }

  document.getElementById('detail-spec-difficulty').textContent = diffDef.name;
  document.getElementById('detail-spec-grid').textContent = `${diffDef.rows}×${diffDef.cols}`;
  document.getElementById('detail-spec-pieces').textContent = `${diffDef.missing} Pieces`;

  const bestTime = profile.bestTimesByMeme ? profile.bestTimesByMeme[meme.id] : null;
  document.getElementById('detail-spec-best').textContent = bestTime ? formatTime(bestTime) : (isSolved ? 'Completed' : 'Unsolved');

  const btnPlay = document.getElementById('btn-detail-play');
  if (btnPlay) {
    if (!req.isPlayable) {
      btnPlay.disabled = true;
      btnPlay.className = 'detail-play-btn locked-disabled';
      btnPlay.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
        </svg>
        <span>${req.reqText}</span>
      `;
      btnPlay.onclick = null;
    } else {
      btnPlay.disabled = false;
      btnPlay.className = 'detail-play-btn active';
      const playLabel = isSolved ? 'REPLAY PUZZLE' : 'PLAY PUZZLE (SOLVE TO UNLOCK)';
      btnPlay.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
        <span>${playLabel}</span>
      `;
      btnPlay.onclick = () => {
        closeMemeDetail();
        state.currentMeme = meme;
        state.customImage = null;
        const targetMode = isModeUnlocked(meme.mode) ? (meme.mode || profile.selectedDifficulty) : profile.selectedDifficulty;
        profile.selectedDifficulty = targetMode;
        saveProfile();
        startPuzzle(targetMode, meme);
      };
    }
  }

  modal.classList.add('active');
}

function closeMemeDetail() {
  const modal = document.getElementById('meme-detail-modal');
  if (modal) modal.classList.remove('active');
  selectedMemeForDetail = null;
}

// Collection Filtering and Rendering
let currentCollectionFilter = 'all';

function renderCatalog() {
  const memeGridEl = document.getElementById('meme-grid');
  const countBadge = document.getElementById('catalog-count-badge');
  const countAll = document.getElementById('filter-count-all');
  const countEasy = document.getElementById('filter-count-easy');
  const countMed = document.getElementById('filter-count-med');
  const countHard = document.getElementById('filter-count-hard');
  const countExt = document.getElementById('filter-count-ext');

  if (!memeGridEl) return;
  memeGridEl.innerHTML = '';

  const total = MEMES.length;
  const easyCount = MEMES.filter(m => m.mode === 'easy').length;
  const medCount = MEMES.filter(m => m.mode === 'medium').length;
  const hardCount = MEMES.filter(m => m.mode === 'hard').length;
  const extCount = MEMES.filter(m => m.mode === 'extreme').length;

  if (countAll) countAll.textContent = total;
  if (countEasy) countEasy.textContent = easyCount;
  if (countMed) countMed.textContent = medCount;
  if (countHard) countHard.textContent = hardCount;
  if (countExt) countExt.textContent = extCount;

  // Vault completion progress
  const solvedCount = profile.solvedMemeIds.length;
  const collectedTitle = document.getElementById('vault-collected-title');
  if (collectedTitle) collectedTitle.textContent = `${solvedCount} of ${total} Collected`;
  const pct = total > 0 ? Math.round((solvedCount / total) * 100) : 0;
  const pctNum = document.getElementById('vault-percent-num');
  if (pctNum) pctNum.textContent = `${pct}%`;
  const progFill = document.getElementById('vault-progress-fill');
  if (progFill) progFill.style.width = `${pct}%`;

  // Filter memes
  const filtered = currentCollectionFilter === 'all'
    ? MEMES
    : MEMES.filter(m => m.mode === currentCollectionFilter);

  if (countBadge) {
    countBadge.textContent = `${filtered.length} Memes`;
  }

  // Bind filter buttons
  document.querySelectorAll('.col-filter-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.filter === currentCollectionFilter);
    btn.onclick = (e) => {
      e.preventDefault();
      currentCollectionFilter = btn.dataset.filter;
      renderCatalog();
      const scrollBody = document.querySelector('#screen-collection .tab-scroll-body');
      if (scrollBody) scrollBody.scrollTop = 0;
    };
  });

  filtered.forEach((meme, index) => {
    const req = getMemeUnlockRequirement(meme, index);
    const isSolved = req.isSolved;
    const card = document.createElement('div');
    card.className = `meme-card ${isSolved ? 'collected' : 'locked-card'}`;
    const modeName = (meme.mode || 'easy').toUpperCase();
    const titleText = getStandardMemeTitle(meme, index);

    let thumbHtml = '';
    if (isSolved) {
      thumbHtml = `
        <div class="thumb-box collected-thumb">
          <img src="${meme.src}" alt="${titleText}" loading="lazy">
          <span class="crown-badge">👑 SOLVED</span>
        </div>
      `;
    } else {
      // ONLY show artwork for collected memes! If not collected, mystery locked box
      thumbHtml = `
        <div class="thumb-box locked-thumb">
          <div class="mystery-lock-silhouette">
            <svg class="lock-glyph" width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
            </svg>
          </div>
          <span class="locked-chip ${req.isPlayable ? 'playable' : 'locked'}">${req.isPlayable ? '⚡ READY' : '🔒 LOCKED'}</span>
        </div>
      `;
    }

    card.innerHTML = `
      ${thumbHtml}
      <span class="meme-card-title">${titleText}</span>
      <div class="meme-card-req ${req.isPlayable ? 'playable' : 'locked'}">
        <svg class="req-glyph" width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
        </svg>
        <span class="req-text-label">${req.reqText}</span>
      </div>
      <div class="meme-card-footer">
        <span class="meme-mode-badge ${meme.mode || 'easy'}">${modeName}</span>
        <span class="meme-status-pill ${isSolved ? 'solved' : (req.isPlayable ? 'ready' : 'locked')}">${isSolved ? '✓ Solved' : (req.isPlayable ? '⚡ Ready' : '🔒 Locked')}</span>
      </div>
    `;

    card.onclick = () => {
      if (!req.isPlayable) {
        card.classList.remove('shake');
        void card.offsetWidth;
        card.classList.add('shake');
        playWrongSound();
        triggerHaptic('heavy');
        showToast(`🔒 ${req.reqText}`);
      } else {
        playTone(523.25, 'triangle', 0.08);
      }
      openMemeDetail(meme, index);
    };

    memeGridEl.appendChild(card);
  });
}

// Remote API Sync (Read-only catalog sync)
async function fetchRemoteCatalog() {
  try {
    const res = await fetch('/api/memes');
    if (!res.ok) return;
    const data = await res.json();
    if (data.memes && Array.isArray(data.memes) && data.memes.length > 0) {
      MEMES = data.memes;
      renderCatalog();
      if (state.levelSelectMode) {
        openLevelSelect(state.levelSelectMode);
      }
    }
  } catch (err) {}
}

function setupRemoteEventSource() {
  try {
    const evtSource = new EventSource('/api/memes/stream');
    evtSource.addEventListener('update', (e) => {
      try {
        const data = JSON.parse(e.data);
        if (data.memes && Array.isArray(data.memes)) {
          MEMES = data.memes;
          renderCatalog();
          if (state.levelSelectMode) {
            openLevelSelect(state.levelSelectMode);
          }
        }
      } catch (err) {}
    });
  } catch (err) {}
}

function updateBoardDimensions() {
  if (!boardEl || !state.mode) return;
  const diff = DIFFICULTIES[state.mode];
  if (!diff) return;

  // Viewport width available (max 440px)
  const appViewport = document.getElementById('app-viewport');
  const maxW = appViewport ? Math.min(appViewport.clientWidth - 20, 440) : Math.min(window.innerWidth - 20, 440);

  // Available height in screen: window.innerHeight minus header, progress bar, tray, and padding
  const headerEl = document.querySelector('.app-header');
  const progressEl = document.querySelector('.progress-container');
  const trayEl = document.getElementById('tray-container');

  const headerH = headerEl ? headerEl.offsetHeight : 52;
  const progressH = progressEl ? progressEl.offsetHeight : 24;
  const trayH = trayEl ? trayEl.offsetHeight : 124; // Extended missing pieces tray
  const paddingH = 26;

  const availableH = Math.max(160, window.innerHeight - (headerH + progressH + trayH + paddingH));
  const availableW = Math.max(180, maxW - 16);

  // Maintain strict 4:5 aspect ratio (width : height = 4 : 5) - perfectly matches mobile game proportions
  let boardW = availableW;
  let boardH = Math.round(boardW * (5 / 4));

  if (boardH > availableH) {
    boardH = availableH;
    boardW = Math.round(boardH * (4 / 5));
  }

  boardEl.style.width = `${boardW}px`;
  boardEl.style.height = `${boardH}px`;
  boardEl.style.aspectRatio = '4 / 5';
  boardEl.style.gridTemplateColumns = `repeat(${diff.cols}, 1fr)`;
  boardEl.style.gridTemplateRows = `repeat(${diff.rows}, 1fr)`;
}

// Window resize listener to keep 4:5 board and tray fitted without scrolling
window.addEventListener('resize', () => {
  if (state.currentMeme && state.mode && !state.isComplete) {
    updateBoardDimensions();
  }
});

// Slice Image into Puzzle Blocks with exact 4:5 aspect ratio (mobile game standard)
async function loadAndSliceImage() {
  const diff = DIFFICULTIES[state.mode];
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      // Crop source image to exact 4:5 aspect ratio (0.8) so game board extends down nicely
      const targetAspect = 4 / 5;
      const imgAspect = img.width / img.height;
      let srcX = 0, srcY = 0, srcW = img.width, srcH = img.height;

      if (imgAspect > targetAspect) {
        // Wider than 4:5: crop left and right to center
        srcW = Math.floor(img.height * targetAspect);
        srcX = Math.floor((img.width - srcW) / 2);
      } else {
        // Taller than 4:5: crop top and bottom to center
        srcH = Math.floor(img.width / targetAspect);
        srcY = Math.floor((img.height - srcH) / 2);
      }

      // Base tile dimensions to guarantee exact 4:5 ratio for each tile and the full board
      const scaleFactor = Math.floor(1200 / (diff.rows * 5));
      const tileW = Math.max(20, scaleFactor * 4);
      const tileH = Math.max(25, scaleFactor * 5);
      const finalW = tileW * diff.cols;
      const finalH = tileH * diff.rows; // finalW : finalH is exactly 4:5!

      const masterCanvas = document.createElement('canvas');
      masterCanvas.width = finalW;
      masterCanvas.height = finalH;
      const ctx = masterCanvas.getContext('2d');
      ctx.drawImage(img, srcX, srcY, srcW, srcH, 0, 0, finalW, finalH);

      if (state.currentMeme && !state.customImage) {
        drawMemeCaptions(ctx, finalW, finalH, state.currentMeme.topText, state.currentMeme.bottomText);
      }

      const tiles = [];
      for (let r = 0; r < diff.rows; r++) {
        for (let c = 0; c < diff.cols; c++) {
          const tileCanvas = document.createElement('canvas');
          tileCanvas.width = tileW;
          tileCanvas.height = tileH;
          const tCtx = tileCanvas.getContext('2d');
          tCtx.drawImage(masterCanvas, c * tileW, r * tileH, tileW, tileH, 0, 0, tileW, tileH);
          
          tiles.push({
            id: `tile_${r}_${c}`,
            row: r,
            col: c,
            dataUrl: tileCanvas.toDataURL('image/jpeg', 0.9)
          });
        }
      }
      resolve({ tiles, masterUrl: masterCanvas.toDataURL('image/jpeg', 0.95), finalW, finalH });
    };
    img.onerror = reject;
    img.src = state.customImage || state.currentMeme.src;
  });
}

function drawMemeCaptions(ctx, w, h, topText, bottomText) {
  const fontSize = Math.max(16, Math.floor(w * 0.055));
  ctx.font = `900 ${fontSize}px "Impact", "Arial Black", sans-serif`;
  ctx.textAlign = 'center';
  ctx.fillStyle = '#FFFFFF';
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = Math.max(3, Math.floor(fontSize * 0.12));
  ctx.lineJoin = 'miter';
  ctx.miterLimit = 2;

  if (topText) {
    ctx.textBaseline = 'top';
    ctx.strokeText(topText.toUpperCase(), w / 2, 14);
    ctx.fillText(topText.toUpperCase(), w / 2, 14);
  }
  if (bottomText) {
    ctx.textBaseline = 'bottom';
    ctx.strokeText(bottomText.toUpperCase(), w / 2, h - 14);
    ctx.fillText(bottomText.toUpperCase(), w / 2, h - 14);
  }
}

// Start / Initialize Puzzle
// Level Selection UI & Sequential Progression
function openLevelSelect(mode) {
  state.levelSelectMode = mode;
  switchScreen('screen-levels');

  const diff = DIFFICULTIES[mode] || DIFFICULTIES.easy;
  const titleEl = document.getElementById('level-mode-title');
  const progEl = document.getElementById('level-mode-progress');
  const gridEl = document.getElementById('level-cards-grid');

  if (titleEl) {
    titleEl.textContent = `${diff.name.toUpperCase()} LEVELS`;
    titleEl.style.color = diff.accent || '#fff';
  }

  // Filter memes for this mode (fallback to all memes if mode is hard/extreme and no dedicated folder yet)
  let pool = MEMES.filter(m => m.mode === mode);
  if (pool.length === 0) {
    pool = MEMES;
  }

  const maxUnlocked = (profile.unlockedLevel && profile.unlockedLevel[mode]) || 0;
  if (progEl) {
    progEl.textContent = `${Math.min(maxUnlocked + 1, pool.length)} / ${pool.length} UNLOCKED`;
    progEl.style.color = diff.accent || '#facc15';
  }

  if (!gridEl) return;
  gridEl.innerHTML = '';

  pool.forEach((meme, index) => {
    const levelNum = index + 1;
    const isUnlocked = isLevelUnlocked(mode, index);
    const isCompleted = profile.solvedMemeIds.includes(meme.id);

    const card = document.createElement('div');
    card.className = `level-grid-card ${isUnlocked ? 'unlocked' : 'locked'} ${isCompleted ? 'completed' : ''}`;
    card.dataset.levelIndex = index;
    card.dataset.memeId = meme.id;

    let overlayHtml = '';
    if (!isUnlocked) {
      overlayHtml = `
        <div class="level-lock-overlay">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
          </svg>
          <span class="level-lock-text">LOCKED</span>
        </div>`;
    } else if (isCompleted) {
      overlayHtml = `<span class="level-solved-badge">✓ SOLVED</span>`;
    }

    const displayTitle = getStandardMemeTitle(meme, index);

    card.innerHTML = `
      <div class="level-thumb-box">
        <img src="${meme.src}" alt="${displayTitle}" loading="lazy">
        <span class="level-num-pill">${levelNum}</span>
        ${overlayHtml}
      </div>
      <div class="level-meta">
        <span class="level-name">${displayTitle}</span>
        <span class="level-status-label">${!isUnlocked ? '🔒 Locked' : (isCompleted ? '✓ Completed' : '⚡ Ready')}</span>
      </div>
    `;

    card.onclick = () => {
      if (!isUnlocked) {
        playWrongSound();
        triggerHaptic('heavy');
        card.classList.remove('shake');
        void card.offsetWidth;
        card.classList.add('shake');
        showToast(`🔒 Level ${levelNum} is locked! Complete Level ${levelNum - 1} first.`);
        return;
      }
      playTone(523.25, 'triangle', 0.1);
      profile.selectedDifficulty = mode;
      saveProfile();
      state.currentLevelIndex = index;
      startPuzzle(mode, meme);
    };

    gridEl.appendChild(card);
  });
}

async function startPuzzle(mode = null, meme = null) {
  if (mode) state.mode = mode;
  if (meme) state.currentMeme = meme;

  CrazySDK.gameplayStart();

  clearInterval(state.timerInterval);
  state.isComplete = false;
  state.isTimeUp = false;
  state.placedCount = 0;
  state.moveCount = 0;
  state.mistakeCount = 0;
  state.selectedTile = null;

  const diff = DIFFICULTIES[state.mode];
  const isDaily = state.currentMeme && state.currentMeme.id && state.currentMeme.id.startsWith('daily_');
  const totalTimeLimit = isDaily ? 120 : diff.time;
  state.timeRemaining = totalTimeLimit;
  state.totalTime = totalTimeLimit;

  // Switch to game stage
  switchScreen('screen-game');

  // Update header labels
  memeTitleEl.textContent = state.currentMeme ? getStandardMemeTitle(state.currentMeme) : 'Custom Meme';
  modeBadgeEl.textContent = diff.name.toUpperCase();
  modeBadgeEl.className = `mode-badge ${state.mode}`;
  updateStatsLine();
  updateTimerUI();

  // Load and Slice
  const { tiles, masterUrl, finalW, finalH } = await loadAndSliceImage();
  state.tiles = tiles;

  // Peek overlay
  peekOverlayEl.style.backgroundImage = `url("${masterUrl}")`;
  peekOverlayEl.classList.remove('active');

  // Board layout sizing - guaranteed 3:2 aspect ratio fitting on one screen
  updateBoardDimensions();

  // Pick missing tiles scattered randomly
  const total = diff.rows * diff.cols;
  state.missingPositions = new Set();
  
  const shuffledIndices = Array.from({ length: total }, (_, i) => i).sort(() => Math.random() - 0.5);
  shuffledIndices.slice(0, diff.missing).forEach(idx => state.missingPositions.add(idx));

  // Build Board & Tray
  boardEl.innerHTML = '';
  trayGridEl.innerHTML = '';
  state.tray = [];

  tiles.forEach((tile, index) => {
    const isMissing = state.missingPositions.has(index);
    const cell = document.createElement('div');
    cell.className = `cell cell-${tile.row}-${tile.col}`;
    cell.dataset.row = tile.row;
    cell.dataset.col = tile.col;

    if (!isMissing) {
      cell.classList.add('prefilled');
      const img = document.createElement('img');
      img.src = tile.dataUrl;
      cell.appendChild(img);
    } else {
      cell.classList.add('slot');
      cell.dataset.expectedId = tile.id;
      
      // Slot dragover / drop
      cell.addEventListener('dragover', (e) => {
        if (state.isTimeUp || state.isComplete) return;
        e.preventDefault();
        cell.classList.add('drag-over');
      });
      cell.addEventListener('dragleave', () => cell.classList.remove('drag-over'));
      cell.addEventListener('drop', (e) => {
        if (state.isTimeUp || state.isComplete) return;
        e.preventDefault();
        cell.classList.remove('drag-over');
        const tileId = e.dataTransfer.getData('application/x-puzzle-tile') || e.dataTransfer.getData('text/plain');
        attemptPlacement(tileId, tile.row, tile.col, cell);
      });

      // Tap-to-place
      cell.onclick = () => {
        if (state.isTimeUp || state.isComplete) return;
        if (state.selectedTile) {
          attemptPlacement(state.selectedTile.id, tile.row, tile.col, cell);
        }
      };

      state.tray.push(tile);
    }

    boardEl.appendChild(cell);
  });

  // Shuffle tray pieces
  state.tray.sort(() => Math.random() - 0.5);
  renderTray();
  updateProgress();
  startCountdown();
}

// Render Missing Pieces in Tray
function renderTray() {
  trayGridEl.innerHTML = '';
  state.tray.forEach(tile => {
    const item = document.createElement('div');
    item.className = 'tray-item tray-tile';
    item.dataset.id = tile.id;
    item.draggable = true;

    const img = document.createElement('img');
    img.src = tile.dataUrl;
    item.appendChild(img);

    // Drag start
    item.addEventListener('dragstart', (e) => {
      if (state.isTimeUp || state.isComplete) return;
      document.body.classList.add('dragging-active');
      e.dataTransfer.setData('application/x-puzzle-tile', tile.id);
      e.dataTransfer.setData('text/plain', tile.id);
      item.classList.add('dragging');
      triggerHaptic('light');
    });

    item.addEventListener('dragend', () => {
      document.body.classList.remove('dragging-active');
      item.classList.remove('dragging');
    });

    // Tap to select
    item.onclick = () => {
      if (state.isTimeUp || state.isComplete) return;
      if (state.selectedTile && state.selectedTile.id === tile.id) {
        state.selectedTile = null;
        item.classList.remove('selected');
      } else {
        document.querySelectorAll('.tray-item').forEach(i => i.classList.remove('selected'));
        state.selectedTile = tile;
        item.classList.add('selected');
        triggerHaptic('light');
      }
    };

    trayGridEl.appendChild(item);
  });
}

// Placement Logic
function attemptPlacement(tileId, targetRow, targetCol, cellEl) {
  if (state.isTimeUp || state.isComplete) return;
  state.moveCount++;

  const tile = state.tiles.find(t => t.id === tileId);
  if (!tile) return;

  const isCorrect = tile.row === targetRow && tile.col === targetCol;

  if (isCorrect) {
    // Valid Drop
    playSuccessSound();
    triggerHaptic('medium');

    cellEl.classList.remove('slot', 'drag-over');
    cellEl.classList.add('placed');
    cellEl.innerHTML = `<img src="${tile.dataUrl}">`;

    // Remove from tray
    state.tray = state.tray.filter(t => t.id !== tileId);
    state.placedCount++;
    state.selectedTile = null;

    renderTray();
    updateProgress();
    checkCompletion();
  } else {
    // Invalid Drop
    playErrorSound();
    triggerHaptic('heavy');
    state.mistakeCount++;
    profile.totalMistakes++;
    saveProfile();
    updateStatsLine();

    cellEl.classList.add('error-flash');
    setTimeout(() => cellEl.classList.remove('error-flash'), 450);

    const trayItem = document.querySelector(`.tray-item[data-id="${tileId}"]`);
    if (trayItem) {
      trayItem.classList.add('tray-bounce-back');
      setTimeout(() => trayItem.classList.remove('tray-bounce-back'), 450);
    }
  }
}

// Progress Bar
function updateProgress() {
  const totalMissing = state.missingPositions.size;
  const pct = totalMissing > 0 ? (state.placedCount / totalMissing) * 100 : 0;
  progressBarEl.style.width = `${pct}%`;
  progressTextEl.textContent = `${state.placedCount}/${totalMissing} placed`;
}

// Countdown Timer
function startCountdown() {
  clearInterval(state.timerInterval);
  updateTimerUI();

  state.timerInterval = setInterval(() => {
    state.timeRemaining--;
    updateTimerUI();

    if (state.timeRemaining <= 10 && state.timeRemaining > 0) {
      playWarningTick(true);
    } else if (state.timeRemaining <= 25 && state.timeRemaining > 10) {
      playWarningTick(false);
    }

    if (state.timeRemaining <= 0) {
      clearInterval(state.timerInterval);
      triggerFailure();
    }
  }, 1000);
}

function updateTimerUI() {
  timerDigits.textContent = Math.max(0, state.timeRemaining);

  const radius = 18;
  const circumference = 2 * Math.PI * radius;
  const fraction = Math.max(0, state.timeRemaining / state.totalTime);
  const strokeOffset = circumference * (1 - fraction);

  timerFill.style.strokeDasharray = `${circumference}`;
  timerFill.style.strokeDashoffset = `${strokeOffset}`;

  const container = document.getElementById('timer-container');
  if (state.timeRemaining <= 10) {
    container.classList.add('urgent');
    timerFill.style.stroke = '#ef4444';
  } else {
    container.classList.remove('urgent');
    timerFill.style.stroke = '#facc15';
  }
}

function showTimerPenaltyAnim(text = '-10s') {
  const container = document.getElementById('timer-container');
  if (!container) return;
  container.classList.remove('timer-penalty-shake');
  void container.offsetWidth;
  container.classList.add('timer-penalty-shake');

  const badge = document.createElement('div');
  badge.className = 'timer-penalty-float';
  badge.textContent = text;
  container.appendChild(badge);
  setTimeout(() => badge.remove(), 900);
}

// Failure (Time's Up)
function triggerFailure() {
  state.isTimeUp = true;
  playFailSound();
  triggerHaptic('heavy');

  const total = state.missingPositions.size;
  const placed = state.placedCount;
  const remaining = total - placed;
  const pct = total > 0 ? Math.round((placed / total) * 100) : 0;

  document.getElementById('fail-progress-text').textContent = `${placed} of ${total} pieces placed`;
  document.getElementById('fail-remaining-text').textContent = `${remaining} piece${remaining === 1 ? '' : 's'} remaining`;
  document.getElementById('fail-percent').textContent = `${pct}%`;

  const radius = 18;
  const circ = 2 * Math.PI * radius;
  const offset = circ * (1 - (pct / 100));
  const failCircle = document.getElementById('fail-circle-fill');
  if (failCircle) {
    failCircle.style.strokeDasharray = `${circ}`;
    failCircle.style.strokeDashoffset = `${offset}`;
  }

  CrazySDK.gameplayStop();
  failModal.classList.add('active');
}

function updateStatsLine() {
  const diff = DIFFICULTIES[state.mode];
  statsLineEl.textContent = `${diff.cols}×${diff.rows} · ${state.mistakeCount} misses`;
}

// Victory & Stats Recording
function checkCompletion() {
  if (state.placedCount >= state.missingPositions.size) {
    state.isComplete = true;
    clearInterval(state.timerInterval);
    playWinSound();
    triggerHaptic('medium');
    fireConfetti();

    const elapsed = state.totalTime - state.timeRemaining;
    const mins = Math.floor(elapsed / 60);
    const secs = Math.floor(elapsed % 60);
    document.getElementById('win-time').textContent = `${mins}:${secs.toString().padStart(2, '0')}`;
    document.getElementById('win-moves').textContent = state.moveCount;
    const acc = state.moveCount > 0 ? Math.round((state.placedCount / state.moveCount) * 100) : 100;
    document.getElementById('win-accuracy').textContent = `${acc}%`;

    // Record Profile stats
    profile.totalSolved++;
    if (!profile.completedModes.includes(state.mode)) {
      profile.completedModes.push(state.mode);
    }
    if (!profile.bestTimes[state.mode] || elapsed < profile.bestTimes[state.mode]) {
      profile.bestTimes[state.mode] = elapsed;
    }
    if (!profile.bestTimesByMeme) profile.bestTimesByMeme = {};
    if (state.currentMeme) {
      const prevMemeBest = profile.bestTimesByMeme[state.currentMeme.id];
      if (!prevMemeBest || elapsed < prevMemeBest) {
        profile.bestTimesByMeme[state.currentMeme.id] = elapsed;
      }
    }
    if (state.currentMeme && !profile.solvedMemeIds.includes(state.currentMeme.id)) {
      profile.solvedMemeIds.push(state.currentMeme.id);
    }

    profile.streak = (profile.streak || 0) + 1;

    // XP calculation
    const baseXP = state.mode === 'easy' ? 60 : (state.mode === 'medium' ? 120 : (state.mode === 'hard' ? 250 : 450));
    const flawlessBonus = (state.mistakeCount === 0) ? 50 : 0;
    const speedBonus = (elapsed <= 30) ? 40 : 0;
    profile.xp = (profile.xp || 0) + baseXP + flawlessBonus + speedBonus;

    // Unlock next level in current mode
    if (!profile.unlockedLevel) profile.unlockedLevel = {};
    const curIdx = state.currentLevelIndex != null ? state.currentLevelIndex : 0;
    profile.unlockedLevel[state.mode] = Math.max((profile.unlockedLevel[state.mode] || 0), curIdx + 1);

    // Daily Blitz Solve Recording
    if (state.currentMeme && state.currentMeme.id && state.currentMeme.id.startsWith('daily_')) {
      const dailyInfo = getDailyBlitzInfo();
      if (profile.lastCompletedDailyDate !== dailyInfo.todayKey) {
        if (profile.lastCompletedDailyDate === dailyInfo.yesterdayKey) {
          profile.dailyStreak = (profile.dailyStreak || 0) + 1;
        } else {
          profile.dailyStreak = 1;
        }
        profile.lastCompletedDailyDate = dailyInfo.todayKey;
        // Big Daily Blitz bonus XP (+300 XP)
        profile.xp = (profile.xp || 0) + 300;
        showToast(`🔥 Daily Blitz Day ${dailyInfo.dayNumber} Solved! Streak: ${profile.dailyStreak}`);
      }
    }

    // Achievements check
    unlockAchievement('first_blitz');
    unlockAchievement('first_win');
    if (elapsed < 45) unlockAchievement('speed_demon');
    if (elapsed < 45) unlockAchievement('speed_sub45');
    if (elapsed <= 20 && (state.mode === 'medium' || state.mode === 'hard' || state.mode === 'extreme')) unlockAchievement('speed_sub20');
    if (state.mistakeCount === 0) {
      profile.flawlessCount = (profile.flawlessCount || 0) + 1;
      unlockAchievement('flawless');
      if (profile.flawlessCount >= 3) {
        unlockAchievement('surgical_precision');
      }
    }
    if (state.mode === 'hard') {
      unlockAchievement('galaxy_brain');
      unlockAchievement('hard_core');
    }
    if (state.mode === 'extreme') unlockAchievement('extreme_champion');
    if (profile.totalSolved >= 5) unlockAchievement('puzzle_novice');
    if (profile.totalSolved >= 25) unlockAchievement('puzzle_artisan');
    if (profile.totalSolved >= 50) unlockAchievement('puzzle_grandmaster');
    if (profile.solvedMemeIds.length >= 10) unlockAchievement('collector_10');
    if (profile.solvedMemeIds.length >= 25) unlockAchievement('collector_25');
    if (profile.solvedMemeIds.length >= 100) unlockAchievement('meme_master');
    if (profile.streak >= 3) unlockAchievement('streak_3');
    if (profile.streak >= 5) unlockAchievement('streak_5');
    if (profile.streak >= 10) unlockAchievement('streak_10');

    rotateCompetitiveChallengeQuote();

    saveProfile();
    renderCatalog();

    CrazySDK.happytime();
    CrazySDK.gameplayStop();

    setTimeout(() => winModal.classList.add('active'), 600);
  }
}

// Simple Confetti
function fireConfetti() {
  const canvas = document.getElementById('confetti-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;

  const pieces = [];
  const colors = ['#FF4E8E', '#FFD60A', '#30D158', '#0A84FF', '#BF5AF2'];
  for (let i = 0; i < 90; i++) {
    pieces.push({
      x: canvas.width / 2,
      y: canvas.height * 0.4,
      vx: (Math.random() - 0.5) * 14,
      vy: (Math.random() - 1.2) * 12,
      size: Math.random() * 8 + 4,
      color: colors[Math.floor(Math.random() * colors.length)],
      rotation: Math.random() * 360,
      vRot: (Math.random() - 0.5) * 10
    });
  }

  let frame = 0;
  function animate() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    pieces.forEach(p => {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.35;
      p.rotation += p.vRot;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate((p.rotation * Math.PI) / 180);
      ctx.fillStyle = p.color;
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size);
      ctx.restore();
    });
    frame++;
    if (frame < 180) {
      requestAnimationFrame(animate);
    } else {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
  }
  animate();
}

// Rewarded Ad (CrazyGames SDK v3 + Second Wind Achievement)
const btnWatchAd = document.getElementById('btn-watch-ad');
if (btnWatchAd) {
  btnWatchAd.onclick = () => {
    btnWatchAd.disabled = true;
    btnWatchAd.textContent = 'Loading Ad…';

    CrazySDK.requestRewarded(
      () => {
        // onReward success
        state.isTimeUp = false;
        state.timeRemaining = 20;
        state.totalTime = Math.max(state.totalTime, 20);
        failModal.classList.remove('active');
        btnWatchAd.disabled = false;
        btnWatchAd.innerHTML = `
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M4 6h16a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2zm6 2.5v7l6-3.5-6-3.5z"/></svg>
          Watch Ad to Continue (+20s)
        `;
        unlockAchievement('second_wind');
        showToast('💨 Second Wind! +20s added');
        startCountdown();
      },
      () => {
        // onError fallback (give user a chance anyway)
        state.isTimeUp = false;
        state.timeRemaining = 20;
        state.totalTime = Math.max(state.totalTime, 20);
        failModal.classList.remove('active');
        btnWatchAd.disabled = false;
        btnWatchAd.innerHTML = `
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M4 6h16a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2zm6 2.5v7l6-3.5-6-3.5z"/></svg>
          Watch Ad to Continue (+20s)
        `;
        unlockAchievement('second_wind');
        startCountdown();
      }
    );
  };
}

// UI Interactions & Controls Wiring
function initLaunchScreen() {
  const overlay = document.getElementById('launch-screen');
  const video = document.getElementById('launch-video');

  if (!overlay || !video) return;

  let dismissed = false;

  function dismissLaunchScreen() {
    if (dismissed) return;
    dismissed = true;
    overlay.classList.add('launch-dismissed');
    try {
      video.pause();
    } catch (_) {}
    setTimeout(() => {
      overlay.style.display = 'none';
    }, 500);

    // Automatically start background music once the launch has finished!
    if (profile.musicEnabled !== false) {
      playBGM();
    }

    // Fallback if browser blocked BGM autoplay until a click after launch
    const startBGMOnGameClick = () => {
      if (profile.musicEnabled !== false) {
        playBGM();
      }
      window.removeEventListener('pointerdown', startBGMOnGameClick);
      window.removeEventListener('keydown', startBGMOnGameClick);
    };
    window.addEventListener('pointerdown', startBGMOnGameClick, { once: true });
    window.addEventListener('keydown', startBGMOnGameClick, { once: true });
  }

  // Ensure video sound is enabled
  video.muted = false;
  video.volume = 1.0;

  video.addEventListener('ended', () => {
    dismissLaunchScreen();
  });

  video.addEventListener('error', () => {
    dismissLaunchScreen();
  });

  const playPromise = video.play();
  if (playPromise !== undefined) {
    playPromise.catch((err) => {
      console.warn('[LaunchVideo] Unmuted autoplay blocked by browser policy:', err);
      // Fallback: play muted as initial fallback so video frames move, and show unmute prompt
      video.muted = true;
      video.play().catch(() => {});

      let unmutePill = document.getElementById('launch-unmute-pill');
      if (!unmutePill) {
        unmutePill = document.createElement('div');
        unmutePill.id = 'launch-unmute-pill';
        unmutePill.className = 'launch-unmute-pill';
        unmutePill.innerHTML = `<span>🔊 Tap for sound</span>`;
        overlay.appendChild(unmutePill);
      }

      const doUnmuteAndRestart = (e) => {
        if (e) {
          e.stopPropagation();
        }
        try {
          video.muted = false;
          video.volume = 1.0;
          video.currentTime = 0;
          video.play().catch(() => {});
          if (unmutePill) unmutePill.remove();
        } catch (_) {}
        window.removeEventListener('pointerdown', doUnmuteAndRestart);
        window.removeEventListener('keydown', doUnmuteAndRestart);
      };
      window.addEventListener('pointerdown', doUnmuteAndRestart, { once: true });
      window.addEventListener('keydown', doUnmuteAndRestart, { once: true });
    });
  }

  // Fallback safety timeout (video duration is ~5.97s + buffer)
  setTimeout(() => {
    dismissLaunchScreen();
  }, 7500);
}

document.addEventListener('DOMContentLoaded', async () => {
  CrazySDK.loadingStart();
  await CrazySDK.init();
  CrazySDK.loadingStop();

  initLaunchScreen();
  loadProfile();
  updateProfileUI();

  // Top Bar buttons
  const btnStats = document.getElementById('btn-top-stats');
  if (btnStats) btnStats.onclick = () => statsModal.classList.add('active');

  const btnCloseStats = document.getElementById('btn-close-stats');
  if (btnCloseStats) btnCloseStats.onclick = () => statsModal.classList.remove('active');

  const btnSound = document.getElementById('btn-top-sound');
  if (btnSound) {
    btnSound.onclick = () => {
      profile.soundEnabled = !profile.soundEnabled;
      saveProfile();
      playTone(520, 'sine', 0.1);
      showToast(profile.soundEnabled ? '🔊 Sound Enabled' : '🔇 Sound Muted');
    };
  }

  const btnSettings = document.getElementById('btn-top-settings');
  if (btnSettings) btnSettings.onclick = () => settingsModal.classList.add('active');

  const btnCloseSettings = document.getElementById('btn-close-settings');
  if (btnCloseSettings) btnCloseSettings.onclick = () => settingsModal.classList.remove('active');

  // Daily Blitz Play button (Hard Mode · 10x10 · 32 pcs · 35s timer · -10s Eye)
  const btnDailyPlay = document.getElementById('btn-daily-play');
  if (btnDailyPlay) {
    btnDailyPlay.onclick = () => {
      const dailyInfo = getDailyBlitzInfo();
      playTone(520, 'sine', 0.1);
      triggerHaptic('medium');
      startPuzzle('hard', dailyInfo.meme);
    };
  }

  // Floating Meme Cards - Playful animation on click (does NOT navigate to puzzle)
  document.querySelectorAll('.floating-meme-card').forEach(btn => {
    btn.onclick = (e) => {
      e.preventDefault();
      e.stopPropagation();

      btn.classList.remove('card-bounce-pop');
      void btn.offsetWidth; // Force CSS reflow to replay keyframe
      btn.classList.add('card-bounce-pop');

      triggerHaptic('light');
      playPopBounceSound();
      spawnCardSparkles(btn);
    };
  });

  // Difficulty Play Buttons
  document.querySelectorAll('.btn-play-pill').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      const mode = btn.dataset.mode;
      if (!isModeUnlocked(mode)) {
        playWrongSound();
        triggerHaptic('heavy');
        showToast(`🔒 ${mode.toUpperCase()} is locked! Beat ${mode === 'medium' ? 'Easy' : 'Medium'} mode first.`);
        return;
      }
      profile.selectedDifficulty = mode;
      saveProfile();
      startPuzzle(mode, state.currentMeme || MEMES[0]);
    };
  });

  // Difficulty Cards & Play Buttons -> Open Level Select
  document.querySelectorAll('.btn-play-pill').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      const mode = btn.dataset.mode;
      handleDifficultySelect(mode);
    };
  });

  document.querySelectorAll('.diff-arcade-card').forEach(card => {
    card.onclick = () => {
      const mode = card.id.replace('card-', '');
      handleDifficultySelect(mode);
    };
  });

  function handleDifficultySelect(mode) {
    if (!isModeUnlocked(mode)) {
      playWrongSound();
      triggerHaptic('heavy');
      const prev = mode === 'medium' ? 'Easy' : (mode === 'hard' ? 'Medium' : 'Hard');
      showToast(`🔒 ${mode.toUpperCase()} is locked! Complete ${prev} mode first.`);
      return;
    }
    playTone(523.25, 'triangle', 0.1);
    openLevelSelect(mode);
  }

  // Back from Level Select
  const btnLevelBack = document.getElementById('btn-level-back');
  if (btnLevelBack) {
    btnLevelBack.onclick = () => {
      playTone(440, 'triangle', 0.08);
      switchScreen('screen-home');
    };
  }

  // Bottom Navigation Bar tabs
  document.querySelectorAll('.nav-tab-btn').forEach(btn => {
    btn.onclick = () => switchScreen(btn.dataset.tab);
  });

  // In-Game Back & Restart Controls
  const btnGameBack = document.getElementById('btn-game-back');
  if (btnGameBack) {
    btnGameBack.onclick = () => {
      clearInterval(state.timerInterval);
      openLevelSelect(state.mode);
    };
  }

  const btnRestart = document.getElementById('btn-restart');
  if (btnRestart) btnRestart.onclick = () => startPuzzle(state.mode, state.currentMeme);

  const btnWinReplay = document.getElementById('btn-win-replay');
  if (btnWinReplay) {
    btnWinReplay.onclick = () => {
      winModal.classList.remove('active');
      startPuzzle(state.mode, state.currentMeme);
    };
  }

  const btnWinLevels = document.getElementById('btn-win-levels');
  if (btnWinLevels) {
    btnWinLevels.onclick = () => {
      winModal.classList.remove('active');
      openLevelSelect(state.mode);
    };
  }

  const btnWinHome = document.getElementById('btn-win-home');
  if (btnWinHome) {
    btnWinHome.onclick = () => {
      winModal.classList.remove('active');
      switchScreen('screen-home');
    };
  }

  const btnWinNew = document.getElementById('btn-win-new');
  if (btnWinNew) {
    btnWinNew.onclick = () => {
      winModal.classList.remove('active');
      CrazySDK.requestMidgame(() => {
        let pool = MEMES.filter(m => m.mode === state.mode);
        if (pool.length === 0) pool = MEMES;
        const nextIdx = (state.currentLevelIndex != null ? state.currentLevelIndex : 0) + 1;
        if (nextIdx < pool.length) {
          state.currentLevelIndex = nextIdx;
          startPuzzle(state.mode, pool[nextIdx]);
        } else {
          openLevelSelect(state.mode);
        }
      });
    };
  }

  const btnFailRetry = document.getElementById('btn-fail-retry');
  if (btnFailRetry) {
    btnFailRetry.onclick = () => {
      failModal.classList.remove('active');
      CrazySDK.requestMidgame(() => {
        startPuzzle(state.mode, state.currentMeme);
      });
    };
  }

  const btnFailLevels = document.getElementById('btn-fail-levels');
  if (btnFailLevels) {
    btnFailLevels.onclick = () => {
      failModal.classList.remove('active');
      openLevelSelect(state.mode);
    };
  }

  const btnFailModes = document.getElementById('btn-fail-modes');
  if (btnFailModes) {
    btnFailModes.onclick = () => {
      failModal.classList.remove('active');
      switchScreen('screen-home');
    };
  }

  // Peek button with competitive 10-second penalty
  const btnPeek = document.getElementById('btn-peek');
  let isPeekingActive = false;

  function triggerPeekPenalty() {
    if (state.isComplete || state.isTimeUp) return;
    state.timeRemaining = Math.max(0, state.timeRemaining - 10);
    updateTimerUI();
    triggerHaptic('medium');
    playTone(220, 'sawtooth', 0.12);
    showTimerPenaltyAnim('-10s');

    if (state.timeRemaining <= 0) {
      clearInterval(state.timerInterval);
      triggerFailure();
    }
  }

  if (btnPeek) {
    btnPeek.setAttribute('title', 'Peek at full meme (-10s penalty)');
    btnPeek.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      if (!isPeekingActive) {
        isPeekingActive = true;
        peekOverlayEl.classList.add('active');
        triggerPeekPenalty();
      }
    });

    const endPeek = () => {
      if (isPeekingActive) {
        isPeekingActive = false;
        peekOverlayEl.classList.remove('active');
      }
    };

    window.addEventListener('pointerup', endPeek);
    window.addEventListener('pointercancel', endPeek);
  }

  // Settings Toggles
  const toggleSound = document.getElementById('toggle-sound');
  if (toggleSound) {
    toggleSound.onchange = (e) => {
      profile.soundEnabled = e.target.checked;
      saveProfile();
    };
  }

  const toggleMusic = document.getElementById('toggle-music');
  if (toggleMusic) {
    toggleMusic.onchange = (e) => {
      profile.musicEnabled = e.target.checked;
      saveProfile();
      if (profile.musicEnabled) {
        playBGM();
      } else {
        pauseBGM();
      }
    };
  }

  const toggleHaptics = document.getElementById('toggle-haptics');
  if (toggleHaptics) {
    toggleHaptics.onchange = (e) => {
      profile.hapticsEnabled = e.target.checked;
      saveProfile();
    };
  }

  // Sound Pack Buttons
  document.querySelectorAll('.sound-pack-btn').forEach(btn => {
    btn.onclick = () => {
      const packKey = btn.dataset.pack;
      if (SOUND_PACKS[packKey]) {
        profile.selectedSoundPack = packKey;
        saveProfile();
        updateProfileUI();
        const pack = SOUND_PACKS[packKey];
        const preview = pack.sounds[Math.floor(Math.random() * pack.sounds.length)];
        playWinSound(preview);
      }
    };
  });

  // Leaderboard Modal Logic
  function renderLeaderboardModal() {
    const listEl = document.getElementById('leaderboard-ranks-list');
    if (!listEl) return;

    const fmt = (sec) => {
      if (sec == null) return '--:--';
      const m = Math.floor(sec / 60);
      const s = Math.floor(sec % 60);
      return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    };

    const records = [
      {
        medal: '🥇',
        name: 'Easy Blitz Record',
        desc: 'Fastest 6×6 puzzle solve',
        score: fmt(profile.bestTimes.easy),
        highlight: profile.bestTimes.easy != null
      },
      {
        medal: '🥈',
        name: 'Medium Blitz Record',
        desc: 'Fastest 8×8 puzzle solve',
        score: fmt(profile.bestTimes.medium),
        highlight: profile.bestTimes.medium != null
      },
      {
        medal: '🥉',
        name: 'Hard Blitz Record',
        desc: 'Fastest 10×10 puzzle solve',
        score: fmt(profile.bestTimes.hard),
        highlight: profile.bestTimes.hard != null
      },
      {
        medal: '💀',
        name: 'Extreme 48-Piece Record',
        desc: 'Hardcore blitz challenge solve',
        score: fmt(profile.bestTimes.extreme),
        highlight: profile.bestTimes.extreme != null
      },
      {
        medal: '🔥',
        name: 'Solving Streak',
        desc: 'Current consecutive solves',
        score: `${profile.streak || 0} in a row`,
        highlight: (profile.streak || 0) > 0
      },
      {
        medal: '🧩',
        name: 'Total Memes Restored',
        desc: 'Catalog completion count',
        score: `${profile.totalSolved || 0} solved`,
        highlight: (profile.totalSolved || 0) > 0
      }
    ];

    listEl.innerHTML = records.map(r => `
      <div class="leaderboard-rank-card ${r.highlight ? 'highlight' : ''}">
        <div class="lb-rank-info">
          <span class="lb-medal">${r.medal}</span>
          <div class="lb-title-group">
            <span class="lb-name">${r.name}</span>
            <span class="lb-desc">${r.desc}</span>
          </div>
        </div>
        <span class="lb-score">${r.score}</span>
      </div>
    `).join('');
  }

  const btnTopLeaderboard = document.getElementById('btn-top-leaderboard');
  const leaderboardModal = document.getElementById('leaderboard-modal');
  const btnCloseLeaderboard = document.getElementById('btn-close-leaderboard');
  const btnCloseLeaderboardX = document.getElementById('btn-close-leaderboard-x');

  function openLeaderboard() {
    renderLeaderboardModal();
    if (leaderboardModal) leaderboardModal.classList.add('active');
  }
  function closeLeaderboard() {
    if (leaderboardModal) leaderboardModal.classList.remove('active');
  }

  if (btnTopLeaderboard) btnTopLeaderboard.onclick = openLeaderboard;
  if (btnCloseLeaderboard) btnCloseLeaderboard.onclick = closeLeaderboard;
  if (btnCloseLeaderboardX) btnCloseLeaderboardX.onclick = closeLeaderboard;
  if (leaderboardModal) {
    leaderboardModal.onclick = (e) => {
      if (e.target.id === 'leaderboard-modal') closeLeaderboard();
    };
  }

  // Competitive Challenge Banner
  const challengeBanner = document.getElementById('blitz-challenge-banner');
  if (challengeBanner) {
    challengeBanner.onclick = openLeaderboard;
  }
  rotateCompetitiveChallengeQuote();

  document.querySelectorAll('.diff-toggle-btn').forEach(btn => {
    btn.onclick = () => {
      profile.selectedDifficulty = btn.dataset.diff;
      document.querySelectorAll('.diff-toggle-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.diff === profile.selectedDifficulty);
      });
      playTone(523.25, 'triangle', 0.08);
      saveProfile();
    };
  });

  const btnReset = document.getElementById('btn-reset-data');
  if (btnReset) {
    btnReset.onclick = () => {
      if (confirm('Reset all high scores and player progress?')) {
        try {
          if (window.CrazyGames?.SDK?.data?.clear) {
            window.CrazyGames.SDK.data.clear();
          }
        } catch (_) {}
        localStorage.clear();
        sessionStorage.clear();
        profile.bestTimes = { easy: null, medium: null, hard: null, extreme: null };
        profile.totalSolved = 0;
        profile.totalMistakes = 0;
        profile.solvedMemeIds = [];
        profile.achievements = [];
        profile.completedModes = [];
        profile.unlockedLevel = { easy: 0, medium: 0, hard: 0, extreme: 0 };
        profile.dailyStreak = 0;
        profile.lastCompletedDailyDate = null;
        saveProfile();
        settingsModal.classList.remove('active');
        showToast('Player data reset.');
      }
    };
  }

  // Meme Detail Modal Close Listeners
  const btnCloseMemeDetail = document.getElementById('btn-close-meme-detail');
  if (btnCloseMemeDetail) {
    btnCloseMemeDetail.onclick = closeMemeDetail;
  }
  const memeDetailModal = document.getElementById('meme-detail-modal');
  if (memeDetailModal) {
    memeDetailModal.onclick = (e) => {
      if (e.target.id === 'meme-detail-modal') closeMemeDetail();
    };
  }

  // Init Data
  renderCatalog();
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    await fetchRemoteCatalog();
    setupRemoteEventSource();
  }
  const initialParams = new URLSearchParams(window.location.search);
  const initialFilter = initialParams.get('filter');
  if (initialFilter && ['all', 'easy', 'medium', 'hard', 'extreme'].includes(initialFilter.toLowerCase())) {
    currentCollectionFilter = initialFilter.toLowerCase();
    renderCatalog();
  }
  const initialTab = initialParams.get('tab') || window.location.hash.replace('#', '');
  const initialMode = initialParams.get('mode');
  const initialPlay = initialParams.get('play');
  if (initialTab === 'collection') {
    switchScreen('screen-collection');
  } else if (initialTab === 'achievements') {
    switchScreen('screen-achievements');
  } else if (initialMode && DIFFICULTIES[initialMode]) {
    if (initialPlay) {
      const memePool = MEMES.filter(m => m.mode === initialMode);
      startPuzzle(initialMode, memePool[0] || MEMES[0]).then(() => {
        if (initialParams.get('peek') === '1') {
          setTimeout(() => {
            const btnPeek = document.getElementById('btn-peek');
            if (btnPeek) {
              btnPeek.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
            }
          }, 350);
        }
        if (initialParams.get('fail') === '1') {
          setTimeout(() => {
            onGameFail();
          }, 350);
        }
      });
    } else {
      openLevelSelect(initialMode);
      if (initialParams.get('scroll') === 'bottom') {
        const gridEl = document.getElementById('level-cards-grid');
        if (gridEl && gridEl.lastElementChild) {
          gridEl.lastElementChild.scrollIntoView();
        }
      }
    }
  } else {
    switchScreen('screen-home');
  }

  const initialModal = initialParams.get('modal');
  if (initialModal === 'settings') {
    const sModal = document.getElementById('settings-modal');
    if (sModal) sModal.classList.add('active');
  } else if (initialModal === 'stats') {
    const stModal = document.getElementById('stats-modal');
    if (stModal) stModal.classList.add('active');
  } else if (initialModal === 'fail') {
    const fModal = document.getElementById('fail-modal');
    if (fModal) fModal.classList.add('active');
  } else if (initialModal === 'win') {
    const wModal = document.getElementById('win-modal');
    if (wModal) wModal.classList.add('active');
  }
});
