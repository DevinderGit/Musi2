import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Loaded: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error: ${error.description}');
          },
        ),
      );

    // Load IFrame player
    const videoId = 'dQw4w9WgXcQ'; // Replace with dynamic video ID
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
                playerVars: { 'autoplay': 1, 'controls': 1, 'playsinline': 1 },
                events: {
                  'onReady': function(event) { event.target.playVideo(); },
                  'onStateChange': function(event) {
                    if (event.data == YT.PlayerState.ENDED) {
                      // Handle video end (e.g., play next video)
                    }
                  }
                }
              });
            }
          </script>
        </body>
      </html>
    ''';
    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}