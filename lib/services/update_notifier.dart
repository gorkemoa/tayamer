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
                  UpdateHelper.launchUpdateURL(platform);
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
}

// Store URL'sine yönlendirme sınıfı
class UpdateHelper {
  static Future<void> launchUpdateURL(String platform) async {
    final Uri url = Uri.parse(
      platform.toLowerCase() == 'ios'
          ? 'https://apps.apple.com/tr/app/tayamer/id1668001080'
          : 'https://play.google.com/store/apps/details?id=com.office701.tayamer&hl=tr',
    );

    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        print('$platform için mağaza bağlantısı açılamadı: $url');
      } else {
        print('$platform için mağazaya yönlendirildi.');
      }
    } catch (e) {
      print('Mağaza bağlantısı sırasında hata oluştu: $e');
    }
  }
} 