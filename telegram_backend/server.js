const express = require('express');
const { TelegramClient, Api } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { NewMessage } = require('telegram/events');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

// ==========================================
// 1. FIREBASE INITIALIZATION
// ==========================================
// Try loading serviceAccountKey.json, else check environment variable
let serviceAccount;
try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (e) {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    console.error("❌ Firebase service account key not found!");
    process.exit(1);
  }
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// ==========================================
// 2. EXPRESS APP SETUP
// ==========================================
const app = express();
app.use(cors());
app.use(express.json());

// ==========================================
// 3. DUAL TELEGRAM CLIENT SETUP (SDWB2 Architecture)
// ==========================================
const apiId = parseInt(process.env.API_ID || '29507367');
const apiHash = process.env.API_HASH || 'a99c710ea3f1530e5600d27ac8f3fe84';
const botToken = process.env.BOT_TOKEN || '8625523630:AAEGanx-X7n4GKdIMgWFVuhdtldHVyecGXI';
const userSession = process.env.SESSION_STRING || '1BVtsOIUBu7xMx9lE4QiHTIlfR_EHGBEBPo0fBztkSg2OzUf243J6MTXrn2--G0RdV4ZYOhne101ZeKL494VLkeo-g7CavefitFfLmVcw9-kyOciAvFTRlYmOHOci6Z0RPvTPZ-_00HuAfK50acaV-n86n2QgiPVBANeiPuFGfELJWHfkNggb0ml-8KkutLJLYefKxTUiSP3JayH5xoLEPElmRvy2SNxMW2FdlUaDmg9dthDUc-dPg2b_z_1LBTFsH49KDJMEZGFxzAViD4I9jcz0IXQtiDvgA0USussjGQFiMuozto9yZuqITrhy55v6WbZuFH0oKLzjJcBeBGNY6WZqvTpPLus=';

let botClient = null;
let userClient = null;

async function startClients() {
  // 1. Initialize UserBot client (User session) if provided.
  // UserBot is essential for private/restricted channels where the Bot token is not allowed.
  if (userSession) {
    userClient = new TelegramClient(new StringSession(userSession), apiId, apiHash, {
      connectionRetries: 5,
    });
    try {
      await userClient.start();
      console.log('👤 User Client (UserBot) Connected successfully!');
    } catch (e) {
      console.error('❌ Failed to start User Client:', e.message);
    }
  }

  // 2. Initialize primary Bot token client
  if (botToken) {
    botClient = new TelegramClient(new StringSession(''), apiId, apiHash, {
      connectionRetries: 5,
    });
    try {
      await botClient.start({ botAuthToken: botToken });
      console.log('🤖 Main Telegram Bot Connected successfully!');
    } catch (e) {
      console.error('❌ Failed to start Bot Client:', e.message);
    }
  }

  // Listen to live updates on channels
  setupEventListeners();
  
  // Auto-index configured channels on startup
  autoIndexOnStartup();
}
startClients();

// Helper to get active Telegram client (fallback order: UserBot -> Bot)
function getActiveClient() {
  return userClient || botClient;
}

