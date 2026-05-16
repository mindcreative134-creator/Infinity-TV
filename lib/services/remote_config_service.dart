import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _remoteConfig.setDefaults(<String, dynamic>{
      'banner_message': 'Welcome to Infinity TV!',
      'featured_stream': '',
      'is_update_available': false,
    });
    await _remoteConfig.fetchAndActivate();
  }

  String get bannerMessage => _remoteConfig.getString('banner_message');
  String get featuredStream => _remoteConfig.getString('featured_stream');
  bool get isUpdateAvailable => _remoteConfig.getBool('is_update_available');
}
