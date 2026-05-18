import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../api/filmy4uhd_service.dart';
import 'filmy_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = Filmy4uHDService();
  late Future<List<Filmy4uHDMedia>> _trending;
  late Future<List<Filmy4uHDMedia>> _popular;

  final List<String> _tabs = ['Home', 'Shows', 'Movie', 'Anime', 'Shorts'];
  String _selectedTab = 'Home';
  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _languages = [
    {'name': 'Hindi', 'color': const Color(0xFFF2B04E), 'image': 'https://image.tmdb.org/t/p/w200/nJUHX3XL1jMkk8honUZnUmudFb9.jpg'}, // Example image
    {'name': 'Tamil', 'color': const Color(0xFFE5C06A), 'image': 'https://image.tmdb.org/t/p/w200/nJUHX3XL1jMkk8honUZnUmudFb9.jpg'},
    {'name': 'Telugu', 'color': const Color(0xFF4CAF50), 'image': 'https://image.tmdb.org/t/p/w200/nJUHX3XL1jMkk8honUZnUmudFb9.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _trending = _service.getTrending();
        _popular = _service.getLatestMovies();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15151A),
      body: RefreshIndicator(
        onRefresh: () async { _service.clearCache(); _load(); },
        color: const Color(0xFFF2B04E),
        backgroundColor: const Color(0xFF222228),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildHeroSection(),
              _sectionTitle('Explore In Your Language'),
              _buildLanguageCards(),
              _sectionTitle('Lokpriya Filmein Dekhein'),
              _buildHorizontalList(_popular),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 8),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF222228), borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: const Color(0xFFF2B04E),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (ctx, i) {
                final tab = _tabs[i];
                final isSel = tab == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
                  child: Container(
                    margin: const EdgeInsets.only(right: 20),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.grey,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (isSel)
                          Container(margin: const EdgeInsets.only(top: 4), width: 20, height: 2, color: const Color(0xFFF2B04E)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return FutureBuilder<List<Filmy4uHDMedia>>(
      future: _trending,
      builder: (context, snap) {
        if (!snap.hasData) return _shimmerHero();
        final items = snap.data!.toList();
        if (items.isEmpty) return const SizedBox(height: 350);
        final m = items.first; // Top trending

        return SizedBox(
          height: 400,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: m.poster.isNotEmpty ? m.poster : m.backdrop,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black26),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [const Color(0xFF15151A), Colors.transparent],
                    stops: const [0.0, 0.4],
                  ),
                ),
              ),
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _goDetail(m),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2B04E),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                        label: const Text('PLAY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('List', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(width: 3, height: 16, color: const Color(0xFFF2B04E)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageCards() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _languages.length,
        itemBuilder: (ctx, i) {
          final lang = _languages[i];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: lang['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10, top: 0, bottom: 0,
                  child: Opacity(
                    opacity: 0.5,
                    child: CachedNetworkImage(
                      imageUrl: lang['image'] as String,
                      width: 80, fit: BoxFit.cover,
                      errorWidget: (_,__,___) => const SizedBox(),
                    ),
                  ),
                ),
                Positioned(
                  left: 12, bottom: 12,
                  child: Text(
                    lang['name'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(Future<List<Filmy4uHDMedia>> future) {
    return SizedBox(
      height: 190,
      child: FutureBuilder<List<Filmy4uHDMedia>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFF2B04E)));
          if (snap.data!.isEmpty) return const SizedBox();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: snap.data!.length,
            itemBuilder: (_, i) => _MediaCard(media: snap.data![i]),
          );
        },
      ),
    );
  }

  void _goDetail(Filmy4uHDMedia m) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: m)));

  Widget _shimmerHero() => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2A2A2A),
        child: Container(height: 350, color: Colors.white),
      );
}

class _MediaCard extends StatelessWidget {
  final Filmy4uHDMedia media;
  const _MediaCard({required this.media});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: media))),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: media.poster,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.white12),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                      ),
                      child: Text(
                        media.languages.isNotEmpty ? media.languages.first.toUpperCase() : 'MULTILINGUAL',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            media.isTVShow ? '${media.totalSeasons ?? 1} season' : 'Movie',
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                          const Spacer(),
                          if (media.rating > 0)
                            Text(media.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              media.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
