import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/iptv_service.dart';
import '../models/channel_model.dart';
import 'video_player_screen.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  final _service = IPTVService();
  String _selectedCat = 'All';
  String _selectedLang = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  Future<List<Channel>>? _channelsFuture;
  List<Channel> _allChannels = [];
  Channel? _playingChannel;

  final List<String> _languages = ['All', 'Hindi', 'English', 'Tamil', 'Telugu'];
  
  // Custom category list to match screenshot
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.tv_rounded},
    {'name': 'History', 'icon': Icons.history_rounded},
    {'name': 'Favorite', 'icon': Icons.star_border_rounded},
    {'name': 'Sports', 'icon': Icons.sports_baseball_rounded},
    {'name': 'News', 'icon': Icons.article_outlined},
    {'name': 'Movies', 'icon': Icons.movie_creation_outlined},
    {'name': 'Music', 'icon': Icons.music_note_rounded},
    {'name': 'Entertainment', 'icon': Icons.celebration_outlined},
    {'name': 'Business', 'icon': Icons.business_center_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  void _loadChannels() {
    setState(() {
      _channelsFuture = _service.fetchChannels(category: _selectedCat).then((channels) {
        _allChannels = channels;
        return channels;
      });
    });
  }

  List<Channel> get _visible {
    var list = _allChannels;
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15151A), // Darker background
      appBar: AppBar(
        backgroundColor: const Color(0xFF15151A),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF222228),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFFF2B04E),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              hintText: 'Search Channel',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
      ),
      body: Column(
        children: [
          // Video Player Placeholder / Area
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black,
            child: _playingChannel != null
                ? Stack(
                    children: [
                      Center(
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white.withValues(alpha: 0.8), size: 64),
                      ),
                      Positioned(
                        bottom: 10, left: 10,
                        child: Text('Playing: ${_playingChannel!.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(url: _playingChannel!.url, title: _playingChannel!.name, isLive: true)
                              ));
                            },
                          ),
                        ),
                      )
                    ],
                  )
                : const Center(
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
                  ),
          ),

          // Language Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _languages.length,
              itemBuilder: (ctx, i) {
                final lang = _languages[i];
                final isSelected = _selectedLang == lang;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLang = lang),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF2B04E) : const Color(0xFF222228),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sidebar and Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                Container(
                  width: 110,
                  color: const Color(0xFF1C1C22),
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCat == cat['name'];
                      return InkWell(
                        onTap: () {
                          if (!isSelected) {
                            setState(() => _selectedCat = cat['name'] as String);
                            _loadChannels();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: isSelected ? const Color(0xFFF2B04E) : Colors.transparent, width: 3)),
                            gradient: isSelected ? LinearGradient(colors: [const Color(0xFFF2B04E).withValues(alpha: 0.1), Colors.transparent]) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isSelected && i == 0) ...[
                                    Text('All (${_allChannels.length})', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ] else ...[
                                    Icon(cat['icon'] as IconData, color: isSelected ? const Color(0xFFF2B04E) : Colors.grey, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(cat['name'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 11))),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Channels List
                Expanded(
                  child: FutureBuilder<List<Channel>>(
                    future: _channelsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFF2B04E)));
                      } else if (!snapshot.hasData || _visible.isEmpty) {
                        return const Center(child: Text('No channels found', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _visible.length,
                        itemBuilder: (ctx, i) {
                          final channel = _visible[i];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: channel.logo.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: channel.logo,
                                      width: 40, height: 40, fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => Container(width: 40, height: 40, color: Colors.white12, child: const Icon(Icons.tv, size: 20, color: Colors.white54)),
                                    )
                                  : Container(width: 40, height: 40, color: Colors.white12, child: const Icon(Icons.tv, size: 20, color: Colors.white54)),
                            ),
                            title: Text(channel.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            onTap: () {
                              setState(() => _playingChannel = channel);
                              // Auto-play immediately
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(url: channel.url, title: channel.name, isLive: true)
                              ));
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
