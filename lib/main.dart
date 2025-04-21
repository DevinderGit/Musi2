import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  runApp(const MusiApp());
}

class MusiApp extends StatelessWidget {
  const MusiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musi Clone',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  YoutubePlayerController? _ytController;

  void _playVideo(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Musi Clone')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL here',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    _playVideo(_controller.text.trim());
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_ytController != null)
              YoutubePlayer(
                controller: _ytController!,
                showVideoProgressIndicator: true,
              ),
          ],
        ),
      ),
    );
  }
}
