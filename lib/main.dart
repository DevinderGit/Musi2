import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Musi Clone')),
        body: const YouTubeWebView(),
      ),
    );
  }
}

class YouTubeWebView extends StatefulWidget {
  const YouTubeWebView({super.key});

  @override
  State<YouTubeWebView> createState() => _YouTubeWebViewState();
}

class _YouTubeWebViewState extends State<YouTubeWebView> {
  InAppWebViewController? _webViewController;
  final TextEditingController _videoIdController = TextEditingController();
  String _currentVideoId = 'b83WrYIVIcY'; // Default video

  void _loadVideo(String videoId) {
    if (videoId.isEmpty) return;
    setState(() {
      _currentVideoId = videoId;
    });
    final html = '''
      <!DOCTYPE html>
      <html>
        <body style="margin:0;background:black;">
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                height: '100%',
                width: '100%',
                videoId: '$videoId',
                playerVars: { 'autoplay': 1, 'controls': 1, 'playsinline': 1, 'enablejsapi': 1 },
                events: {
                  'onReady': function(event) { 
                    console.log('Player ready');
                    event.target.playVideo(); 
                  },
                  'onStateChange': function(event) {
                    console.log('Player state: ' + event.data);
                    if (event.data === YT.PlayerState.PAUSED) {
                      console.log('Paused detected, attempting to resume');
                      event.target.playVideo();
                    }
                    if (event.data === YT.PlayerState.ENDED) {
                      console.log('Video ended');
                    }
                  },
                  'onError': function(event) {
                    console.log('Player error: ' + event.data);
                  }
                }
              });
            }
          </script>
        </body>
      </html>
    ''';
    _webViewController?.loadData(data: html);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideo(_currentVideoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _videoIdController,
            decoration: InputDecoration(
              labelText: 'Enter YouTube Video ID (e.g., b83WrYIVIcY)',
              suffixIcon: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _loadVideo(_videoIdController.text),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _loadVideo,
          ),
        ),
        Expanded(
          child: InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              allowsAirPlayForMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              debugPrint('Started loading: $url');
            },
            onLoadStop: (controller, url) async {
              debugPrint('Finished loading: $url');
              await controller.evaluateJavascript(source: '''
                if (player && typeof player.playVideo === 'function') {
                  console.log('Resuming playback on load stop');
                  player.playVideo();
                }
              ''');
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('Console: ${consoleMessage.message}');
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoIdController.dispose();
    super.dispose();
  }
}