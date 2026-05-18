import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'find_screen.dart';
import 'live_tv_screen.dart';
import 'download_screen.dart';
import 'profile_screen.dart';
import '../api/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _screens = const [
    HomeScreen(),
    FindScreen(),
    LiveTVScreen(),
    DownloadScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F0F),
              border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                    _buildNavItem(1, Icons.movie_creation_rounded, Icons.movie_creation_outlined, 'Find'),
                    _buildNavItem(2, Icons.live_tv_rounded, Icons.live_tv_outlined, 'TV'),
                    _buildNavItem(3, Icons.download_rounded, Icons.file_download_outlined, 'Download'),
                    _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Me'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey(isSelected),
                color: isSelected ? const Color(0xFFF2B04E) : const Color(0xFF666666),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF2B04E) : const Color(0xFF666666),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
