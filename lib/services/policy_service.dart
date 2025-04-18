import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/policy_model.dart';

class PolicyService {
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
  
  // Kullanıcının poliçelerini çekme
  Future<List<Policy>> getUserPolicies() async {
    try {
      // Token'ı SharedPreferences'dan al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        print('Token bulunamadı, poliçe bilgileri alınamıyor');
        return [];
      }
      
      // Kullanıcı ID'sini SharedPreferences'tan al
      int? userId = prefs.getInt('user_id');
      
      // Eğer user_id anahtarıyla bulunamazsa, user_data içindeki JSON'dan almayı dene
      if (userId == null) {
        final userData = prefs.getString('user_data');
        if (userData != null && userData.isNotEmpty) {
          try {
            final Map<String, dynamic> userDataMap = jsonDecode(userData);
            if (userDataMap.containsKey('userID')) {
              final userIdValue = userDataMap['userID'];
              userId = userIdValue is int ? userIdValue : int.parse(userIdValue.toString());
              
              // Gelecekteki istekler için user_id anahtarıyla kaydedelim
              await prefs.setInt('user_id', userId);
            }
          } catch (e) {
            print('Kullanıcı verisi JSON çözümleme hatası: $e');
          }
        }
      }
      
      if (userId == null) {
        print('Kullanıcı ID bulunamadı, poliçe bilgileri alınamıyor');
        return [];
      }
      
      // Token ile istek yap
      print('Poliçe bilgileri isteği gönderiliyor: $_baseUrl/user/account/$userId/policys');
      
      // PUT isteği ile userToken gönderiyoruz
      final response = await http.put(
        Uri.parse('$_baseUrl/user/account/$userId/policys'),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'userToken': token,
        }),
      );
      
      print('API yanıtı: StatusCode=${response.statusCode}');
      
      if (response.statusCode != 410) {
        print('API hatası: ${response.statusCode}');
        return [];
      }
      
      // Yanıtın JSON formatında olup olmadığını kontrol et
      if (response.body.isEmpty) {
        print('API boş yanıt döndü');
        return [];
      }
      
      final data = jsonDecode(response.body);
      
      // API başarılı yanıt verdiyse poliçe verisini dön
      if (data is Map<String, dynamic> && data['error'] == false) {
        // Yeni API yapısı: data.policys içinde poliçe bilgileri var
        if (data['data'] != null && 
            data['data'] is Map<String, dynamic> && 
            data['data']['policys'] != null) {
          
          // PolicyResponse sınıfını kullanarak verilerimizi dönüştürelim
          final policyResponse = PolicyResponse.fromJson(data);
          return policyResponse.data.policys;
        } 
        // API yanıtında data.policys alanı yoksa boş liste döndür
        else {
          print('API yanıtında beklenen veri yapısı yok');
          return [];
        }
      } else {
        print('API yanıtında poliçe bilgileri bulunamadı veya hata döndü');
        return [];
      }
    } catch (e) {
      print('Poliçe bilgileri alınırken hata: $e');
      return [];
    }
  }

  // Belirli bir poliçenin detaylarını çekme
  Future<Policy?> getPolicyDetail(String policyId) async {
    try {
      // Token'ı SharedPreferences'dan al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null || token.isEmpty) {
        print('Token bulunamadı, poliçe detayı alınamıyor');
        return null;
      }
      
      // Poliçe detayı için istek yap
      print('Poliçe detay bilgileri isteği gönderiliyor: $_baseUrl/user/account/policy/$policyId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user/account/policy/$policyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
      );
      
      print('API yanıtı: StatusCode=${response.statusCode}');
      
      if (response.statusCode != 410) {
        print('API hatası: ${response.statusCode}');
        return null;
      }
      
      // Yanıtın JSON formatında olup olmadığını kontrol et
      if (response.body.isEmpty) {
        print('API boş yanıt döndü');
        return null;
      }
      
      final data = jsonDecode(response.body);
      
      // API başarılı yanıt verdiyse poliçe verisini dön
      if (data is Map<String, dynamic> && data['error'] == false && data['success'] == true) {
        if (data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
          try {
            // İlk poliçeyi al ve null kontrolü yap
            if (data['data'][0] is Map<String, dynamic>) {
              // Burada bir poliçe objesi oluşturmadan önce kritik alanları kontrol edelim
              final policyData = data['data'][0] as Map<String, dynamic>;
              
              // statusColor null kontrolü
              if (policyData['statusColor'] == null) {
                policyData['statusColor'] = '#50cd89'; // Varsayılan değer
              }
              
              return Policy.fromJson(policyData);
            } else {
              print('API yanıtında poliçe verisi geçerli formatta değil');
              return null;
            }
          } catch (e) {
            print('Poliçe verisini işlerken hata: $e');
            return null;
          }
        } else {
          print('API yanıtında poliçe detayı verisi yok');
          return null;
        }
      } else {
        print('API yanıtında hata: ${data['error']}');
        return null;
      }
    } catch (e) {
      print('Poliçe detayı alınırken hata: $e');
      return null;
    }
  }
} 