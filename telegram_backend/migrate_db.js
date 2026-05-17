const admin = require('firebase-admin');
const fetch = require('node-fetch');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

function cleanTitle(title) {
  if (!title) return "";
  
  if (title.includes('\n')) {
    title = title.split('\n')[0];
  }
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
    const parts = title.split('-');
    if (parts[0].trim().match(/\d{4}/)) {
      title = parts[0];
    }
  }

  title = title.replace(/@\S+/g, '');
  title = title.replace(/https?:\/\/t\.me\/\S+/gi, '');
  title = title.replace(/Join our channel/gi, '');
  title = title.replace(/Click here to download/gi, '');
  title = title.replace(/[_*`[\]()~]/g, '');
  title = title.replace(/[._]/g, ' ');
  title = title.replace(/\s+/g, ' ');
  
  return title.trim();
}

async function fetchMovieMetadata(rawTitle) {
  try {
    let cleanQuery = rawTitle
      .replace(/\b(1080p|720p|480p|360p|2160p|4k|hd|sd|webrip|web-dl|web|hdtv|bluray|x264|h264|hevc|x265|5\.1|dual|audio|hindi|english|org|multi|dubbed|esub|sub|corrected|season\s*\d+|ep\s*\d+|s\d+e\d+|s\d+|e\d+)\b/gi, '')
      .replace(/[^a-zA-Z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    if (!cleanQuery) return null;

    const tmdbApiKey = '6abcb6bb99fb77f33c37016a28866ed2';
    const tmdbUrl = `https://api.themoviedb.org/3/search/multi?api_key=${tmdbApiKey}&query=${encodeURIComponent(cleanQuery)}&language=en-US`;

    const res = await fetch(tmdbUrl);
    if (res.ok) {
      const searchData = await res.json();
      if (searchData.results && searchData.results.length > 0) {
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
  return null;
}

async function migrate() {
  console.log("🚀 Starting Firestore Database migration...");
  const moviesRef = db.collection('movies');
  const snapshot = await moviesRef.get();

  console.log(`📊 Found ${snapshot.size} documents in Firestore. Processing...`);

  let updatedCount = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    let needsUpdate = false;
    let updateFields = {};

    // 1. Clean localhost URLs
    let streamUrl = data.stream_url || '';
    if (streamUrl.includes('localhost:') || streamUrl.includes('127.0.0.1:')) {
      streamUrl = streamUrl.replace(/http:\/\/localhost:\d+/g, 'https://infinity-tv-a37n.onrender.com');
      streamUrl = streamUrl.replace(/http:\/\/127\.0\.0\.1:\d+/g, 'https://infinity-tv-a37n.onrender.com');
      updateFields.stream_url = streamUrl;
      needsUpdate = true;
    }

    let streams = data.streams || [];
    let updatedStreams = [];
    let streamsChanged = false;
    for (let stream of streams) {
      if (stream.url && (stream.url.includes('localhost:') || stream.url.includes('127.0.0.1:'))) {
        stream.url = stream.url.replace(/http:\/\/localhost:\d+/g, 'https://infinity-tv-a37n.onrender.com');
        stream.url = stream.url.replace(/http:\/\/127\.0\.0\.1:\d+/g, 'https://infinity-tv-a37n.onrender.com');
        streamsChanged = true;
      }
      updatedStreams.push(stream);
    }
    if (streamsChanged) {
      updateFields.streams = updatedStreams;
      needsUpdate = true;
    }

    // 2. Fetch correct metadata using data.title
    const poster = data.poster_url || '';
    const titleVal = data.title || '';
    if (!poster || poster.includes('unsplash.com') || poster.includes('photo-') || !titleVal || titleVal.includes('Movie_Stream_')) {
      const clean = cleanTitle(titleVal || doc.id);
      if (clean && !clean.includes('Movie_Stream_') && clean.length > 2) {
        console.log(`🔍 Fetching metadata for cleaned title: "${clean}"...`);
        const meta = await fetchMovieMetadata(clean);
        if (meta) {
          updateFields.title = meta.title;
          updateFields.poster_url = meta.poster_url;
          updateFields.backdrop_url = meta.backdrop_url;
          updateFields.description = meta.description;
          updateFields.rating = meta.rating;
          updateFields.year = meta.year;
          updateFields.category = meta.category;
          needsUpdate = true;
          console.log(`   ✅ TMDB Metadata Hydrated: [Title: "${meta.title}", Year: ${meta.year}]`);
        }
      }
    }

    if (needsUpdate) {
      await moviesRef.doc(doc.id).update(updateFields);
      updatedCount++;
    }
  }

  console.log(`🏁 Migration complete! Successfully updated ${updatedCount} Firestore documents.`);
  process.exit(0);
}

migrate().catch(err => {
  console.error("❌ Migration failed:", err);
  process.exit(1);
});
