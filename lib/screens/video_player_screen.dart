import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLive = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  String? _error;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Force landscape for video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() { _error = null; _initializing = true; });
    try {
      // Dispose old controllers if retrying
      await _videoCtrl?.dispose();
      _chewieCtrl?.dispose();

      _videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Referer': 'https://filmy4uhd.com/',
        },
      );

      await _videoCtrl!.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: widget.isLive, // Loop for live TV
        isLive: widget.isLive,
        allowedScreenSleep: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: !widget.isLive, // Don't auto-hide for live
        hideControlsTimer: const Duration(seconds: 4),
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFFF3B30),
          handleColor: const Color(0xFFFF3B30),
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.white.withValues(alpha: 0.3),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFFF3B30),
          handleColor: const Color(0xFFFF3B30),
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          bufferedColor: Colors.white.withValues(alpha: 0.3),
        ),
        placeholder: const _LoadingPlaceholder(),
        errorBuilder: (ctx, msg) => _ErrorWidget(
          message: msg,
          onRetry: _initPlayer,
          onBack: () => Navigator.pop(context),
          isLive: widget.isLive,
          url: widget.url,
        ),
      );

      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Stream unavailable: ${e.toString().split(':').first}';
          _initializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _videoCtrl?.dispose();
    _chewieCtrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _initializing || _error != null
          ? AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (widget.isLive)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Row(children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ],
            )
          : null, // AppBar hidden when player is active (chewie has its own controls)
      body: _initializing
          ? const _LoadingPlaceholder()
          : _error != null
              ? _ErrorWidget(
                  message: _error!,
                  onRetry: _initPlayer,
                  onBack: () => Navigator.pop(context),
                  isLive: widget.isLive,
                  url: widget.url,
                )
              : _chewieCtrl != null
                  ? Chewie(controller: _chewieCtrl!)
                  : const _LoadingPlaceholder(),
    );
  }
}

// ── Loading placeholder ────────────────────────────────────────
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF3B30), strokeWidth: 2),
          SizedBox(height: 20),
          Text('Loading stream...', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Error widget with retry ────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final bool isLive;
  final String url;

  const _ErrorWidget({
    required this.message, 
    required this.onRetry, 
    required this.onBack,
    required this.isLive,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                color: Color(0xFFFF3B30), size: 64),
            const SizedBox(height: 20),
            const Text('Stream Unavailable',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              isLive 
                ? 'This channel may be geo-blocked or temporarily offline.'
                : 'The media file could not be loaded. The server might be busy or the file format is unsupported.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                ),
                if (!isLive)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final videoUrl = url.replaceFirst(RegExp(r'^https?://'), '');
                      final scheme = url.startsWith('https') ? 'https' : 'http';
                      final intentUrl = 'intent://$videoUrl#Intent;action=android.intent.action.VIEW;scheme=$scheme;type=video/*;package=com.nextplayer.pro;S.browser_fallback_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.nextplayer.pro;end';
                      
                      try {
                        final uri = Uri.parse(intentUrl);
                        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
                      } catch (_) {
                        // Fallback if intent fails
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                    label: const Text('Play in Next Player'),
                  ),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
