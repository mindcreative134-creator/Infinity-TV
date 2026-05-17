import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  // ========================================================
  // ⚡ YOUR BACKEND URL (Change this to your local or host URL)
  // ========================================================
  static const String _backendUrl = 'https://infinity-tv-a37n.onrender.com';

  // Core Cloak Switch & Update Toggles
  bool _isMovieAppActive = true;
  bool _isUpdateAvailable = false;

  // App Theme & Branding
  String _appName = 'INFINITY TV';
  String _appTagline = 'Movies  •  TV  •  Live Channels';
  String _primaryColor = '#ff3b30'; // Netflix red by default
  String _bannerMessage = 'Welcome to Infinity TV!';
  String _featuredStream = '';

  // Remote AdMob Settings
  bool _isBannerAdEnabled = true;
  bool _isInterstitialAdEnabled = true;
  String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Google test keys fallback
  String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  Future<void> initialize() async {
    try {
      debugPrint("🚀 Synchronizing Live App Config with Backend...");
      final response = await http.get(Uri.parse('$_backendUrl/config')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Parsing Core configs
        _isMovieAppActive = data['is_movie_app_active'] ?? true;
        _isUpdateAvailable = data['is_update_available'] ?? false;

        // Parsing Branding configs
        _appName = data['app_name'] ?? 'INFINITY TV';
        _appTagline = data['app_tagline'] ?? 'Movies  •  TV  •  Live Channels';
        _primaryColor = data['primary_color'] ?? '#ff3b30';
        _bannerMessage = data['banner_message'] ?? 'Welcome to Infinity TV!';
        _featuredStream = data['featured_stream'] ?? '';

        // Parsing AdMob configs
        _isBannerAdEnabled = data['is_banner_ad_enabled'] ?? true;
        _isInterstitialAdEnabled = data['is_interstitial_ad_enabled'] ?? true;
        _bannerAdUnitId = data['banner_ad_unit_id'] ?? 'ca-app-pub-3940256099942544/6300978111';
        _interstitialAdUnitId = data['interstitial_ad_unit_id'] ?? 'ca-app-pub-3940256099942544/1033173712';
        
        debugPrint("✅ Sync Complete. Cloak Switch is_movie_app_active = $_isMovieAppActive");
      } else {
        debugPrint("⚠️ Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Failed to sync config from backend, using safe defaults: $e");
    }
  }

  // Branding Getters
  String get appName => _appName;
  String get appTagline => _appTagline;
  String get primaryColor => _primaryColor;
  String get bannerMessage => _bannerMessage;
  String get featuredStream => _featuredStream;

  // Control Switches Getters
  bool get isMovieAppActive => _isMovieAppActive;
  bool get isUpdateAvailable => _isUpdateAvailable;

  // AdMob Revenue Getters
  bool get isBannerAdEnabled => _isBannerAdEnabled;
  bool get isInterstitialAdEnabled => _isInterstitialAdEnabled;
  String get bannerAdUnitId => _bannerAdUnitId;
  String get interstitialAdUnitId => _interstitialAdUnitId;
}
