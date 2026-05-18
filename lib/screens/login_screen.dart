import 'package:flutter/material.dart';
import '../api/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) Navigator.pop(context); // Close login screen
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo / Branding
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2B04E).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.movie_rounded, color: Color(0xFFF2B04E), size: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'INFINITY TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Unlimited Entertainment',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Spacer(),
            
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFFF2B04E))
            else ...[
              // Google Sign In Button
              _buildSocialButton(
                onTap: _handleGoogleSignIn,
                icon: 'https://img.icons8.com/color/48/000000/google-logo.png',
                label: 'Continue with Google',
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({required VoidCallback onTap, required String icon, required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(icon, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
