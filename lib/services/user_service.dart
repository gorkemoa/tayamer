import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'http_interceptor.dart';

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
      
      // PUT isteği ile userToken gönderiyoruz
      final response = await _apiService.put(
        '/user/id/$userId',
        body: {
          'userToken': token,
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
}