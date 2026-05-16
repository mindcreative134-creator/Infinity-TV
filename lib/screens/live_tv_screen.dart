import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/live_tv_service.dart';
import 'video_player_screen.dart';
class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  final _service = LiveTVService();
  TVCategory _selectedCat = TVCategory.all;
  String _searchQuery = '';
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  List<LiveChannel> get _visible {
    final list = _service.getChannelsByCategory(_selectedCat);
    if (_searchQuery.isEmpty) return list;
    return list.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: const Color(0xFFFF3B30),
                decoration: const InputDecoration(
                  hintText: 'Search channels...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text(
                'LIVE TV',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5),
              ),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close Search' : 'Search Channels',
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) { _searchQuery = ''; _searchCtrl.clear(); }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _categoryBar(),
          Expanded(
            child: _visible.isEmpty
                ? _empty()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _visible.length,
                    itemBuilder: (ctx, i) => _ChannelTile(channel: _visible[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar() => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: TVCategory.values.map((cat) {
            final isSelected = _selectedCat == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCat = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.tv_off_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('No channels found', style: TextStyle(color: Colors.grey)),
        ]),
      );
}

class _ChannelTile extends StatelessWidget {
  final LiveChannel channel;
  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          url: channel.streamUrl,
          title: channel.name,
          isLive: true,
        ),
      )),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CachedNetworkImage(
                  imageUrl: channel.logo,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.live_tv_rounded, color: Colors.white24, size: 36),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          channel.name,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
