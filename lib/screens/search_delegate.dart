import 'package:flutter/material.dart';
import '../api/filmy4uhd_service.dart';
import 'filmy_detail_screen.dart';

class MediaSearchDelegate extends SearchDelegate<Filmy4uHDMedia?> {
  final _service = Filmy4uHDService();
  String _lastQuery = '';

  @override
  String get searchFieldLabel => 'Search movies, series...';

  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151515),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded, color: Colors.white),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildContent(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_rounded, color: Colors.white12, size: 80),
          SizedBox(height: 16),
          Text('Type to search...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (query != _lastQuery) {
      _lastQuery = query;
    }

    return FutureBuilder<List<Filmy4uHDMedia>>(
      future: _service.search(query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)));
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.movie_filter_rounded, color: Colors.white.withValues(alpha: 0.1), size: 80),
              const SizedBox(height: 16),
              Text('No results for "$query"', style: const TextStyle(color: Colors.grey)),
            ]),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final m = items[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: m.poster.isNotEmpty
                    ? Image.network(m.poster, width: 48, height: 68, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(width: 48, height: 68, color: const Color(0xFF1A1A1A)))
                    : Container(width: 48, height: 68, color: const Color(0xFF1A1A1A), child: const Icon(Icons.movie_outlined, color: Colors.white24)),
              ),
              title: Text(m.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${m.releaseYear} • ${m.isTVShow ? 'TV Series' : 'Movie'} • ${m.rating.toStringAsFixed(1)}⭐',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Icon(m.isTVShow ? Icons.live_tv_rounded : Icons.movie_rounded, color: Colors.white24, size: 18),
              onTap: () {
                close(context, m);
                Navigator.push(context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: m)));
              },
            );
          },
        );
      },
    );
  }
}
