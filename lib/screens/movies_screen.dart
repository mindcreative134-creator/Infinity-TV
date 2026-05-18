import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/filmy4uhd_service.dart';
import 'filmy_detail_screen.dart';
import 'search_delegate.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _service = Filmy4uHDService();
  final _scrollCtrl = ScrollController();

  final List<Filmy4uHDMedia> _movies = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300 && !_loading && _hasMore) {
        _fetch();
      }
    });
  }

  Future<void> _fetch() async {
    if (!_hasMore || (_loading && _page > 1)) return;
    setState(() => _loading = true);

    final results = await _service.getMovies(page: _page);
    if (mounted) {
      setState(() {
        _movies.addAll(results);
        _loading = false;
        _hasMore = results.isNotEmpty;
        _page++;
      });
    }
  }

  Future<void> _refresh() async {
    _service.clearCache();
    setState(() { _movies.clear(); _page = 1; _hasMore = true; });
    await _fetch();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text('Movies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => showSearch(context: context, delegate: MediaSearchDelegate()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFF2B04E),
        backgroundColor: const Color(0xFF1A1A1A),
        child: _movies.isEmpty && _loading
            ? _shimmerGrid()
            : _movies.isEmpty
                ? _empty()
                : GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: _movies.length + (_hasMore ? 3 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _movies.length) return _shimmerCard();
                      return _MovieCard(media: _movies[i]);
                    },
                  ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.movie_outlined, color: Colors.white.withValues(alpha: 0.1), size: 80),
          const SizedBox(height: 16),
          const Text('No movies found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _refresh, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2B04E)), child: const Text('Retry')),
        ]),
      );

  Widget _shimmerGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 14,
        ),
        itemCount: 12,
        itemBuilder: (_, _) => _shimmerCard(),
      );

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2A2A2A),
        child: Column(children: [
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 6),
          Container(height: 10, color: Colors.white, margin: const EdgeInsets.symmetric(horizontal: 4)),
        ]),
      );
}

class _MovieCard extends StatelessWidget {
  final Filmy4uHDMedia media;
  const _MovieCard({required this.media});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: media))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(fit: StackFit.expand, children: [
              media.poster.isNotEmpty
                  ? Image.network(media.poster, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A1A)))
                  : Container(color: const Color(0xFF1A1A1A)),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  child: Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 10),
                    const SizedBox(width: 2),
                    Text(media.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(media.rip, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 5),
        Text(media.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${media.releaseYear}', style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
      ]),
    );
  }
}
