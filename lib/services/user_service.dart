import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  // API bağlantı adresi
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
      
      // Kullanıcı ID'sini SharedPreferences'dan al
      final userData = prefs.getString('user_data');
      if (userData == null || userData.isEmpty) {
        print('Kullanıcı bilgileri bulunamadı');
        return null;
      }
      
      final userDataMap = jsonDecode(userData);
      final userId = userDataMap['userID'];
      
      if (userId == null) {
        print('Kullanıcı ID bulunamadı');
        return null;
      }
      
      print('Kullanıcı bilgileri isteği gönderiliyor: $_baseUrl/user/id/$userId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user/id/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
          'token': token,
          'userToken': token,  // Bazı API'ler userToken istiyor olabilir
        },
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
      
      if (data is Map<String, dynamic> && 
          data['success'] == true && 
          data['data'] != null && 
          data['data']['user'] != null) {
        
        final user = User.fromJson(data['data']['user']);
        print('Kullanıcı bilgileri başarıyla alındı: ${user.userFullname}');
        
        // İsterseniz burada güncel userToken'ı kaydedebilirsiniz
        if (user.userToken.isNotEmpty) {
          await prefs.setString('user_token', user.userToken);
          print('Kullanıcı token güncellendi');
        }
        
        return user;
      } else {
        print('API yanıtında kullanıcı bilgileri bulunamadı');
        return null;
      }
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return null;
    }
  }
} 