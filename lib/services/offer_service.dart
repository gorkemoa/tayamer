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
      
      print('API isteği hazırlanıyor: $_baseUrl/user/account/$userId/offers');
      print('UserID: $userId, Token: ${token.substring(0, 10)}...');
      
      // ÖNEMLİ: Önce PUT isteği ile token gönderilecek
      print('PUT isteği gönderiliyor...');
      final putResponse = await http.put(
        Uri.parse('$_baseUrl/user/account/$userId/offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'userToken': token,
        }),
      );
      
      print('PUT yanıtı: StatusCode=${putResponse.statusCode}');
      print('PUT yanıt içeriği: ${putResponse.body}');
      
      // PUT yanıtını kontrol et
      if (putResponse.statusCode == 200) {
        final putData = jsonDecode(utf8.decode(putResponse.bodyBytes));
        // PUT yanıtı başarılıysa ve teklif verisi içeriyorsa, buradan dön
        if (putData['success'] == true && putData['data'] != null && putData['data']['offers'] != null) {
            print('Teklifler PUT yanıtından alındı.');
            final offersList = putData['data']['offers'] as List;
            return offersList.map((offerJson) => Offer.fromJson(offerJson)).toList();
        }
         // Eğer PUT yanıtı başarılı ama veri yoksa GET isteğine devam et
         print('PUT yanıtı başarılı ancak teklif verisi içermiyor, GET isteği denenecek.');
      } else if (putResponse.statusCode != 410) {
          // 200 veya 410 dışında bir durum varsa hata fırlat
        throw Exception('Token doğrulama isteği başarısız: ${putResponse.statusCode}');
      }
      
      // PUT isteği 200 değilse veya 200 olup veri içermiyorsa, veya 410 ise GET isteği ile veriler alınacak
      print('GET isteği gönderiliyor...');
      final getResponse = await http.get(
        Uri.parse('$_baseUrl/user/account/$userId/offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
      );
      
      print('GET yanıtı: StatusCode=${getResponse.statusCode}');
      print('GET yanıt içeriği: ${getResponse.body}'); // GET yanıtını logla
      
      // 410 Gone, API için geçerli bir yanıt olabilir, ancak yine de veri kontrolü yapılmalı
      if (getResponse.statusCode == 200 || getResponse.statusCode == 410) {
        final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
        
        // Başarılı yanıt ve veri varlığını kontrol et (Farklı formatları işle)
        if (data['success'] == true && data['data'] != null) {
            List<Offer> offers = [];
            if (data['data']['offers'] != null && data['data']['offers'] is List) {
                final offersList = data['data']['offers'] as List;
                offers = offersList.map((offerJson) => Offer.fromJson(offerJson)).toList();
            } else if (data['data'] is List) { // Doğrudan data listesi gelirse
                offers = (data['data'] as List).map((offerJson) => Offer.fromJson(offerJson)).toList();
            }
             // offers listesi boş değilse döndür
            if (offers.isNotEmpty) return offers;
        }
        // Success true ama data['offers'] direkt root seviyesinde ise (eski kontrol)
        else if (data['success'] == true && data['offers'] != null && data['offers'] is List) {
             return (data['offers'] as List).map((offerJson) => Offer.fromJson(offerJson)).toList();
        }

        // 410 durumunda bile veri yoksa veya success false ise
        if (getResponse.statusCode == 410) {
             print('410 yanıtı alındı ancak geçerli teklif verisi bulunamadı.');
             return []; // Boş liste döndür
        }

        // Başarılı yanıtta (200) veri bulunamadıysa
        throw Exception('API yanıtında teklif verisi bulunamadı (GET)');
      }
      
      // GET isteği başarısız olduysa
      throw Exception('Teklifler alınamadı (GET): ${getResponse.statusCode}');
      
    } catch (e) {
      print('API hatası: $e');
       // Hatayı daha açıklayıcı yap
      if (e is http.ClientException) {
        throw Exception('Ağ hatası: ${e.message}');
      } else {
        throw Exception('Teklifler alınırken hata oluştu: ${e.toString()}');
      }
    }
  }
  
  // Belirli bir teklifi detayları ile getir
  Future<Offer> getOfferDetail(String offerId) async {
    try {
      // Token al
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null) {
        throw Exception('Kullanıcı girişi bulunamadı');
      }
      
      print('API isteği hazırlanıyor: $_baseUrl/user/account/offer/$offerId');
      
      // ÖNEMLİ: Önce PUT isteği ile token gönderilecek
      print('PUT isteği gönderiliyor...');
      final putResponse = await http.put(
        Uri.parse('$_baseUrl/user/account/offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: jsonEncode({
          'userToken': token,
        }),
      );
      
      print('PUT yanıtı: StatusCode=${putResponse.statusCode}');
      print('PUT yanıt içeriği: ${putResponse.body}');
      
      if (putResponse.statusCode != 200 && putResponse.statusCode != 410) {
        throw Exception('Token doğrulama isteği başarısız: ${putResponse.statusCode}');
      }
      
      // Daha sonra GET isteği ile veriler alınacak
      print('GET isteği gönderiliyor...');
      final getResponse = await http.get(
        Uri.parse('$_baseUrl/user/account/offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
      );
      
      print('GET yanıtı: StatusCode=${getResponse.statusCode}');
      
      // 410 Gone, API için geçerli bir yanıt olabilir
      if (getResponse.statusCode == 410) {
        print('410 Gone yanıtı alındı, veri işlenecek');
        print('API 410 yanıt içeriği: ${getResponse.body}');
        
        final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
        
        if (data['success'] == true && data['data'] != null) {
          // Farklı veri formatlarını işle
          if (data['data'] is List && data['data'].isNotEmpty) {
            return Offer.fromJson(data['data'][0]);
          } else if (data['data'] is Map) {
            return Offer.fromJson(data['data']);
          }
        }
      }
      
      if (getResponse.statusCode != 200) {
        throw Exception('Teklif detayı alınamadı: ${getResponse.statusCode}');
      }
      
      final data = jsonDecode(utf8.decode(getResponse.bodyBytes));
      
      if (data['success'] == true && data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
        return Offer.fromJson(data['data'][0]);
      } else if (data['success'] == true && data['data'] != null && data['data'] is Map) {
        return Offer.fromJson(data['data']);
      } else {
        throw Exception('API yanıtında teklif detayı bulunamadı');
      }
    } catch (e) {
      print('API hatası: $e');
      throw Exception('Teklif detayı alınırken hata oluştu: $e');
    }
  }
} 