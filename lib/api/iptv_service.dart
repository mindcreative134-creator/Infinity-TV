import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

class IPTVService {
  static const Map<String, String> _categories = {
    'All': 'https://iptv-org.github.io/iptv/countries/in.m3u',
    'News': 'https://iptv-org.github.io/iptv/categories/news.m3u',
    'Sports': 'https://iptv-org.github.io/iptv/categories/sports.m3u',
    'Movies': 'https://iptv-org.github.io/iptv/categories/movies.m3u',
    'Entertainment': 'https://iptv-org.github.io/iptv/categories/entertainment.m3u',
    'Global': 'https://iptv-org.github.io/iptv/index.m3u',
  };

  Future<List<Channel>> fetchChannels({String category = 'All'}) async {
    final url = _categories[category] ?? _categories['All']!;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return _parseM3u(response.body);
    } else {
      throw Exception('Failed to load IPTV playlist');
    }
  }

  static List<String> get categoryNames => _categories.keys.toList();

  List<Channel> _parseM3u(String content) {
    final List<Channel> channels = [];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXTINF')) {
        final infoLine = lines[i];
        if (i + 1 < lines.length && lines[i + 1].startsWith('http')) {
          final streamUrl = lines[i + 1].trim();
          channels.add(Channel.fromM3u(infoLine, streamUrl));
          i++; // Skip the URL line
        }
      }
    }
    // Filter out potential non-working links if needed, or sort them
    return channels;
  }
}
