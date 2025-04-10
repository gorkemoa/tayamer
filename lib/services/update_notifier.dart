import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Güncelleme bildirimi için yardımcı sınıf
class UpdateNotifier {
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  // Navigator key ayarlamak için
  static set navigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  
  static void showUpdateMessage(String message, String platform) {
    // Ana ekranda gösterilecek mesaj
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Güncelleme Gerekli'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text('Şimdi Güncelle'),
                onPressed: () {
                  // Store'a yönlendirme işlemi yapılabilir
                  Navigator.of(context).pop();
                  _launchUpdateURL(platform);
                },
              ),
              TextButton(
                child: Text('Daha Sonra'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
  
  // Store URL'sine yönlendirme
  static Future<void> _launchUpdateURL(String platform) async {
    final Uri url;
    if (platform == 'iOS') {
      // App Store URL
      url = Uri.parse('https://apps.apple.com/tr/app/tayamer/id1589417390');
    } else {
      // Google Play Store URL
      url = Uri.parse('https://play.google.com/store/apps/details?id=com.fabrikasigorta.tayamer');
    }
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('$platform için mağaza sayfası açılamadı: $url');
    } else {
      print('$platform için mağaza sayfasına yönlendirildi');
    }
  }
} 