import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('SETTINGS'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: _buildDrawer(user),
          body: user != null ? _buildProfileView(user) : _buildGuestView(),
        );
      },
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Join Infinity TV',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to save your favorites, sync your watch history, and get personalized recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign In / Sign Up', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(User user) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.red.withValues(alpha: 0.1),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.red,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(user.email ?? 'No Email', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Premium Member', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _buildSettingItem(context, Icons.person_outline, 'Edit Profile'),
        _buildSettingItem(context, Icons.favorite_outline, 'My List', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
        }),
        _buildSettingItem(context, Icons.history, 'Watch History'),
        _buildSettingItem(context, Icons.notifications_none, 'Notifications'),
        _buildSettingItem(context, Icons.info_outline, 'About Infinity TV'),
        const Divider(color: Colors.grey),
        _buildSettingItem(context, Icons.logout, 'Logout', color: Colors.red, onTap: () => _authService.signOut()),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      backgroundColor: const Color(0xFF141414),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.red,
              gradient: LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFF83050C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Guest User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login, color: Colors.white),
            title: Text(user != null ? 'Account Settings' : 'Login / Sign In', style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              if (user == null) Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white),
            title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('About Us', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.grey),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _authService.signOut();
              },
            ),
        ],
      ),
    );
  }
}
