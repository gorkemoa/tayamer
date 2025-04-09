import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  bool isLoading = true;
  bool hasError = false;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                hasError = false;
              });
            }
            print('WebView sayfası yükleniyor: $url');
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => isLoading = false);
            }
            print('WebView sayfası yüklendi: $url');
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
                hasError = true;
              });
            }
            print('WebView yükleme hatası: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_isPdfUrl(widget.url) ? _getGoogleViewerUrl(widget.url) : widget.url));
  }

  bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  String _getGoogleViewerUrl(String pdfUrl) {
    // Google PDF Viewer kullanarak PDF'i görüntüle
    return 'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true';
  }

  Future<void> _openInBrowser() async {
    final Uri url = Uri.parse(widget.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3A70),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: _openInBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dosya yüklenirken bir hata oluştu',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openInBrowser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3A70),
                    ),
                    child: const Text('Tarayıcıda Aç'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => controller.reload(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 