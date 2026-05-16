import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (user != null) _buildLoggedInView(user) else _buildLoggedOutView(),
                const SizedBox(height: 40),
                _buildMenuSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoggedInView(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          backgroundColor: const Color(0xFFFF3B30),
          child: user.photoURL == null
              ? Text(user.displayName?[0] ?? 'U', style: const TextStyle(fontSize: 32, color: Colors.white))
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? 'Infinity User',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user.email ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _authService.signOut(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }

  Widget _buildLoggedOutView() {
    return Column(
      children: [
        const Icon(Icons.account_circle_outlined, color: Colors.white24, size: 100),
        const SizedBox(height: 16),
        const Text(
          'Join Infinity TV',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: Text(
            'Sign in to sync your watchlist and preferences across devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Sign In / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _menuTile(Icons.history_rounded, 'Watch History'),
        _menuTile(Icons.bookmark_outline_rounded, 'My Watchlist'),
        _menuTile(Icons.settings_outlined, 'Settings'),
        _menuTile(Icons.help_outline_rounded, 'Help & Support'),
        _menuTile(Icons.info_outline_rounded, 'About Infinity TV'),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF3B30)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: () {},
    );
  }
}
