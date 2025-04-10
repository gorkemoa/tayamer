import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // URL'yi ayrıştırmayı dene
    final uri = Uri.tryParse(widget.url);

    // URL geçerli değilse veya mutlak bir yol değilse işlemi durdur
    if (uri == null || !uri.isAbsolute) { // !uri.hasAbsolutePath yerine !uri.isAbsolute daha genel
       if (mounted) {
        setState(() {
          _errorMessage = "Geçersiz veya göreceli PDF URL'si."; // Çift tırnak kullanıldı
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // PDF'i URL'den indir
      final response = await http.get(uri); // uri değişkeni kullanıldı
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        // Geçici bir dizine kaydet
        final dir = await getTemporaryDirectory();
        // Dosya adını URL'den veya rastgele al
        final fileName = basename(widget.url).isNotEmpty && basename(widget.url).toLowerCase().endsWith('.pdf')
          ? basename(widget.url)
          : '${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
         if (mounted) {
           setState(() {
             _errorMessage = 'PDF indirilemedi (Hata Kodu: ${response.statusCode})';
             _isLoading = false;
           });
         }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Hata mesajını kısaltarak göster
          _errorMessage = 'PDF yüklenirken bir hata oluştu: ${e.toString().substring(0, (e.toString().length > 100 ? 100 : e.toString().length))}...';
          _isLoading = false;
        });
        if (kDebugMode) {
          print('PDF yükleme hatası: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
         iconTheme: const IconThemeData(color: Colors.white),
         titleTextStyle: const TextStyle(
           color: Colors.white,
           fontSize: 20,
           fontWeight: FontWeight.bold,
         ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
               const SizedBox(height: 16),
               ElevatedButton(
                 onPressed: _loadPdf, // Tekrar deneme butonu
                 child: const Text('Tekrar Dene'),
               )
            ],
          ),
        ),
      );
    } else if (_localPath != null) {
      return PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false, // Dikey kaydırma
        autoSpacing: false,
        pageFling: true, // Sayfaları kaydırarak geçme
        pageSnap: true, // Sayfaya yapışma
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH, // Genişlik ve yüksekliğe sığdır
        preventLinkNavigation: false, // PDF içindeki linklere tıklanabilirlik (istenirse true yapılabilir)
        onError: (error) {
           if (mounted) {
             setState(() {
               _errorMessage = 'PDF görüntülenirken hata: $error';
             });
           }
          if (kDebugMode) {
            print(error.toString());
          }
        },
        onPageError: (page, error) {
           if (mounted) {
             setState(() {
               _errorMessage = 'Sayfa $page yüklenirken hata: $error';
             });
           }
          if (kDebugMode) {
            print('$page: ${error.toString()}');
          }
        },
      );
    } else {
       return const Center(child: Text('PDF dosyası yüklenemedi.'));
    }
  }
} 