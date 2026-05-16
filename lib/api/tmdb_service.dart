import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/movie_model.dart';

class TMDBService {
  static const String _apiKey = '0da8b26f661ce60b48bb5f2876e13c74';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const Duration _timeout = Duration(seconds: 15);

  // Real TMDB poster paths for offline/mock mode
  List<Movie> _getMockMovies() {
    return [
      Movie(id: 550, title: 'Fight Club', overview: 'An insomniac office worker and a soap salesman form an underground fight club.', posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', backdropPath: '/87hTDiay2N2qWyX4Ds7ybXi9h8a.jpg', releaseDate: '1999-10-15', voteAverage: 8.4),
      Movie(id: 238, title: 'The Godfather', overview: 'The aging patriarch of an organized crime dynasty transfers control to his reluctant son.', posterPath: '/3bhkrj58Vtu7enYsLegHnDmni2y.jpg', backdropPath: '/tmU7GeKVybMWFButWEGl2M4GeiP.jpg', releaseDate: '1972-03-24', voteAverage: 8.7),
      Movie(id: 278, title: 'The Shawshank Redemption', overview: 'Two imprisoned men bond over a number of years, finding solace and eventual redemption.', posterPath: '/lyQBXzOQSuE59IsHyhrp0qIiPAz.jpg', backdropPath: '/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg', releaseDate: '1994-09-23', voteAverage: 8.7),
      Movie(id: 155, title: 'The Dark Knight', overview: 'Batman faces the Joker, a terrorist who plunges Gotham into anarchy.', posterPath: '/qJ2tW9e5GJPJf0cHb9HiE0c7B1P.jpg', backdropPath: '/nMK9S69967l97u9vB0L.jpg', releaseDate: '2008-07-18', voteAverage: 9.0),
      Movie(id: 19404, title: 'Dilwale Dulhania Le Jayenge', overview: 'A young man and woman fall in love on a trip through Europe, but the woman\'s father disapproves.', posterPath: '/2CAL2433ZeIihfX1Hb2139CX0pW.jpg', backdropPath: '/l6QEDlJPdJ2dCMOQfIUgxPFGGlH.jpg', releaseDate: '1995-10-20', voteAverage: 8.1),
      Movie(id: 1891, title: 'The Empire Strikes Back', overview: 'After the Rebels are brutally overpowered by the Empire, Luke Skywalker begins Jedi training.', posterPath: '/2l05cFWJacyIsTpsqSgH0wQXe4V.jpg', backdropPath: '/2l05cFWJacyIsTpsqSgH0wQXe4V.jpg', releaseDate: '1980-05-21', voteAverage: 8.7),
      Movie(id: 329, title: 'Jurassic Park', overview: 'During a preview tour, a theme park suffers a major power breakdown that allows its cloned dinosaur exhibits to run amok.', posterPath: '/9i3plLl89DHMz7mahksDaM8RR0N.jpg', backdropPath: '/9i3plLl89DHMz7mahksDaM8RR0N.jpg', releaseDate: '1993-06-11', voteAverage: 7.9),
      Movie(id: 424, title: 'Schindler\'s List', overview: 'In German-occupied Poland during World War II, industrialist Oskar Schindler saves the lives of more than a thousand mostly Polish-Jewish refugees.', posterPath: '/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg', backdropPath: '/loRmRzQXZeqG78TqZEgjHOAQInX.jpg', releaseDate: '1993-12-15', voteAverage: 8.6),
    ];
  }

  List<Movie> _getMockTVShows() {
    return [
      Movie(id: 1396, title: 'Breaking Bad', overview: 'A high school chemistry teacher diagnosed with cancer turns to crime.', posterPath: '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg', backdropPath: '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg', releaseDate: '2008-01-20', voteAverage: 9.5),
      Movie(id: 1399, title: 'Game of Thrones', overview: 'Nine noble families fight for control over the lands of Westeros.', posterPath: '/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg', backdropPath: '/suopoADq0k8YZr4dQXcU6pToj6s.jpg', releaseDate: '2011-04-17', voteAverage: 9.3),
      Movie(id: 60625, title: 'Rick and Morty', overview: 'An animated series that follows the exploits of a super scientist and his not-so-bright grandson.', posterPath: '/cvhNj9eoRBe5SxjCbQTkh05UP5K.jpg', backdropPath: '/4zzB2SYTr8xTKz3cCTfNcYV1PNp.jpg', releaseDate: '2013-12-02', voteAverage: 9.0),
      Movie(id: 66732, title: 'Stranger Things', overview: 'When a young boy disappears, his mother, a police chief and his friends must confront terrifying supernatural forces.', posterPath: '/x2LSRK2Cm7MZhjluni1msVJ3wDh.jpg', backdropPath: '/rcA17r3hfHFRWzlHQCSZckvijcB.jpg', releaseDate: '2016-07-15', voteAverage: 8.7),
    ];
  }

  Future<List<Movie>> fetchTrendingMovies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/trending/all/day?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }

  Future<List<Movie>> fetchPopularMovies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }

  Future<List<Movie>> fetchTopRatedMovies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/movie/top_rated?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }

  Future<List<Movie>> fetchUpcomingMovies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/movie/upcoming?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }

  Future<List<Movie>> fetchNowPlayingMovies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/movie/now_playing?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }

  Future<List<Movie>> fetchTrendingTVShows() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/trending/tv/day?api_key=$_apiKey&language=en-US'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockTVShows();
    } catch (e) {
      return _getMockTVShows();
    }
  }

  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/search/multi?api_key=$_apiKey&language=en-US&query=${Uri.encodeComponent(query)}'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .where((m) => m['media_type'] != 'person')
            .map((m) => Movie.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Category-based movie fetch using TMDB genre IDs
  Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/discover/movie?api_key=$_apiKey&with_genres=$genreId&language=en-US&sort_by=popularity.desc'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List).map((m) => Movie.fromJson(m)).toList();
        if (results.isNotEmpty) return results;
      }
      return _getMockMovies();
    } catch (e) {
      return _getMockMovies();
    }
  }
}