// ==========================================
// 4. METADATA CLEANING & AUTO-INDEX LOGIC
// ==========================================
function cleanTitle(title) {
  if (!title) return "";
  
  // Take first line if multiple lines exist
  if (title.includes('\n')) {
    title = title.split('\n')[0];
  }
  
  // Split on typical promotional banners / colons
  if (title.includes(':')) {
    title = title.split(':')[0];
  }
  if (title.includes('╔')) {
    title = title.split('╔')[0];
  }
  if (title.includes('[')) {
    title = title.split('[')[0];
  }
  if (title.includes('|')) {
    title = title.split('|')[0];
  }
  if (title.includes('-')) {
    // If it's a long promotional dash, split
    const parts = title.split('-');
    if (parts[0].trim().match(/\d{4}/)) { // if first part ends in or contains a year, take it
      title = parts[0];
    }
  }

  // Remove usernames (e.g. @BingeStream)
  title = title.replace(/@\S+/g, '');
  
  // Remove typical Telegram links (e.g. t.me/...)
  title = title.replace(/https?:\/\/t\.me\/\S+/gi, '');
  
  // Remove common movie channel footer ads
  title = title.replace(/Join our channel/gi, '');
  title = title.replace(/Click here to download/gi, '');
  
  // Remove markdown symbols
  title = title.replace(/[_*`[\]()~]/g, '');
  
  // Replace underscores and dots with spaces for clean display
  title = title.replace(/[._]/g, ' ');
  
  // Clean multiple spaces
  title = title.replace(/\s+/g, ' ');
  
  return title.trim();
}

async function fetchMovieMetadata(rawTitle) {
  try {
    // Clean query for search APIs (remove quality, audio tags, and non-alphanumeric/non-ASCII symbols)
    let cleanQuery = rawTitle
      .replace(/\b(1080p|720p|480p|360p|2160p|4k|hd|sd|webrip|web-dl|web|hdtv|bluray|x264|h264|hevc|x265|5\.1|dual|audio|hindi|english|org|multi|dubbed|esub|sub|corrected|season\s*\d+|ep\s*\d+|s\d+e\d+|s\d+|e\d+)\b/gi, '')
      .replace(/[^a-zA-Z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    if (!cleanQuery) return null;

    console.log(`🔍 Querying TMDB API for clean title: "${cleanQuery}"`);
    const tmdbApiKey = '6abcb6bb99fb77f33c37016a28866ed2';
    const tmdbUrl = `https://api.themoviedb.org/3/search/multi?api_key=${tmdbApiKey}&query=${encodeURIComponent(cleanQuery)}&language=en-US`;

    const res = await fetch(tmdbUrl);
    if (res.ok) {
      const searchData = await res.json();
      if (searchData.results && searchData.results.length > 0) {
        // Look for movie/tv type results with poster paths
        const bestMatch = searchData.results.find(r => (r.media_type === 'movie' || r.media_type === 'tv') && r.poster_path);
        const result = bestMatch || searchData.results[0];

        const posterUrl = result.poster_path 
          ? `https://image.tmdb.org/t/p/w500${result.poster_path}` 
          : 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
        
        const backdropUrl = result.backdrop_path
          ? `https://image.tmdb.org/t/p/original${result.backdrop_path}`
          : posterUrl;

        const year = result.release_date 
          ? parseInt(result.release_date.split('-')[0]) 
          : (result.first_air_date ? parseInt(result.first_air_date.split('-')[0]) : 2026);
        
        const rating = result.vote_average ? parseFloat(result.vote_average.toFixed(1)) : 8.5;
        const category = result.media_type === 'tv' ? 'Korean Drama' : 'Trending Movies';

        return {
          title: result.title || result.name || cleanQuery,
          poster_url: posterUrl,
          backdrop_url: backdropUrl,
          description: result.overview || 'An exciting new premium release loaded instantly from Telegram channels.',
          rating: rating,
          year: year,
          category: category
        };
      }
    }
  } catch (err) {
    console.error("⚠️ TMDB API fetch failed:", err.message);
  }

  // 2. Fallback to IMDB Worker API
  try {
    let cleanQuery = rawTitle.replace(/[^a-zA-Z0-9\s]/g, ' ').trim();
    console.log(`🔍 Querying IMDB Worker fallback: "${cleanQuery}"`);
    const imdbUrl = `https://imdbapi.kr562481.workers.dev/?q=${encodeURIComponent(cleanQuery)}`;
    
    const res = await fetch(imdbUrl);
    if (res.ok) {
      const data = await res.json();
      if (data && data.results && data.results.length > 0) {
        const item = data.results[0];
        return {
          title: item.title || cleanQuery,
          poster_url: item.image || 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500',
          backdrop_url: item.image || 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500',
          description: item.description || 'An exciting new premium release loaded instantly from Telegram channels.',
          rating: item.rating ? parseFloat(item.rating) : 8.5,
          year: item.year ? parseInt(item.year) : 2026,
          category: 'Trending Movies'
        };
      }
    }
  } catch (err) {
    console.error("⚠️ IMDB Worker fallback failed:", err.message);
  }

  return null;
}

function parseQuality(fileName) {
  const name = fileName.toLowerCase();
  if (name.includes('4k') || name.includes('2160p')) return '4K UHD';
  if (name.includes('1080p')) return '1080p Full HD';
  if (name.includes('720p')) return '720p HD';
  if (name.includes('480p')) return '480p';
  if (name.includes('360p')) return '360p';
  if (name.includes('bluray')) return 'BluRay HD';
  if (name.includes('webrip') || name.includes('web-dl')) return 'WEB-DL';
  if (name.includes('hdrip')) return 'HDRip';
  return 'HD Quality';
}

function parseLanguage(fileName) {
  const name = fileName.toLowerCase();
  const langs = [];
  if (name.includes('hindi') || name.includes('hin')) langs.push('Hindi');
  if (name.includes('english') || name.includes('eng')) langs.push('English');
  if (name.includes('tamil') || name.includes('tam')) langs.push('Tamil');
  if (name.includes('telugu') || name.includes('tel')) langs.push('Telugu');
  if (name.includes('bengali') || name.includes('ben')) langs.push('Bengali');
  if (name.includes('marathi')) langs.push('Marathi');
  
  if (langs.length > 1) return `Dual [${langs.join('/')}]`;
  if (langs.length === 1) return langs[0];
  if (name.includes('dual') || name.includes('multi')) return 'Dual Audio';
  return 'English';
}

async function processAndIndexMessage(message, channelId) {
  try {
    const messageId = message.id;

    // Check if already indexed to prevent duplicates
    const existQuery = await db.collection('movies')
      .where('telegram_channel_id', '==', String(channelId))
      .where('telegram_message_id', '==', messageId)
      .get();

    if (!existQuery.empty) {
      console.log(`⚠️ File from channel ${channelId} and Message ${messageId} is already indexed.`);
      return;
    }

    // Try to resolve clean file name
    let fileName = cleanTitle(message.message || "");
    if (!fileName && message.media && message.media.document && message.media.document.attributes) {
      const fileAttr = message.media.document.attributes.find(a => a.className === 'DocumentAttributeFilename');
      if (fileAttr) {
        fileName = cleanTitle(fileAttr.fileName);
      }
    }

    if (!fileName) {
      fileName = `Movie_Stream_${messageId}`;
    }

    // Build the streaming link
    const backendUrl = process.env.BACKEND_URL || `http://localhost:${process.env.PORT || 3000}`;
    const streamUrl = `${backendUrl}/stream/${channelId}/${messageId}`;

    // Query TMDB or IMDB fallback metadata!
    const meta = await fetchMovieMetadata(fileName) || {};
    const movieTitle = meta.title || fileName;

    // Parse quality and language tags from original file name
    const parsedQuality = parseQuality(fileName);
    const parsedLanguage = parseLanguage(fileName);
    const newStream = {
      url: streamUrl,
      quality: parsedQuality,
      language: parsedLanguage,
      file_name: fileName,
      telegram_channel_id: String(channelId),
      telegram_message_id: messageId,
      added_at: new Date().toISOString()
    };

    // Grouping Strategy: Check if a movie with the exact same title already exists in Firestore!
    const movieQuery = await db.collection('movies')
      .where('title', '==', movieTitle)
      .get();

    if (!movieQuery.empty) {
      // Grouping: Append new stream quality/language to the existing movie document!
      const movieDoc = movieQuery.docs[0];
      const movieData = movieDoc.data();
      
      let streams = movieData.streams || [];
      
      // Migrate legacy documents that only have a single stream_url field
      if (streams.length === 0 && movieData.stream_url) {
        streams.push({
          url: movieData.stream_url,
          quality: parseQuality(movieData.title || ''),
          language: parseLanguage(movieData.title || ''),
          file_name: movieData.title || 'Source 1',
          telegram_channel_id: movieData.telegram_channel_id || '',
          telegram_message_id: movieData.telegram_message_id || '',
          added_at: new Date().toISOString()
        });
      }

      // Check if this specific stream URL is already registered
      const alreadyHasStream = streams.some(s => s.url === streamUrl);
      if (!alreadyHasStream) {
        streams.push(newStream);
        await movieDoc.ref.update({
          streams: streams,
          // Enrich with best TMDB details if available
          poster_url: meta.poster_url || movieData.poster_url || 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500',
          description: meta.description || movieData.description || '',
          rating: meta.rating || movieData.rating || 8.5,
          year: meta.year || movieData.year || 2026,
          category: meta.category || movieData.category || 'Trending Movies'
        });
        console.log(`✅ Grouped new Stream to existing movie: "${movieTitle}" [Quality: ${parsedQuality}, Language: ${parsedLanguage}]`);
      } else {
        console.log(`⚠️ Stream already present for: "${movieTitle}"`);
      }
    } else {
      // First-time insertion: Store movie document with streams array
      await db.collection('movies').add({
        title: movieTitle,
        category: meta.category || 'Trending Movies',
        poster_url: meta.poster_url || 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500',
        description: meta.description || 'An exciting new premium release loaded instantly from Telegram channels.',
        rating: meta.rating || 8.5,
        year: meta.year || 2026,
        stream_url: streamUrl, // Backwards compatibility for legacy app seeking
        streams: [newStream],
        telegram_channel_id: String(channelId),
        telegram_message_id: messageId,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        is_active: true
      });
      console.log(`✅ Dynamic Index & First Source Hydration: "${movieTitle}" -> Firestore [Quality: ${parsedQuality}, Language: ${parsedLanguage}]`);
    }
  } catch (err) {
    console.error("❌ Error indexing message:", err.message);
  }
}

// 1. Fast Indexing of Channels (Real-Time listener)
function setupEventListeners() {
  const client = getActiveClient();
  if (!client) return;

  client.addEventHandler(async (event) => {
    const message = event.message;
    if (!message) return;

    const channelId = String(message.peerId ? message.peerId.channelId : '');
    if (!channelId) return;

    // Verify if channel is in our configuration
    const defaultChs = '-1002740721681,-1002423454296,-1002185819000,-1002360632501,-1002257290028,-1002719303311,-1002368981263,-1002440315747,-1002903580895';
    const configuredChannels = (process.env.DATABASE_CHANNELS || process.env.DATABASE_CHANNEL || defaultChs).split(',');
    if (!configuredChannels.includes(channelId) && !configuredChannels.includes(`-100${channelId}`)) return;

    if (message.media && (message.media.document || message.media.video)) {
      console.log(`📥 New video uploaded in Telegram channel: ${channelId}`);
      await processAndIndexMessage(message, channelId);
    }
  }, new NewMessage({}));
}

async function autoIndexOnStartup() {
  const defaultChs = '-1002740721681,-1002423454296,-1002185819000,-1002360632501,-1002257290028,-1002719303311,-1002368981263,-1002440315747,-1002903580895';
  const configuredChannels = (process.env.DATABASE_CHANNELS || process.env.DATABASE_CHANNEL || defaultChs).split(',');
  console.log("🔍 Auto-indexing configured channels:", configuredChannels);

  const limit = parseInt(process.env.INITIAL_INDEX_LIMIT || '200');
  console.log(`⚡ Startup index scanning limit is set to: ${limit} posts per channel.`);

  for (const channel of configuredChannels) {
    if (channel.trim()) {
      await indexPastChannelMessages(channel.trim(), limit);
    }
  }
}

async function indexPastChannelMessages(channelId, limit = 200) {
  const client = getActiveClient();
  if (!client) {
    console.warn("⚠️ No active Telegram client connected. Cannot index channel.");
    return;
  }

  console.log(`🚀 Scanning last ${limit} posts in channel: ${channelId}...`);

  try {
    // Resolve channel peer ID
    const entity = await client.getEntity(channelId);
    
    // GramJS getMessages logic
    const history = await client.getMessages(entity, {
      limit: limit,
      filter: new Api.InputMessagesFilterDocument(), // Filter only documents/videos
    });

    console.log(`📊 Found ${history.length} video documents. Processing database index...`);

    let indexedCount = 0;
    for (const msg of history) {
      if (msg.media && (msg.media.document || msg.media.video)) {
        await processAndIndexMessage(msg, channelId);
        indexedCount++;
      }
    }
    console.log(`🏁 Finished scanning. Indexed ${indexedCount} new videos from channel ${channelId}`);
  } catch (error) {
    console.error(`❌ Failed to scan channel ${channelId}:`, error.message);
  }
}

// Root endpoint - Serving a beautiful premium status dashboard
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Infinity TV - Streaming Server Control Center</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          background: #0f0f11;
          color: #ffffff;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
        }
        .container {
          background: rgba(255, 255, 255, 0.03);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 24px;
          padding: 40px;
          text-align: center;
          box-shadow: 0 20px 50px rgba(0,0,0,0.5);
          max-width: 480px;
          width: 90%;
          backdrop-filter: blur(20px);
        }
        .logo {
          font-size: 3rem;
          color: #ff3b30;
          margin-bottom: 20px;
          font-weight: bold;
        }
        h1 {
          font-size: 1.8rem;
          margin: 0 0 10px 0;
          font-weight: 700;
          letter-spacing: -0.5px;
        }
        p {
          color: #8e8e93;
          margin: 0 0 30px 0;
          font-size: 0.95rem;
          line-height: 1.5;
        }
        .badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: rgba(52, 199, 89, 0.1);
          color: #34c759;
          padding: 8px 16px;
          border-radius: 20px;
          font-weight: 600;
          font-size: 0.85rem;
          border: 1px solid rgba(52, 199, 89, 0.2);
          margin-bottom: 30px;
        }
        .details-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 15px;
          border-top: 1px solid rgba(255, 255, 255, 0.08);
          padding-top: 25px;
          text-align: left;
        }
        .detail-item {
          font-size: 0.85rem;
        }
        .detail-label {
          color: #8e8e93;
          margin-bottom: 4px;
        }
        .detail-value {
          font-weight: 600;
          color: #ffffff;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo">∞</div>
        <h1>Infinity TV</h1>
        <p>Premium Telegram Auto-Indexing & Direct Playable Video Streaming Cloud Core Server is Online.</p>
        <div class="badge">
          <span style="font-size: 1.1rem;">●</span> Server Status: Active
        </div>
        <div class="details-grid">
          <div class="detail-item">
            <div class="detail-label">API Version</div>
            <div class="detail-value">v1.5.0</div>
          </div>
          <div class="detail-item">
            <div class="detail-label">Database Connection</div>
            <div class="detail-value">Firestore Connected</div>
          </div>
          <div class="detail-item">
            <div class="detail-label">Auto-Index Engine</div>
            <div class="detail-value">9 Channels Ready</div>
          </div>
          <div class="detail-item">
            <div class="detail-label">Streaming Type</div>
            <div class="detail-value">MP4 Range Seeking</div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Endpoint to fetch the dynamic app configuration (for Play Store cloaking)
app.get('/config', async (req, res) => {
  try {
    const doc = await db.collection('config').doc('app_control').get();
    if (!doc.exists) {
      return res.json({
        is_movie_app_active: false,
        banner_message: 'Welcome to Infinity TV!',
        featured_stream: '',
        is_update_available: false
      });
    }
    res.json(doc.data());
  } catch (error) {
    console.error('❌ Failed to fetch config from Firestore:', error.message);
    res.status(500).json({ error: "Failed to load config" });
  }
});

function getStableId(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  return Math.abs(hash);
}

// Expose Firestore custom catalog to Flutter Mobile App
app.get('/movies', async (req, res) => {
  try {
    const searchQuery = req.query.search || req.query.query || '';
    const categoryQuery = req.query.category || '';

    const snapshot = await db.collection('movies').limit(300).get();
    let list = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      const stableId = getStableId(doc.id);
      
      const title = data.title || doc.id;
      const desc = data.description || 'An exciting new premium release loaded instantly from Telegram channels.';

      // Filter locally for case-insensitive match
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        if (!title.toLowerCase().includes(q) && !desc.toLowerCase().includes(q)) {
          return;
        }
      }
      
      if (categoryQuery) {
        if ((data.category || '').toLowerCase() !== categoryQuery.toLowerCase()) {
          return;
        }
      }

      list.push({
        id: stableId,
        title: title,
        overview: desc,
        poster_path: data.poster_url || '',
        backdrop_path: data.backdrop_url || data.poster_url || '',
        vote_average: parseFloat(data.rating || 8.5),
        release_date: (data.year || 2026).toString(),
        stream_url: data.stream_url || ''
      });
    });
    
    res.json(list);
  } catch (err) {
    console.error('❌ Failed to fetch movies catalog:', err.message);
    res.status(500).json({ error: "Failed to load movies catalog" });
  }
});

