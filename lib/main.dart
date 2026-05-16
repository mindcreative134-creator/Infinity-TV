import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinity_tv/screens/splash_screen.dart';
import 'package:infinity_tv/utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:infinity_tv/services/remote_config_service.dart';
import 'package:infinity_tv/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar for immersive feel
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp();
    await RemoteConfigService().initialize();
    await AdService.initialize();
  } catch (e) {
    debugPrint("Services initialization error: $e");
  }

  runApp(const InfinityTVApp());
}

class InfinityTVApp extends StatelessWidget {
  const InfinityTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
