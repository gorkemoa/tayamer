import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  // API bağlantı adresi - düzeltildi
  final String _baseUrl = 'https://api.tayamer.com/service';
  
  // Basic Authentication bilgileri
  final String _basicAuthUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  final String _basicAuthPassword = 'vRP4rTJAqmjtmkI17I1EVpPH57Edl0';
  
  // Basic Auth header'ı oluşturma
  String _getBasicAuthHeader() {
    final String credentials = '$_basicAuthUsername:$_basicAuthPassword';
    final String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }
  
  // Kullanıcı bilgilerini çekme
  Future<User?> getUserInfo() async {
    try {
      // Token'ı SharedPreferences'dan al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        print('Token bulunamadı, kullanıcı bilgileri alınamıyor');
        return null;
      }
      
      // Kullanıcı ID'sini SharedPreferences'tan al
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        print('Kullanıcı ID bulunamadı, kullanıcı bilgileri alınamıyor');
        return null;
      }
      
      // Token ile istek yap
      print('Kullanıcı bilgileri isteği gönderiliyor: $_baseUrl/user/id/$userId');
      
      // PUT isteği ile userToken gönderiyoruz
      final response = await http.put(
        Uri.parse('$_baseUrl/user/id/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'userToken': token,
        }),
      );
      
      print('API yanıtı: StatusCode=${response.statusCode}');
      print('Yanıt içeriği: ${response.body}');
      
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
        print('API yanıtında kullanıcı bilgileri bulunamadı ve hata döndü');
        return null;
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return null;
    }
  }
} 