import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_model.dart';

class FavoritesService {
  static const String _key = 'favorite_movies';

  Future<void> toggleFavorite(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    if (favorites.any((m) => m.id == movie.id)) {
      favorites.removeWhere((m) => m.id == movie.id);
    } else {
      favorites.add(movie);
    }
    
    await prefs.setString(_key, json.encode(favorites.map((m) => {
      'id': m.id,
      'title': m.title,
      'overview': m.overview,
      'poster_path': m.posterPath,
      'vote_average': m.voteAverage,
      'release_date': m.releaseDate,
    }).toList()));
  }

  Future<List<Movie>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    
    final List<dynamic> decoded = json.decode(data);
    return decoded.map((m) => Movie.fromJson(m)).toList();
  }

  Future<bool> isFavorite(int movieId) async {
    final favorites = await getFavorites();
    return favorites.any((m) => m.id == movieId);
  }
}
