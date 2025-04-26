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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Loaded: $url');
            // Inject JavaScript to ensure audio continues in background
            _controller.runJavaScript('''
              var videos = document.getElementsByTagName("video");
              for (var i = 0; i < videos.length; i++) {
                videos[i].play();
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('youtube.com') ||
                request.url.contains('googlevideo.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));
  }

  void _searchYouTube(String query) {
    if (query.isNotEmpty) {
      final url =
          'https://m.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}';
      _controller.loadRequest(Uri.parse(url));
    }
  }

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
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}