// Route to manually trigger indexing of a channel
app.post('/index-channel', async (req, res) => {
  const { channel_id, limit } = req.body;
  if (!channel_id) {
    return res.status(400).json({ error: "channel_id is required" });
  }

  // Run in background
  indexPastChannelMessages(channel_id, limit || 200);

  res.json({
    success: true,
    message: `Indexing started for channel: ${channel_id}. Check server logs for progress.`
  });
});

// ==========================================
// 6. THE STREAMING ENGINE (RANGE REQUESTS)
// ==========================================
app.get('/stream/:channel_id/:message_id', async (req, res) => {
  const { channel_id, message_id } = req.params;
  
  // Try Bot Client first, fallback to User Client
  const client = userClient || botClient;

  if (!client) {
    return res.status(503).send("Streaming service unavailable (Clients not started)");
  }

  try {
    // 1. Resolve peer entity and fetch message
    const entity = await client.getEntity(channel_id);
    const messages = await client.getMessages(entity, { ids: parseInt(message_id) });

    if (!messages || messages.length === 0) {
      return res.status(404).send("File not found on Telegram");
    }

    const message = messages[0];
    if (!message.media || !message.media.document) {
      return res.status(404).send("No document media found in this Telegram message");
    }

    const document = message.media.document;
    const size = parseInt(document.size.toString());

    // 2. Handle HTTP Range Requests (Essential for Video Seek / Fast Play)
    const range = req.headers.range;
    if (!range) {
      return res.status(400).send("Requires Range Header");
    }

    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : Math.min(start + (2 * 1024 * 1024) - 1, size - 1); // 2MB Chunk

    const chunksize = (end - start) + 1;

    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${size}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': 'video/mp4',
    });

    // 3. Download media chunk directly from Telegram servers in real-time
    const buffer = await client.downloadMedia(document, {
      offset: BigInt(start),
      size: BigInt(chunksize),
    });

    res.write(buffer);
    res.end();

  } catch (error) {
    console.error('❌ Stream Error:', error.message);
    if (!res.headersSent) {
      res.status(500).send("Error streaming the requested Telegram file");
    }
  }
});

// ==========================================
// START SERVER
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Premium Telegram Auto-Indexing & Streaming Backend running on port ${PORT}`);
});
