import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark OTT Color Palette
  static const Color background = Color(0xFF0A0A0A);
  static const Color cardBg = Color(0xFF151515);
  static const Color accentGold = Color(0xFFF2B04E);
  static const Color accentGoldDark = Color(0xFFD99A3A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color chipBg = Color(0xFF1E1E1E);
  static const Color chipSelected = Color(0xFFF2B04E);

  // Gradients
  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x800A0A0A), Color(0xFF0A0A0A)],
    stops: [0.2, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD000000)],
    stops: [0.4, 1.0],
  );

  static const LinearGradient drawerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2B04E), Color(0xFFD99A3A)],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: accentGold,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accentGold,
      secondary: accentGoldDark,
      surface: cardBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 2,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F0F0F),
      selectedItemColor: accentGold,
      unselectedItemColor: Color(0xFF666666),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: chipBg,
      selectedColor: chipSelected,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: const StadiumBorder(),
    ),
  );
}
