import 'package:flutter/material.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: const Center(
        child: Text('No downloads yet.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
