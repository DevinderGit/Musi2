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
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search YouTube',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchYouTube(_searchController.text),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _searchYouTube,
          ),
        ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://m.youtube.com')),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false, // Allow auto-play
              useShouldOverrideUrlLoading: true,
              allowsInlineMediaPlayback: true, // Play videos inline (iOS)
              allowsBackForwardNavigationGestures: true, // iOS navigation gestures
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              debugPrint('Started loading: $url');
            },
            onLoadStop: (controller, url) async {
              debugPrint('Finished loading: $url');
              // Ensure video playback continues
              await controller.evaluateJavascript(source: '''
                var videos = document.getElementsByTagName("video");
                for (var i = 0; i < videos.length; i++) {
                  videos[i].play();
                }
              ''');
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('Console: ${consoleMessage.message}');
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              // Allow YouTube and video domains
              if (url.contains('youtube.com') || url.contains('googlevideo.com')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
          ),
        ),
      ],
    );
  }

  void _searchYouTube(String query) {
    if (query.isNotEmpty && _webViewController != null) {
      final url =
          'https://m.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
      _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}