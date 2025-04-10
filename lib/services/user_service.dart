import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'http_interceptor.dart';
import 'dart:math' as Math;
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
          
          /* Sürüm kontrolü geçici olarak devre dışı bırakıldı
          // Sürüm kontrolü yapılıyor
          final userInfo = data['data']['user'];
          
          // Cihaz platformuna göre güncel sürüm kontrolü
          if (platform == 'ios' && userInfo['iOSVersion'] != null) {
            final currentVersion = packageInfo['version'] ?? '';
            final String latestVersion = userInfo['iOSVersion']?.toString() ?? '';
            
            if (currentVersion.isNotEmpty && latestVersion.isNotEmpty) {
              // Versiyon karşılaştırması (basitleştirilmiş)
              if (_isVersionOlder(currentVersion, latestVersion)) {
                print('Uygulama sürümü eskimiş: $currentVersion < $latestVersion');
                _updateApplicationVersion(platform, latestVersion);
              }
            }
          } 
          else if (platform == 'android' && userInfo['androidVersion'] != null) {
            final currentVersion = packageInfo['version'] ?? '';
            final String latestVersion = userInfo['androidVersion']?.toString() ?? '';
            
            if (currentVersion.isNotEmpty && latestVersion.isNotEmpty) {
              // Versiyon karşılaştırması (basitleştirilmiş)
              if (_isVersionOlder(currentVersion, latestVersion)) {
                print('Uygulama sürümü eskimiş: $currentVersion < $latestVersion');
                _updateApplicationVersion(platform, latestVersion);
              }
            }
          }
          */
          
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
  
  /* Güncelleme fonksiyonları geçici olarak devre dışı bırakıldı
  // Versiyon karşılaştırması (basit karşılaştırma)
  bool _isVersionOlder(String currentVersion, String latestVersion) {
    final current = currentVersion.split('.').map(int.parse).toList();
    final latest = latestVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < Math.min(current.length, latest.length); i++) {
      if (current[i] < latest[i]) return true;
      if (current[i] > latest[i]) return false;
    }
    
    return current.length < latest.length;
  }
  
  // Otomatik güncelleme isteği gönderme
  Future<void> _updateApplicationVersion(String platform, String targetVersion) async {
    try {
      final token = await _apiService.getToken();
      final userId = await _apiService.getUserId();
      
      if (token == null || userId == null) {
        print('Token veya kullanıcı ID bulunamadı, güncelleme yapılamıyor');
        return;
      }
      
      print('Uygulama güncellemesi için istek gönderiliyor...');
      
      // Güncelleme isteği
      final response = await _apiService.post(
        '/update/app-version',
        body: {
          'userToken': token,
          'userId': userId,
          'platform': platform.toLowerCase(),
          'targetVersion': targetVersion
        }
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          print('Uygulama sürümü başarıyla güncellendi: $targetVersion');
        } else {
          print('Güncelleme hatası: ${data['message']}');
          // Başarısız olursa normal güncelleme dialogunu göster
          _showUpdateDialog(platform);
        }
      } else {
        print('Güncelleme API hatası: ${response.statusCode}');
        // Başarısız olursa normal güncelleme dialogunu göster
        _showUpdateDialog(platform);
      }
    } catch (e) {
      print('Güncelleme sırasında hata: $e');
      // Hata durumunda normal güncelleme dialogunu göster
      _showUpdateDialog(platform);
    }
  }
  
  // Güncelleme uyarı diyaloğu göster
  void _showUpdateDialog(String platform) {
    // Uygulama bağlamını kullanarak diyalog göstermek için
    // Burada FlutterToast veya SnackBar kullanılabilir
    // Veya bir global fonksiyon çağrılabilir
    
    final message = platform == 'iOS' 
      ? 'Uygulama sürümünüz güncel değil. Lütfen App Store\'dan güncelleyin.'
      : 'Uygulama sürümünüz güncel değil. Lütfen Google Play\'den güncelleyin.';
      
    // Burada global bir dialog gösterme mekanizması kullanılabilir
    UpdateNotifier.showUpdateMessage(message, platform);
  }
  */
}