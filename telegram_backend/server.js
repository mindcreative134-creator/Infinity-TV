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
const apiId = parseInt(process.env.API_ID);
const apiHash = process.env.API_HASH;
const botToken = process.env.BOT_TOKEN;
const userSession = process.env.SESSION_STRING || '';

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

    // Upload to Firestore
    await db.collection('movies').add({
      title: fileName,
      category: 'Trending Movies',
      poster_url: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500', // Default high quality placeholder
      stream_url: streamUrl,
      telegram_channel_id: String(channelId),
      telegram_message_id: messageId,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      is_active: true
    });

    console.log(`✅ Automatically Indexed: "${fileName}" -> Firestore`);
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
    const configuredChannels = (process.env.DATABASE_CHANNELS || process.env.DATABASE_CHANNEL || '').split(',');
    if (!configuredChannels.includes(channelId) && !configuredChannels.includes(`-100${channelId}`)) return;

    if (message.media && (message.media.document || message.media.video)) {
      console.log(`📥 New video uploaded in Telegram channel: ${channelId}`);
      await processAndIndexMessage(message, channelId);
    }
  }, new NewMessage({}));
}

async function autoIndexOnStartup() {
  const configuredChannels = (process.env.DATABASE_CHANNELS || process.env.DATABASE_CHANNEL || '').split(',');
  console.log("🔍 Auto-indexing configured channels:", configuredChannels);

  for (const channel of configuredChannels) {
    if (channel.trim()) {
      await indexPastChannelMessages(channel.trim(), 100); // Index last 100 posts
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

// ==========================================
// 5. REST API ENDPOINTS
// ==========================================

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
