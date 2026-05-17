import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ============================================================
// Data Models
// ============================================================

enum MediaSource {
  filmy4u('https://infinity-tv-a37n.onrender.com', 'Filmy4uHD');

  final String url;
  final String name;
  const MediaSource(this.url, this.name);
}

class FilmyTelegramFile {
  final String id;
  final String name;
  final String quality;
  final String size;

  FilmyTelegramFile({
    required this.id,
    required this.name,
    required this.quality,
    required this.size,
  });

  factory FilmyTelegramFile.fromJson(Map<String, dynamic> json) {
    return FilmyTelegramFile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quality: (json['quality'] ?? 'HD').toString(),
      size: (json['size'] ?? '').toString(),
    );
  }
}

class FilmyEpisode {
  final int episodeNumber;
  final String title;
  final String backdrop;
  final List<FilmyTelegramFile> telegram;

  FilmyEpisode({
    required this.episodeNumber,
    required this.title,
    required this.backdrop,
    required this.telegram,
  });

  factory FilmyEpisode.fromJson(Map<String, dynamic> json) {
    return FilmyEpisode(
      episodeNumber: json['episode_number'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      backdrop: json['episode_backdrop'] ?? '',
      telegram: (json['telegram'] as List? ?? [])
          .map((t) => FilmyTelegramFile.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FilmySeason {
  final int seasonNumber;
  final List<FilmyEpisode> episodes;

  FilmySeason({required this.seasonNumber, required this.episodes});

  factory FilmySeason.fromJson(Map<String, dynamic> json) {
    return FilmySeason(
      seasonNumber: json['season_number'] ?? 1,
      episodes: (json['episodes'] as List? ?? [])
          .map((e) => FilmyEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Filmy4uHDMedia {
  final String tmdbId;
  final String title;
  final String poster;
  final String backdrop;
  final double rating;
  final int releaseYear;
  final String rip;
  final List<String> languages;
  final String description;
  final String mediaType; // 'movie' | 'tv'
  final List<FilmyTelegramFile> telegram; // for movies
  final List<FilmySeason> seasons;        // for tv shows
  final int? totalEpisodes;
  final int? totalSeasons;
  final int? runtime;
  final List<String> genres;
  final String director;
  final List<String> cast;
  final MediaSource source;

  Filmy4uHDMedia({
    required this.tmdbId,
    required this.title,
    required this.poster,
    required this.backdrop,
    required this.rating,
    required this.releaseYear,
    required this.rip,
    required this.languages,
    required this.description,
    required this.mediaType,
    required this.telegram,
    required this.seasons,
    this.totalEpisodes,
    this.totalSeasons,
    this.runtime,
    required this.genres,
    required this.director,
    required this.cast,
    required this.source,
  });

  bool get isTVShow => mediaType == 'tv' || mediaType == 'tvshow';

  factory Filmy4uHDMedia.fromJson(Map<String, dynamic> json, MediaSource source) {
    final rawType = (json['media_type'] ?? json['type'] ?? '').toString().toLowerCase();
    final hasSeasons = json.containsKey('seasons') || json.containsKey('total_seasons') || json.containsKey('episodes');
    final type = (rawType == 'tv' || rawType == 'tvshow' || rawType == 'tv_show' || rawType == 'tvshows' || hasSeasons)
        ? 'tv'
        : 'movie';

    // Parse seasons (sorted by season_number, matching demo repo logic)
    final rawSeasons = json['seasons'] as List? ?? [];
    final seasons = (rawSeasons
        .whereType<Map<String, dynamic>>()
        .map((s) => FilmySeason.fromJson(s))
        .toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber)));

    // Parse movie-level telegram files
    final rawTelegram = json['telegram'] as List? ?? [];
    final telegram = rawTelegram
        .whereType<Map<String, dynamic>>()
        .map((t) => FilmyTelegramFile.fromJson(t))
        .toList();

    return Filmy4uHDMedia(
      tmdbId: (json['tmdb_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Unknown').toString(),
      poster: json['poster'] ?? '',
      backdrop: json['backdrop'] ?? '',
      rating: ((json['rating'] ?? json['vote_average'] ?? 0) as num).toDouble(),
      releaseYear: (json['release_year'] ?? 0) as int,
      rip: (json['rip'] ?? 'HD').toString(),
      languages: List<String>.from(json['languages'] ?? []),
      description: (json['description'] ?? json['overview'] ?? '').toString(),
      mediaType: type,
      telegram: telegram,
      seasons: seasons,
      totalEpisodes: json['total_episodes'] as int?,
      totalSeasons: json['total_seasons'] as int?,
      runtime: json['runtime'] as int?,
      genres: List<String>.from(json['genres'] ?? []),
      director: (json['director'] ?? '').toString(),
      cast: List<String>.from(json['cast'] ?? []),
      source: source,
    );
  }
}

// ============================================================
// Service
// ============================================================

class Filmy4uHDService {
  static final Filmy4uHDService _instance = Filmy4uHDService._internal();
  factory Filmy4uHDService() => _instance;
  Filmy4uHDService._internal();

  final MediaSource _source = MediaSource.filmy4u;
  final Map<String, dynamic> _cache = {};
  static const Duration _timeout = Duration(seconds: 20);

  String get baseUrl => _source.url;

  Future<dynamic> _get(String endpoint, {Map<String, String>? params}) async {
    final cacheKey = '$endpoint${params?.toString() ?? ''}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: params);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      debugPrint('[API ERROR] $endpoint → $e');
    }
    return null;
  }

  Future<List<Filmy4uHDMedia>> getMovies({
    String sortBy = 'updated_on:desc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _get('/api/movies', params: {
      'sort_by': sortBy,
      'page': '$page',
      'page_size': '$pageSize',
    });
    if (data == null) return [];

    final List list = (data is Map)
        ? (data['movies'] ?? data['results'] ?? [])
        : (data is List ? data : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => Filmy4uHDMedia.fromJson(item, _source))
        .toList();
  }

  Future<List<Filmy4uHDMedia>> getTVShows({
    String sortBy = 'updated_on:desc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _get('/api/tvshows', params: {
      'sort_by': sortBy,
      'page': '$page',
      'page_size': '$pageSize',
    });
    if (data == null) return [];

    // ✅ Fix: API often returns 'tvshows' or 'results'
    final List list = (data is Map)
        ? (data['tvshows'] ?? data['tv_shows'] ?? data['results'] ?? [])
        : (data is List ? data : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => Filmy4uHDMedia.fromJson(item, _source))
        .toList();
  }

  Future<List<Filmy4uHDMedia>> getTrending() =>
      getMovies(sortBy: 'rating:desc', pageSize: 10);

  Future<List<Filmy4uHDMedia>> getLatestMovies() =>
      getMovies(sortBy: 'updated_on:desc', pageSize: 20);

  Future<List<Filmy4uHDMedia>> getLatestSeries() =>
      getTVShows(sortBy: 'updated_on:desc', pageSize: 20);

  Future<Filmy4uHDMedia?> getMediaDetails(String tmdbId) async {
    final data = await _get('/api/id/$tmdbId');
    if (data == null || data is! Map<String, dynamic>) return null;
    return Filmy4uHDMedia.fromJson(data, _source);
  }

  Future<List<Filmy4uHDMedia>> search(String query, {int page = 1}) async {
    final data = await _get('/api/search/', params: {
      'query': query,
      'page': '$page',
    });
    if (data == null) return [];

    final List list = (data is Map)
        ? (data['results'] ?? data['movies'] ?? data['tv_shows'] ?? data['tvshows'] ?? [])
        : (data is List ? data : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => Filmy4uHDMedia.fromJson(item, _source))
        .toList();
  }

  Future<List<Filmy4uHDMedia>> getSimilar(String tmdbId, String type) async {
    final data = await _get('/api/similar/', params: {
      'tmdb_id': tmdbId,
      'media_type': type == 'tv' ? 'tvshow' : type,
      'limit': '12',
    });
    if (data == null) return [];

    final List list = (data is Map)
        ? (data['similar_media'] ?? data['results'] ?? [])
        : (data is List ? data : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => Filmy4uHDMedia.fromJson(item, _source))
        .toList();
  }

  void clearCache() => _cache.clear();

  // ✅ Fix: Telegram logic — don't double-prefix 'file_' if ID already has it
  String getTelegramUrl(String id) {
    final String startParam = id.startsWith('file_') ? id : 'file_$id';
    return 'https://t.me/Filmy4uhdbot?start=$startParam';
  }

  String getStreamUrl(String fileId, String fileName) =>
      '$baseUrl/dl/$fileId/${Uri.encodeComponent(fileName)}';
}
