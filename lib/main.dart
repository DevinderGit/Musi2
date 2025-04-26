import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'package:audio_session/audio_session.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  // Configure audio session for background playback
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions:
        AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    avAudioSessionRouteSharingPolicy:
        AVAudioSessionRouteSharingPolicy.defaultPolicy,
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    androidWillPauseWhenDucked: false,
  ));
  // Activate the audio session
  await session.setActive(true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added named 'key' parameter to fix warning
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Added named 'key' parameter to fix warning
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  String? _currentVideoId;
  YoutubePlayerController? _controller;
  bool _isPlaying = false;
  List<String> _playlist = [];
  Duration? _lastPosition; // Store the last playback position

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _loadPlaylist();
    _loadLastPlaybackState(); // Load last video and position on app start
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

  Future<void> _saveLastPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_video_id', _currentVideoId ?? '');
    await prefs.setInt('last_position', _lastPosition?.inSeconds ?? 0);
  }

  Future<void> _loadLastPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVideoId = prefs.getString('last_video_id') ?? '';
    final lastPosition = prefs.getInt('last_position') ?? 0;
    if (lastVideoId.isNotEmpty) {
      setState(() {
        _currentVideoId = lastVideoId;
        _lastPosition = Duration(seconds: lastPosition);
        playVideo(lastVideoId, initialPosition: _lastPosition);
      });
    }
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

  void playVideo(String videoId, {Duration? initialPosition}) {
    setState(() {
      _currentVideoId = videoId;
      _controller?.dispose();
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideThumbnail: true,
       
          startAt: initialPosition?.inSeconds ?? 0,
        ),
      )..addListener(() {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
            _lastPosition = _controller!.value.position;
          });
        });
    });
    _saveLastPlaybackState();
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
      _saveLastPlaybackState();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state: $state');
    if (state == AppLifecycleState.paused) {
      // App is sent to the background (minimized)
      if (_controller != null && _controller!.value.isPlaying) {
        _controller!.pause();
        Future.delayed(Duration(seconds: 3), () {
          if (_controller != null) {
            _controller!.play();
            print('Resumed playback after 3 seconds');
          }
        });
      }
    } else if (state == AppLifecycleState.detached) {
      // App is terminated
      if (_controller != null && _controller!.value.isPlaying) {
        _controller!.pause();
        _saveLastPlaybackState();
        print('App terminated, saved playback state');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
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
                  height: 200,
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
                      title: Text('Video $videoId'),
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