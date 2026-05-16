enum TVCategory {
  all('All'),
  news('News'),
  sports('Sports'),
  entertainment('Entertainment'),
  movies('Movies'),
  music('Music'),
  kids('Kids'),
  religious('Religious');

  final String label;
  const TVCategory(this.label);
}

class LiveChannel {
  final String id;
  final String name;
  final String logo;
  final String streamUrl;
  final TVCategory category;

  const LiveChannel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
    required this.category,
  });
}

class LiveTVService {
  static final LiveTVService _instance = LiveTVService._internal();
  factory LiveTVService() => _instance;
  LiveTVService._internal();

  // ============================================================
  // Real Working M3U8 Streams — sourced from verified providers
  // ============================================================
  static const List<LiveChannel> _channels = [

    // ── NEWS (Public/Legal) ────────────────────────────────────
    LiveChannel(
      id: 'aajtak',
      name: 'Aaj Tak',
      logo: 'https://i.postimg.cc/d1f8N4vM/aaj-tak.png',
      streamUrl: 'https://feeds.intoday.in/aajtak/api/master.m3u8',
      category: TVCategory.news,
    ),
    LiveChannel(
      id: 'ndtvindia',
      name: 'NDTV India',
      logo: 'https://i.postimg.cc/t4G2qf8D/ndtv-india.png',
      streamUrl: 'https://ndtvindiaelemarchana.akamaized.net/hls/live/2003679/ndtvindia/master.m3u8',
      category: TVCategory.news,
    ),

    // ── RELIGIOUS ──────────────────────────────────────────────
    LiveChannel(
      id: 'aastha',
      name: 'Aastha TV',
      logo: 'https://i.postimg.cc/3xwYzVqH/aastha.png',
      streamUrl: 'https://aasthaott.akamaized.net/110923/smil:aasthatv.smil/index.m3u8',
      category: TVCategory.religious,
    ),
    LiveChannel(
      id: 'sanskar_tv',
      name: 'Sanskar TV',
      logo: 'https://i.postimg.cc/gJ0hFqZJ/sanskar.png',
      streamUrl: 'https://d26idhjf0y1p2g.cloudfront.net/out/v1/cd66dd25b9774cb29943bab54bbf3e2f/index.m3u8',
      category: TVCategory.religious,
    ),
  ];

  List<LiveChannel> getAllChannels() => _channels;

  List<LiveChannel> getChannelsByCategory(TVCategory category) {
    if (category == TVCategory.all) return _channels;
    return _channels.where((c) => c.category == category).toList();
  }

  List<LiveChannel> searchChannels(String query) {
    final q = query.toLowerCase();
    return _channels.where((c) => c.name.toLowerCase().contains(q)).toList();
  }
}
