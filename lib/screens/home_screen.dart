import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/tmdb_service.dart';
import '../models/movie_model.dart';
import 'movie_detail_screen.dart';
import 'search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = TMDBService();
  late Future<List<Movie>> _trending;
  late Future<List<Movie>> _popular;
  late Future<List<Movie>> _topRated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        _trending = _service.fetchTrendingMovies();
        _popular = _service.fetchPopularMovies();
        _topRated = _service.fetchTopRatedMovies();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: RefreshIndicator(
        onRefresh: () async { _service.clearCache(); _load(); },
        color: const Color(0xFFFF3B30),
        backgroundColor: const Color(0xFF1A1A1A),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('🔥 Trending', null),
                  _heroSlider(),
                  _section('🎬 Popular Movies', null),
                  _horizontalList(_popular),
                  _section('⭐ Top Rated', null),
                  _horizontalList(_topRated),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _appBar() => SliverAppBar(
        floating: true,
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Row(children: [
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'INFINITY', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            TextSpan(text: ' TV', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ])),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => showSearch(context: context, delegate: MediaSearchDelegate()),
          ),
        ]),
      );

  Widget _heroSlider() => FutureBuilder<List<Movie>>(
        future: _trending,
        builder: (context, snap) {
          if (!snap.hasData) return _shimmerRect(height: 200);
          final items = snap.data!.take(5).toList();
          if (items.isEmpty) return const SizedBox(height: 200);
          return SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => _heroCard(items[i]),
            ),
          );
        },
      );

  Widget _heroCard(Movie m) => GestureDetector(
        onTap: () => _goDetail(m),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(fit: StackFit.expand, children: [
              m.backdropPath != null
                  ? Image.network('https://image.tmdb.org/t/p/w500${m.backdropPath}', fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A1A)))
                  : Container(color: const Color(0xFF1A1A1A)),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFF3B30), size: 14),
                    const SizedBox(width: 4),
                    Text(m.voteAverage.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text(m.releaseDate.split('-')[0], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _horizontalList(Future<List<Movie>> future) => SizedBox(
        height: 210,
        child: FutureBuilder<List<Movie>>(
          future: future,
          builder: (context, snap) {
            if (!snap.hasData) return _shimmerHorizontal();
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

  Widget _section(String title, VoidCallback? onMore) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Row(children: [
                Text('See all', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 13, fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded, color: Color(0xFFFF3B30), size: 18),
              ]),
            ),
        ]),
      );

  void _goDetail(Movie m) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m)));

  Widget _shimmerRect({double height = 180}) => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2A2A2A),
        child: Container(height: height, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      );

  Widget _shimmerHorizontal() => ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: const Color(0xFF1A1A1A),
          highlightColor: const Color(0xFF2A2A2A),
          child: Container(width: 130, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ),
      );
}

class _MediaCard extends StatelessWidget {
  final Movie media;
  const _MediaCard({required this.media});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: media))),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                media.posterPath != null
                    ? Image.network('https://image.tmdb.org/t/p/w200${media.posterPath}', fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A1A)))
                    : Container(color: const Color(0xFF1A1A1A)),
                Positioned(top: 6, left: 6, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: Text(media.voteAverage.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(media.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(media.releaseDate.split('-')[0], style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
        ]),
      ),
    );
  }
}
