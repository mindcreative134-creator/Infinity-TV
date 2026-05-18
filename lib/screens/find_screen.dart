import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/filmy4uhd_service.dart';
import 'filmy_detail_screen.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final Filmy4uHDService _service = Filmy4uHDService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<Filmy4uHDMedia> _items = [];
  bool _isLoading = true;

  final List<String> _types = ['All', 'Movies', 'TV shows', 'Anime', 'Reality Shows'];
  final List<String> _languages = ['All', 'Hindi', 'Tamil', 'Telugu', 'Bengali', 'Malayalam'];
  final List<String> _countries = ['All', 'India', 'United States', 'Japan', 'South Korea'];
  final List<String> _genres = ['All', 'Action', 'Comedy', 'Mystery', 'Animation', 'Drama', 'Adult'];
  final List<String> _years = ['All', '2026', '2025', '2024', '2023', '2022', '2021'];
  final List<String> _providers = ['All', 'Netflix', 'Hotstar', 'Zee5', 'Amazon', 'MXPLAYER'];
  final List<String> _sorts = ['Default', 'Latest', 'Most viewed', 'Rating', 'Premium'];

  String _selType = 'All';
  String _selLang = 'All';
  String _selCountry = 'All';
  String _selGenre = 'All';
  String _selYear = 'All';
  String _selProvider = 'All';
  String _selSort = 'Default';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getLatestMovies();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFilterRow(List<String> items, String selected, Function(String) onSelect, {bool isGold = false}) {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final isSel = item == selected;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (item == 'Premium') const Icon(Icons.star, color: Color(0xFFF2B04E), size: 14),
                  if (item == 'Premium') const SizedBox(width: 4),
                  Text(
                    item,
                    style: TextStyle(
                      color: isSel ? const Color(0xFFF2B04E) : Colors.grey,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15151A),
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
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterRow(_types, _selType, (v) => setState(() => _selType = v)),
          _buildFilterRow(_languages, _selLang, (v) => setState(() => _selLang = v)),
          _buildFilterRow(_countries, _selCountry, (v) => setState(() => _selCountry = v)),
          _buildFilterRow(_genres, _selGenre, (v) => setState(() => _selGenre = v)),
          _buildFilterRow(_years, _selYear, (v) => setState(() => _selYear = v)),
          _buildFilterRow(_providers, _selProvider, (v) => setState(() => _selProvider = v)),
          _buildFilterRow(_sorts, _selSort, (v) => setState(() => _selSort = v), isGold: true),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF2B04E)))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: item))),
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
                                      imageUrl: item.poster,
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
                                        item.languages.isNotEmpty ? item.languages.first.toUpperCase() : 'HINDI',
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
                                            item.isTVShow ? '${item.totalSeasons ?? 1} season' : 'Movie',
                                            style: const TextStyle(color: Colors.white, fontSize: 9),
                                          ),
                                          const Spacer(),
                                          if (item.rating > 0)
                                            Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
