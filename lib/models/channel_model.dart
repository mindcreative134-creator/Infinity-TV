class Channel {
  final String name;
  final String logo;
  final String url;
  final String category;
  final String country;

  Channel({
    required this.name,
    required this.logo,
    required this.url,
    required this.category,
    required this.country,
  });

  factory Channel.fromM3u(String line, String url) {
    final nameMatch = RegExp(r'tvg-name="([^"]+)"').firstMatch(line);
    final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
    final groupMatch = RegExp(r'group-title="([^"]+)"').firstMatch(line);

    String channelName = nameMatch?.group(1) ?? '';
    if (channelName.isEmpty) {
      final commaIndex = line.lastIndexOf(',');
      if (commaIndex != -1 && commaIndex < line.length - 1) {
        channelName = line.substring(commaIndex + 1).trim();
      }
    }
    if (channelName.isEmpty) channelName = 'Unknown Channel';

    return Channel(
      name: channelName,
      logo: logoMatch?.group(1) ?? '',
      url: url,
      category: groupMatch?.group(1) ?? 'General',
      country: '', 
    );
  }
}
