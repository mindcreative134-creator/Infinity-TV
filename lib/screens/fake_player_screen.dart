import 'package:flutter/material.dart';

class FakePlayerScreen extends StatelessWidget {
  const FakePlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Video Player"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Browse your phone gallery to play offline videos.\nNo online streaming supported.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Dummy button
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Gallery...')),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2B04E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
