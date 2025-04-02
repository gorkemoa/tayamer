import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // API bağlantı adresi - URL düzeltildi
  final String _baseUrl = 'https://api.tayamer.com/service';
  
  // Basic Authentication bilgileri
  final String _basicAuthUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  final String _basicAuthPassword = 'vRP4rTJAqmjtmkI17I1EVpPH57Edl0';
  
  // Kullanıcı token'ını saklamak için kullanılacak anahtar
  static const String _tokenKey = 'user_token';
  static const String _userDataKey = 'user_data';
  
  // Basic Auth header'ı oluşturma
  String _getBasicAuthHeader() {
    final String credentials = '$_basicAuthUsername:$_basicAuthPassword';
    final String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }
  
  // API'ye giriş yapma
  Future<bool> login(String username, String password) async {
    try {
      print('Gerçek API isteği gönderiliyor: $_baseUrl/auth/login');
      print('Gönderilen veriler: user_name=$username, password=****');
      print('Basic Authentication kullanılıyor');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'user_name': username,
          'password': password,
        }),
      );
      
      print('API yanıtı: StatusCode=${response.statusCode}');
      print('Yanıt içeriği: ${response.body}');
      
      // Başarısız durum kodu kontrolü - özellikle 401 hatası
      if (response.statusCode == 401) {
        print('Kimlik doğrulama hatası: Yanlış kullanıcı adı veya şifre');
        return false;
      }
      
      // Boş yanıt kontrolü
      if (response.body.isEmpty) {
        print('API boş yanıt döndü');
        return false;
      }
      
      // Yanıtın JSON formatında olup olmadığını kontrol et
      if (response.body.trim().startsWith('{') && response.body.trim().endsWith('}')) {
        try {
          final data = jsonDecode(response.body);
          print('Çözümlenen veri: $data');
          
          // API yanıt formatını kontrol et
          if (data is Map<String, dynamic>) {
            // API'nin gerçek yanıt formatı - success: true kontrolü
            if (data['success'] == true) {
              print('API başarılı yanıt döndü: success=true');
              
              // data içindeki token'ı al
              if (data['data'] != null && data['data']['token'] != null) {
                final token = data['data']['token'];
                final userId = data['data']['userID'];
                
                print('Token ve userID bulundu: $token, $userId');
                
                // Token ve kullanıcı bilgilerini kaydet
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_tokenKey, token);
                
                // UserID'yi SharedPreferences'a int olarak kaydet
                await prefs.setInt('user_id', userId is int ? userId : int.parse(userId.toString()));
                
                // UserID'yi kullanıcı bilgisi olarak kaydedelim
                await prefs.setString(_userDataKey, jsonEncode({
                  'userID': userId,
                  'username': username
                }));
                
                return true;
              }
            } else if (data['error'] == false && data['success'] == true) {
              // Alternatif başarılı yanıt formatı
              print('Alternatif başarılı yanıt formatı: error=false, success=true');
              
              if (data['data'] != null && data['data']['token'] != null) {
                final token = data['data']['token'];
                final userId = data['data']['userID'] ?? 0;
                
                print('Token ve userID bulundu: $token, $userId');
                
                // Token ve kullanıcı bilgilerini kaydet
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_tokenKey, token);
                
                // UserID'yi SharedPreferences'a int olarak kaydet
                await prefs.setInt('user_id', userId is int ? userId : int.parse(userId.toString()));
                
                // UserID'yi kullanıcı bilgisi olarak kaydedelim
                await prefs.setString(_userDataKey, jsonEncode({
                  'userID': userId,
                  'username': username
                }));
                
                return true;
              }
            }
          }
          
          print('Token bulunamadı veya başarılı değil: $data');
          return false;
        } catch (e) {
          // JSON ayrıştırma hatası
          print('JSON ayrıştırma hatası: $e');
          return false;
        }
      } else {
        // Yanıt JSON formatında değil
        print('API yanıtı JSON formatında değil, düz metin: ${response.body}');
        return false;
      }
    } catch (e) {
      // Ağ hatası veya diğer hatalar
      print('API isteği hatası: $e');
      return false;
    }
  }
  
  // Kullanıcının giriş durumunu kontrol et
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Token kontrolü: ${token != null ? "Token mevcut" : "Token yok"}');
    return token != null && token.isNotEmpty;
  }
  
  // Kullanıcı çıkış işlemi
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    print('Çıkış yapıldı: Token ve kullanıcı bilgileri silindi');
  }
  
  // Kayıtlı token'ı al
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null && userData.isNotEmpty) {
      return jsonDecode(userData);
    }
    return {};
  }
  
  // Not: Kayıt işlemi kullanılmayacak, ancak ViewModel referansı olduğu için tutuyoruz
  Future<bool> register(String name, String email, String password) async {
    // Bu metot kullanılmayacak
    return false;
  }
} 