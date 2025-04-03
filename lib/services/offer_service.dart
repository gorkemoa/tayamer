import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offer_model.dart';

class OfferService {
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

  // Kullanıcının tekliflerini getir
  Future<List<Offer>> getOffers() async {
    try {
      // Token ve user id al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getInt('user_id');
      
      if (token == null || userId == null) {
        throw Exception('Kullanıcı girişi bulunamadı');
      }
      
      // API'ye istek at
      final response = await http.get(
        Uri.parse('$_baseUrl/user/account/userid/offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Teklifler alınamadı: ${response.statusCode}');
      }
      
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (data['success'] == true && data['data'] != null && data['data']['offers'] != null) {
        final offersList = data['data']['offers'] as List;
        return offersList.map((offerJson) => Offer.fromJson(offerJson)).toList();
      } else {
        throw Exception('API yanıtında teklif verisi bulunamadı');
      }
    } catch (e) {
      throw Exception('Teklifler alınırken hata oluştu: $e');
    }
  }
  
  // Belirli bir teklifi detayları ile getir
  Future<Offer> getOfferDetail(String offerId) async {
    try {
      // Token ve user id al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null) {
        throw Exception('Kullanıcı girişi bulunamadı');
      }
      
      // API'ye istek at
      final response = await http.get(
        Uri.parse('$_baseUrl/user/account/offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Teklif detayı alınamadı: ${response.statusCode}');
      }
      
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (data['success'] == true && data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
        return Offer.fromJson(data['data'][0]);
      } else {
        throw Exception('API yanıtında teklif detayı bulunamadı');
      }
    } catch (e) {
      throw Exception('Teklif detayı alınırken hata oluştu: $e');
    }
  }
} 