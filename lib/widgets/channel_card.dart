import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel_model.dart';
import '../screens/player_screen.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              url: channel.url,
              title: channel.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: channel.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: channel.logo,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.tv, color: Colors.black, size: 40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
