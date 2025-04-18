import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'http_interceptor.dart';
import 'package:version/version.dart';
import 'update_notifier.dart';

class UserService {
  late ApiService _apiService;
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal();
  
  // ApiService'i başlatma metodu
  void initialize(ApiService apiService) {
    _apiService = apiService;
  }
  
  // Kullanıcı bilgilerini çekme
  Future<User?> getUserInfo() async {
    try {
      // Token'ı SharedPreferences'dan al
      final token = await _apiService.getToken();
      
      if (token == null || token.isEmpty) {
        print('Token bulunamadı, kullanıcı bilgileri alınamıyor');
        return null;
      }
      
      // Kullanıcı ID'sini al
      final userId = await _apiService.getUserId();
      
      if (userId == null) {
        print('Kullanıcı ID bulunamadı, kullanıcı bilgileri alınamıyor');
        return null;
      }
      
      // Token ile istek yap
      print('Kullanıcı bilgileri isteği gönderiliyor: /user/id/$userId');
      
      // Uygulama sürüm ve platform bilgisini al
      final packageInfo = await _apiService.getPackageInfo();
      final platform = _apiService.getPlatform();
      
      // PUT isteği ile userToken, platform ve version gönderiyoruz
      final response = await _apiService.put(
        '/user/id/$userId',
        body: {
          'userToken': token,
          'platform': platform,
          'version': packageInfo['version']
        }
      );
      
      print('API yanıtı: StatusCode=${response.statusCode}');
      print('Yanıt içeriği: ${response.body}');
      
      // 417 hatasını interceptor yakalayacak
      
      if (response.statusCode != 200) {
        print('API hatası: ${response.statusCode}');
        return null;
      }
      
      // Yanıtın JSON formatında olup olmadığını kontrol et
      if (response.body.isEmpty) {
        print('API boş yanıt döndü');
        return null;
      }
      
      final data = jsonDecode(response.body);
      
      // API başarılı yanıt verdiyse kullanıcı verisini dön
      if (data is Map<String, dynamic> && data['error'] == false) {
        // Yeni API yapısı: data.user içinde kullanıcı bilgileri var
        if (data['data'] != null && 
            data['data'] is Map<String, dynamic> && 
            data['data']['user'] != null && 
            data['data']['user'] is Map<String, dynamic>) {
          
          // Kullanıcı verisini data.user'dan al
          final user = User.fromJson(data['data']['user']);
          print('Kullanıcı bilgileri alındı: ${user.userFullname}');
          
          // Sürüm kontrolü yapılıyor
          final userInfo = data['data']['user'];
          
          // Cihaz platformuna göre güncel sürüm kontrolü
          if (platform == 'ios' && userInfo['iOSVersion'] != null) {
            final currentVersion = packageInfo['version'] ?? '';
            final String latestVersion = userInfo['iOSVersion']?.toString() ?? '';
            
            if (currentVersion.isNotEmpty && latestVersion.isNotEmpty) {
              // Version paketi ile versiyon karşılaştırması
              if (isVersionOlder(currentVersion, latestVersion)) {
                print('Uygulama sürümü eskimiş: $currentVersion < $latestVersion');
                showUpdateDialog(platform);
              }
            }
          } 
          else if (platform == 'android' && userInfo['androidVersion'] != null) {
            final currentVersion = packageInfo['version'] ?? '';
            final String latestVersion = userInfo['androidVersion']?.toString() ?? '';
            
            if (currentVersion.isNotEmpty && latestVersion.isNotEmpty) {
              // Version paketi ile versiyon karşılaştırması
              if (isVersionOlder(currentVersion, latestVersion)) {
                print('Uygulama sürümü eskimiş: $currentVersion < $latestVersion');
                showUpdateDialog(platform);
              }
            }
          }
          
          return user;
        } 
        // API yanıtında data.user alanı yoksa null döndür
        else {
          print('API yanıtında beklenen veri yapısı yok. API yanıtı: ${response.body}');
          return null;
        }
      } else {
        print('API yanıtında kullanıcı bilgileri bulunamadı veya hata döndü');
        return null;
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return null;
    }
  }
  
  // Version paketi kullanarak versiyon karşılaştırması
  bool isVersionOlder(String currentVersion, String latestVersion) {
    try {
      // Version paketi daha güvenilir karşılaştırma yapar
      final current = Version.parse(currentVersion);
      final latest = Version.parse(latestVersion);
      
      // currentVersion < latestVersion ise true döner
      return current < latest;
    } catch (e) {
      print('Versiyon karşılaştırma hatası: $e');
      
      // Hata durumunda basit karşılaştırma yöntemi
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();
      
      // İki versiyonu karşılaştır (1.2.3 vs 1.2.4)
      for (int i = 0; i < current.length && i < latest.length; i++) {
        if (current[i] < latest[i]) return true;
        if (current[i] > latest[i]) return false;
      }
      
      // Eğer buraya kadar geldiyse, uzunluk farkına bak
      // Örneğin 1.2 vs 1.2.1
      return current.length < latest.length;
    }
  }
  
  // Güncelleme uyarı diyaloğu göster
  void showUpdateDialog(String platform) {
    final message = platform == 'ios' 
      ? 'Uygulama sürümünüz güncel değil. Lütfen App Store\'dan güncelleyin. Bu zorunlu bir güncellemedir.'
      : 'Uygulama sürümünüz güncel değil. Lütfen Google Play\'den güncelleyin. Bu zorunlu bir güncellemedir.';
      
    // Burada global bir dialog gösterme mekanizması kullanılabilir
    UpdateNotifier.showUpdateMessage(message, platform);
  }
}