import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;
const WEB_DIR = __dirname;
const MEMES_DIR = path.join(__dirname, 'memes');
const DROP_DIR = path.resolve(__dirname, '../memes_drop');
const REA_SITE_DIR = path.resolve(__dirname, '../../../website/public');

// Ensure directories exist
if (!fs.existsSync(MEMES_DIR)) fs.mkdirSync(MEMES_DIR, { recursive: true });
if (!fs.existsSync(DROP_DIR)) fs.mkdirSync(DROP_DIR, { recursive: true });

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.heic': 'image/heic',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.mp4': 'video/mp4',
  '.m4v': 'video/mp4',
  '.webm': 'video/webm',
  '.m4a': 'audio/mp4',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav'
};

const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic']);

const KNOWN_CAPTIONS = {
  shocked_cat: { title: 'Shocked Cat', topText: 'WHEN YOU CHECK YOUR', bottomText: 'SCREEN TIME REPORT' },
  office_dog: { title: 'Calm Office Dog', topText: 'ME IN THE MEETING', bottomText: 'AFTER THE DEADLINE MOVED AGAIN' },
  raccoon_ceo: { title: 'Raccoon CEO', topText: 'ATE FROM THE TRASH', bottomText: 'CALLED IT A PIVOT' },
  side_eye_shiba: { title: 'Side-Eye Shiba', topText: '"THOSE ARE FOR GUESTS"', bottomText: 'THE GUESTS:' },
  distracted_doggo: { title: 'Distracted Pup', topText: 'ME LOOKING AT A NEW SIDE PROJECT', bottomText: 'MY UNFINISHED TASKS:' },
  this_is_fine_fox: { title: 'This Is Fine Fox', topText: 'EVERYTHING IS FINE', bottomText: 'TOTALLY UNDER CONTROL' },
  dramatic_hamster: { title: 'Dramatic Hamster', topText: 'WHEN THEY SAY', bottomText: '"WE NEED TO TALK"' },
  confused_math_cat: { title: 'Confused Math Cat', topText: 'CALCULATING HOW 8 HOURS OF SLEEP', bottomText: 'FELT LIKE 12 MINUTES' },
  success_otter: { title: 'Success Otter', topText: 'PUSHED TO PRODUCTION ON FRIDAY', bottomText: 'NOTHING BROKE' },
  grumpy_bunny: { title: 'Grumpy Bunny', topText: 'I WOKE UP TODAY', bottomText: '0 OUT OF 10 DO NOT RECOMMEND' }
};

function formatTitleFromFilename(filename) {
  const base = path.basename(filename, path.extname(filename));
  const match = base.match(/^(easy|medium|hard|extreme)_(\d+)/i);
  if (match) {
    const tier = match[1].charAt(0).toUpperCase() + match[1].slice(1).toLowerCase();
    const num = parseInt(match[2], 10);
    return `${tier} Meme ${num}`;
  }
  const parts = base.split('_');
  if (parts.length >= 2 && (parts[0] === 'easy' || parts[0] === 'medium' || parts[0] === 'hard' || parts[0] === 'extreme')) {
    const tier = parts[0].charAt(0).toUpperCase() + parts[0].slice(1).toLowerCase();
    return `${tier} Meme ${parseInt(parts[1], 10) || parts[1]}`;
  }
  return base
    .replace(/[_-]+/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\b\w/g, char => char.toUpperCase())
    .trim();
}

function syncDropDirectory() {
  try {
    const droppedFiles = fs.readdirSync(DROP_DIR);
    for (const file of droppedFiles) {
      if (file.startsWith('.')) continue;
      const ext = path.extname(file).toLowerCase();
      if (!IMAGE_EXTENSIONS.has(ext)) continue;
      const srcPath = path.join(DROP_DIR, file);
      const dstPath = path.join(MEMES_DIR, file);
      if (!fs.existsSync(dstPath)) {
        fs.copyFileSync(srcPath, dstPath);
        console.log(`[Auto-Sync] Copied newly dropped meme: ${file}`);
      }
    }
  } catch (err) {
    console.error('Error syncing drop directory:', err.message);
  }
}

function getMemesCatalog() {
  syncDropDirectory();
  const memes = [];
  const seenIds = new Set();

  try {
    const files = fs.readdirSync(MEMES_DIR);
    // Sort files so initial bundled memes come first, followed by newest dropped
    files.sort((a, b) => {
      const aIsKnown = Object.prototype.hasOwnProperty.call(KNOWN_CAPTIONS, path.basename(a, path.extname(a)));
      const bIsKnown = Object.prototype.hasOwnProperty.call(KNOWN_CAPTIONS, path.basename(b, path.extname(b)));
      if (aIsKnown && !bIsKnown) return -1;
      if (!aIsKnown && bIsKnown) return 1;
      return a.localeCompare(b);
    });

    for (const file of files) {
      if (file.startsWith('.')) continue;
      const ext = path.extname(file).toLowerCase();
      if (!IMAGE_EXTENSIONS.has(ext)) continue;

      const id = path.basename(file, ext);
      if (seenIds.has(id)) continue;
      seenIds.add(id);

      const filePath = path.join(MEMES_DIR, file);
      const stats = fs.statSync(filePath);
      const known = KNOWN_CAPTIONS[id];

      // Check for accompanying .json metadata file
      const jsonMetaPath = path.join(MEMES_DIR, `${id}.json`);
      let customMeta = {};
      if (fs.existsSync(jsonMetaPath)) {
        try {
          customMeta = JSON.parse(fs.readFileSync(jsonMetaPath, 'utf8'));
        } catch (e) {}
      }

      const isCurated = file.startsWith('easy_') || file.startsWith('medium_') || file.startsWith('hard_') || file.startsWith('extreme_');
      const mode = file.startsWith('extreme_') ? 'extreme' : (file.startsWith('hard_') ? 'hard' : (file.startsWith('medium_') ? 'medium' : 'easy'));
      const title = isCurated ? formatTitleFromFilename(file) : (customMeta.title || (known ? known.title : formatTitleFromFilename(file)));
      const topText = customMeta.topText || (known ? known.topText : '');
      const bottomText = customMeta.bottomText || (known ? known.bottomText : '');

      memes.push({
        id,
        title,
        filename: file,
        src: `memes/${file}`,
        topText,
        bottomText,
        mode,
        isRemote: !isCurated,
        mtime: stats.mtimeMs
      });
    }
  } catch (err) {
    console.error('Error scanning memes directory:', err.message);
  }

  return memes;
}

