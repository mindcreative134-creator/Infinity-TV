import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/filmy4uhd_service.dart';
import 'video_player_screen.dart';

class FilmyDetailScreen extends StatefulWidget {
  final Filmy4uHDMedia media;
  const FilmyDetailScreen({super.key, required this.media});

  @override
  State<FilmyDetailScreen> createState() => _FilmyDetailScreenState();
}

class _FilmyDetailScreenState extends State<FilmyDetailScreen> {
  final _service = Filmy4uHDService();

  Filmy4uHDMedia? _detail;
  List<Filmy4uHDMedia> _similar = [];
  bool _loadingDetail = true;
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadSimilar();
  }

  Future<void> _loadDetail() async {
    final d = await _service.getMediaDetails(widget.media.tmdbId);
    if (mounted) setState(() { _detail = d ?? widget.media; _loadingDetail = false; });

    // Auto-select first available season
    if (mounted && _detail != null && _detail!.isTVShow && _detail!.seasons.isNotEmpty) {
      setState(() => _selectedSeason = _detail!.seasons.first.seasonNumber);
    }
  }

  Future<void> _loadSimilar() async {
    final s = await _service.getSimilar(widget.media.tmdbId, widget.media.mediaType);
    if (mounted) setState(() => _similar = s);
  }

  Future<void> _openTelegram(String tmdbId) async {
    final url = Uri.parse(_service.getTelegramUrl(tmdbId));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open Telegram')));
    }
  }

  void _playFile(FilmyTelegramFile file) {
    final url = _service.getStreamUrl(file.id, file.name);
    Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url, title: '${widget.media.title} • ${file.quality}')));
  }

  Future<void> _downloadFile(FilmyTelegramFile file) async {
    final url = Uri.parse(_service.getStreamUrl(file.id, file.name));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download')));
    }
  }

  Future<void> _playExternal(FilmyTelegramFile file) async {
    final url = _service.getStreamUrl(file.id, file.name);
    final intent = Uri.parse('intent:$url#Intent;package=com.nextplayer.pro;type=video/*;end');
    if (!await launchUrl(intent, mode: LaunchMode.externalApplication)) {
      final store = Uri.parse('https://play.google.com/store/apps/details?id=com.nextplayer.pro');
      await launchUrl(store, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlaybackOptions(FilmyTelegramFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(file.quality, style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(file.name.split('\\n').first, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center, maxLines: 1),
            const SizedBox(height: 24),
            _optionTile(Icons.play_circle_filled_rounded, 'Play In-App', 'Best for stable internet', () {
              Navigator.pop(context);
              _playFile(file);
            }),
            _optionTile(Icons.rocket_launch_rounded, 'Play in Next Player Pro', 'Supports 4K & All Audio Formats', () {
              Navigator.pop(context);
              _playExternal(file);
            }),
            _optionTile(Icons.download_for_offline_rounded, 'Direct Download', 'Save to device storage', () {
              Navigator.pop(context);
              _downloadFile(file);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, String sub, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final media = _detail ?? widget.media;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(media),
          SliverToBoxAdapter(
            child: _loadingDetail
                ? _shimmerInfo()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titleRow(media),
                        const SizedBox(height: 12),
                        _metaRow(media),
                        const SizedBox(height: 16),
                        if (media.genres.isNotEmpty) _genreChips(media),
                        if (media.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _description(media),
                        ],
                        if (media.director.isNotEmpty || media.cast.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _credits(media),
                        ],
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFF1A1A1A)),
                        const SizedBox(height: 12),
                        if (media.isTVShow)
                          _tvSection(media)
                        else
                          _movieSection(media),
                        if (_similar.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _sectionHeader('More Like This'),
                          const SizedBox(height: 12),
                          _similarList(),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(Filmy4uHDMedia media) => SliverAppBar(
        expandedHeight: 260,
        pinned: true,
        backgroundColor: const Color(0xFF0A0A0A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(fit: StackFit.expand, children: [
            media.backdrop.isNotEmpty
                ? Image.network(media.backdrop, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => media.poster.isNotEmpty
                        ? Image.network(media.poster, fit: BoxFit.cover)
                        : Container(color: const Color(0xFF1A1A1A)))
                : Container(color: const Color(0xFF1A1A1A)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0A0A0A)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _titleRow(Filmy4uHDMedia media) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media.poster.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                media.poster, width: 100, height: 150, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(width: 100, height: 150, color: const Color(0xFF1A1A1A)),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              Text(media.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 6),
              if (media.rating > 0) Row(children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text('${media.rating.toStringAsFixed(1)} / 10', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ],
      );

  Widget _metaRow(Filmy4uHDMedia media) => Wrap(spacing: 8, runSpacing: 8, children: [
        _chip(text: '${media.releaseYear}', icon: Icons.calendar_today_rounded),
        _chip(text: media.rip),
        if (media.isTVShow && media.totalSeasons != null)
          _chip(text: '${media.totalSeasons} Seasons', icon: Icons.live_tv_rounded),
        if (!media.isTVShow && media.runtime != null)
          _chip(text: '${media.runtime} min', icon: Icons.timer_rounded),
        ...media.languages.map((l) => _chip(text: l.toUpperCase(), color: const Color(0xFF1A3A5C))),
      ]);

  Widget _chip({required String text, IconData? icon, Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color ?? const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white70, size: 12), const SizedBox(width: 4)],
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _genreChips(Filmy4uHDMedia media) => Wrap(
        spacing: 6, runSpacing: 6,
        children: media.genres.map((g) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFF333333)), borderRadius: BorderRadius.circular(20)),
          child: Text(g, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
        )).toList(),
      );

  Widget _description(Filmy4uHDMedia media) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Overview'),
        const SizedBox(height: 8),
        Text(media.description, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.6)),
      ]);

  Widget _credits(Filmy4uHDMedia media) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (media.director.isNotEmpty) _infoRow('Director', media.director),
        if (media.cast.isNotEmpty) _infoRow('Cast', media.cast.take(5).join(', ')),
      ]);

  Widget _infoRow(String label, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 65, child: Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(child: Text(val, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13))),
        ]),
      );

  Widget _sectionHeader(String title) => Row(children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ]);

  // ======================================================
  // MOVIE SECTION
  // ======================================================
  Widget _movieSection(Filmy4uHDMedia media) {
    if (media.telegram.isEmpty) {
      return Column(children: [
        _sectionHeader('Watch & Download'),
        const SizedBox(height: 12),
        _telegramBtn(media.tmdbId),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Watch & Download'),
      const SizedBox(height: 12),
      ...media.telegram.map((f) => _fileTile(f)),
    ]);
  }

  // ======================================================
  // TV SHOW SECTION
  // ======================================================
  Widget _tvSection(Filmy4uHDMedia media) {
    if (media.seasons.isEmpty) {
      return Column(children: [
        _sectionHeader('Episodes'),
        const SizedBox(height: 12),
        _telegramBtn(media.tmdbId),
      ]);
    }

    final selectedSeasonData = media.seasons.firstWhere(
      (s) => s.seasonNumber == _selectedSeason,
      orElse: () => media.seasons.first,
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Episodes'),
      const SizedBox(height: 12),
      // Season tabs
      SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: media.seasons.length,
          itemBuilder: (_, i) {
            final s = media.seasons[i];
            final isSelected = s.seasonNumber == _selectedSeason;
            return GestureDetector(
              onTap: () => setState(() => _selectedSeason = s.seasonNumber),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF3B30) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Season ${s.seasonNumber}',
                  style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFAAAAAA), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      // Episodes
      if (selectedSeasonData.episodes.isEmpty)
        _telegramBtn(media.tmdbId)
      else
        ...selectedSeasonData.episodes.map((ep) => _episodeTile(ep, media.tmdbId)),
    ]);
  }

  Widget _fileTile(FilmyTelegramFile file) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A2A))),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFFF3B30).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF3B30), size: 26),
          ),
          title: Text(
            file.name.isNotEmpty ? file.name.split('\\n').first : 'Watch Now',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(children: [
            _qualityBadge(file.quality),
            const SizedBox(width: 6),
            if (file.size.isNotEmpty) Text(file.size, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          trailing: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          onTap: () => _showPlaybackOptions(file),
        ),
      );

  Widget _episodeTile(FilmyEpisode ep, String tmdbId) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(12)),
        child: ep.telegram.isEmpty
            ? ListTile(
                leading: const Icon(Icons.telegram, color: Color(0xFF2196F3)),
                title: Text('Episode ${ep.episodeNumber}: ${ep.title}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                trailing: const Text('Telegram', style: TextStyle(color: Color(0xFF2196F3), fontSize: 12)),
                onTap: () => _openTelegram(tmdbId),
              )
            : ExpansionTile(
                iconColor: const Color(0xFFFF3B30),
                collapsedIconColor: Colors.white54,
                title: Text(
                  'Ep ${ep.episodeNumber}: ${ep.title}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                children: ep.telegram.map((f) => ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF3B30), size: 28),
                  title: Text(f.name.split('\\n').first, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [_qualityBadge(f.quality), const SizedBox(width: 6), if (f.size.isNotEmpty) Text(f.size, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                  trailing: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                  onTap: () => _showPlaybackOptions(f),
                )).toList(),
              ),
      );

  Widget _qualityBadge(String quality) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: quality.contains('1080') ? Colors.blue.withValues(alpha: 0.2) : quality.contains('720') ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: quality.contains('1080') ? Colors.blue.withValues(alpha: 0.5) : quality.contains('720') ? Colors.green.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Text(quality, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _telegramBtn(String tmdbId) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _openTelegram(tmdbId),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          icon: const Icon(Icons.telegram, color: Colors.white),
          label: const Text('Get on Telegram', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );

  Widget _shimmerInfo() => Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2A2A2A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 120, color: Colors.white, margin: const EdgeInsets.only(bottom: 16)),
            Container(height: 20, width: 200, color: Colors.white, margin: const EdgeInsets.only(bottom: 10)),
            Container(height: 14, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
            Container(height: 14, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
            Container(height: 14, width: 150, color: Colors.white),
          ]),
        ),
      );

  Widget _similarList() => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _similar.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilmyDetailScreen(media: _similar[i]))),
            child: Container(
              width: 120, margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(fit: StackFit.expand, children: [
                  _similar[i].poster.isNotEmpty
                      ? Image.network(_similar[i].poster, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A1A)))
                      : Container(color: const Color(0xFF1A1A1A)),
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black, Colors.transparent])),
                    child: Text(_similar[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  )),
                ]),
              ),
            ),
          ),
        ),
      );
}
