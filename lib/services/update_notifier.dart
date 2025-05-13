import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Güncelleme bildirimi için yardımcı sınıf
class UpdateNotifier {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static const String _lastUpdateCheckKey = 'last_update_check';
  
  // Navigator key ayarlamak için
  static set navigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  
  static Future<bool> _shouldShowUpdateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Son 24 saat içinde gösterilmediyse true döndür
    if (now - lastCheck > 24 * 60 * 60 * 1000) {
      // Son kontrol zamanını güncelle
      await prefs.setInt(_lastUpdateCheckKey, now);
      return true;
    }
    
    return false;
  }
  
  static Future<void> showUpdateMessage(String message, String platform) async {
    // Günlük kontrol yapılıyor
    final shouldShow = await _shouldShowUpdateDialog();
    if (!shouldShow) {
      print('Güncelleme bildirimi son 24 saat içinde gösterildi, tekrar gösterilmiyor.');
      return;
    }
    
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