// Active Server-Sent Events subscribers
const sseClients = new Set();

function broadcastCatalogUpdate() {
  const catalog = getMemesCatalog();
  const payload = JSON.stringify({ event: 'catalog_updated', count: catalog.length, memes: catalog });
  const message = `event: update\ndata: ${payload}\n\n`;

  for (const client of sseClients) {
    try {
      client.write(message);
    } catch (e) {
      sseClients.delete(client);
    }
  }
}

// Watch DROP_DIR for live file drops
let dropWatchDebounce = null;
try {
  fs.watch(DROP_DIR, (eventType, filename) => {
    if (filename && !filename.startsWith('.')) {
      clearTimeout(dropWatchDebounce);
      dropWatchDebounce = setTimeout(() => {
        console.log(`[Drop Watch] Detected change in drop folder: ${filename}`);
        syncDropDirectory();
        broadcastCatalogUpdate();
      }, 300);
    }
  });
  console.log(`Watching drop folder at: ${DROP_DIR}`);
} catch (e) {
  console.warn('Watch on drop folder could not be established:', e.message);
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Range');
}

function serveFile(req, res, filePath) {
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('404 Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    setCorsHeaders(res);
    res.setHeader('Accept-Ranges', 'bytes');

    const range = req.headers && req.headers.range;
    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : stats.size - 1;
      if (!isNaN(start) && start <= stats.size - 1) {
        const validEnd = Math.min(end, stats.size - 1);
        const chunksize = (validEnd - start) + 1;
        res.writeHead(206, {
          'Content-Range': `bytes ${start}-${validEnd}/${stats.size}`,
          'Content-Length': chunksize,
          'Content-Type': contentType,
          'Cache-Control': 'no-cache'
        });
        fs.createReadStream(filePath, { start, end: validEnd }).pipe(res);
        return;
      }
    }

    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'Content-Length': stats.size
    });

    fs.createReadStream(filePath).pipe(res);
  });
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost:3000'}`);
  let pathname = decodeURIComponent(url.pathname);

  // Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    setCorsHeaders(res);
    res.writeHead(204);
    res.end();
    return;
  }

  // API: Get Memes Catalog
  if (pathname === '/api/memes' && req.method === 'GET') {
    setCorsHeaders(res);
    const memes = getMemesCatalog();
    res.writeHead(200, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-cache'
    });
    res.end(JSON.stringify({
      version: 1,
      timestamp: Date.now(),
      count: memes.length,
      memes
    }));
    return;
  }

  // API: Server-Sent Events stream for live remote updates
  if (pathname === '/api/memes/stream' && req.method === 'GET') {
    setCorsHeaders(res);
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write('retry: 5000\n\n');

    // Send initial state immediately
    const initialCatalog = getMemesCatalog();
    res.write(`event: init\ndata: ${JSON.stringify({ count: initialCatalog.length, memes: initialCatalog })}\n\n`);

    sseClients.add(res);
    req.on('close', () => sseClients.delete(res));
    return;
  }

  // API: Upload has been completely removed to prevent uncurated content
  if (pathname === '/api/memes/upload') {
    setCorsHeaders(res);
    res.writeHead(403, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ error: 'Image upload is disabled to ensure curated, child-safe content.' }));
    return;
  }

  // Serve REA docs website under /rea/
  if (pathname.startsWith('/rea/')) {
    let subpath = pathname.substring(5);
    if (!subpath || subpath.endsWith('/')) subpath += 'index.html';
    const filePath = path.join(REA_SITE_DIR, subpath);
    serveFile(req, res, filePath);
    return;
  }

  // Serve Meme Block Puzzle Game assets
  if (pathname === '/') pathname = '/index.html';
  const filePath = path.join(WEB_DIR, pathname);
  serveFile(req, res, filePath);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://localhost:${PORT}/`);
  console.log(`Meme Block Puzzle: http://localhost:${PORT}/`);
  console.log(`Remote Catalog API: http://localhost:${PORT}/api/memes`);
  console.log(`Live Drop Folder: ${DROP_DIR}`);
  console.log(`REA Docs & Website: http://localhost:${PORT}/rea/`);
});
