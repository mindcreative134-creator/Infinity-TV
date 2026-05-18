import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../screens/movie_detail_screen.dart';

class BannerSlider extends StatefulWidget {
  final List<Movie> movies;
  const BannerSlider({super.key, required this.movies});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.movies.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox(height: 480);

    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.movies.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              return _BannerSlide(movie: movie);
            },
          ),

          // Page dots indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.movies.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFFF2B04E)
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final Movie movie;
  const _BannerSlide({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image
          movie.backdropPath.isNotEmpty
              ? Image.network(
                  movie.fullBackdropPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackBg(),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _fallbackBg();
                  },
                )
              : movie.posterPath.isNotEmpty
                  ? Image.network(
                      movie.fullPosterPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackBg(),
                    )
                  : _fallbackBg(),

          // Multi-layer gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x000A0A0A),
                  Color(0x660A0A0A),
                  Color(0xFF0A0A0A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xCC0A0A0A), Color(0x000A0A0A)],
              ),
            ),
          ),

          // Content at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2B04E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 16)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Rating + Year
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Text(
                        movie.releaseDate.isNotEmpty ? movie.releaseDate.substring(0, 4) : '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('HD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      _buildPlayBtn(context),
                      const SizedBox(width: 12),
                      _buildMyListBtn(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.movie, color: Color(0xFF2A2A2A), size: 80),
      ),
    );
  }

  Widget _buildPlayBtn(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 20),
      label: const Text('Play', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }

  Widget _buildMyListBtn() {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('My List', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
