import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String? _currentVideoId;
  YoutubePlayerController? _controller;
  bool _isPlaying = false;
  List<String> _playlist = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playlist = prefs.getStringList('playlist') ?? [];
    });
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist', _playlist);
  }

  Future<void> searchYouTube(String query) async {
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$youtubeApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body)['items'];
      });
    } else {
      print('Failed to search YouTube');
    }
  }

  void playVideo(String videoId) {
    setState(() {
      _currentVideoId = videoId;
      _controller?.dispose(); // Dispose previous controller
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideThumbnail: true,
        ),
      )..addListener(() {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        });
    });
  }

  void togglePlayPause() {
    if (_controller != null) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  void addToPlaylist(String videoId) async {
    setState(() {
      if (!_playlist.contains(videoId)) {
        _playlist.add(videoId);
        _savePlaylist();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YouTube Music')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search music',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => searchYouTube(_searchController.text),
                    ),
                  ),
                  onSubmitted: searchYouTube,
                ),
              ),
              if (_currentVideoId != null)
                Container(
                  height: 200, // Smaller player for audio focus
                  child: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final video = _searchResults[index];
                    final videoId = video['id']['videoId'];
                    final title = video['snippet']['title'];
                    return ListTile(
                      title: Text(title),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => addToPlaylist(videoId),
                      ),
                      onTap: () => playVideo(videoId),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_currentVideoId != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.grey[200],
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: Text('Now Playing: $_currentVideoId')),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: togglePlayPause,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show playlist
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Playlist'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlist.length,
                  itemBuilder: (context, index) {
                    final videoId = _playlist[index];
                    return ListTile(
                      title: Text('Video $videoId'), // Replace with title if available
                      onTap: () => playVideo(videoId),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.playlist_play),
      ),
    );
  }
}