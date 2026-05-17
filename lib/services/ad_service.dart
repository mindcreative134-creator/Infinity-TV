import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

class AdService {
  static String get bannerAdUnitId {
    // Check if Ads are disabled globally from the Admin Panel
    if (!RemoteConfigService().isBannerAdEnabled) {
      return '';
    }
    
    // Fetch the remote configured ID
    final remoteId = RemoteConfigService().bannerAdUnitId;
    if (remoteId.isNotEmpty && remoteId.startsWith('ca-app-pub-')) {
      return remoteId;
    }
    
    // Fallback default test ID
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
  }

  static String get interstitialAdUnitId {
    // Check if Interstitial Ads are disabled
    if (!RemoteConfigService().isInterstitialAdEnabled) {
      return '';
    }
    
    // Fetch the remote configured ID
    final remoteId = RemoteConfigService().interstitialAdUnitId;
    if (remoteId.isNotEmpty && remoteId.startsWith('ca-app-pub-')) {
      return remoteId;
    }

    // Fallback default test ID
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd? createBannerAd() {
    final adId = bannerAdUnitId;
    if (adId.isEmpty) return null; // Return null if ads are disabled

    return BannerAd(
      adUnitId: adId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => debugPrint('Ad loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    );
  }
}
