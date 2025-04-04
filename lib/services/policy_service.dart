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

  // Kullanıcı token'ını al
  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  // Kullanıcı ID'sini al
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  // Poliçeleri getir
  Future<List<Policy>> getPolicies() async {
    try {
      final userToken = await _getUserToken();
      final userId = await _getUserId();
      
      if (userToken == null || userToken.isEmpty || userId == 0) {
        throw Exception('Kullanıcı bilgileri bulunamadı');
      }

      final url = '$_baseUrl/user/account/policy/$userId';
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'userToken': userToken,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> policiesData = data['data'];
          return policiesData.map((json) => Policy.fromJson(json)).toList();
        } else {
          // API başarılı yanıt verdi ancak data boş olabilir
          return [];
        }
      } else {
        throw Exception('Poliçe bilgileri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Poliçe servisi hatası: $e');
      return [];
    }
  }

  // Aktif poliçeleri getir
  Future<List<Policy>> getActivePolicies() async {
    final policies = await getPolicies();
    return policies.where((policy) => policy.isActive).toList();
  }

  // Pasif poliçeleri getir
  Future<List<Policy>> getInactivePolicies() async {
    final policies = await getPolicies();
    return policies.where((policy) => !policy.isActive).toList();
  }
} 