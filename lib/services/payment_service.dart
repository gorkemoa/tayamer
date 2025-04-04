import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';

class PaymentService {
  // API bağlantı adresi
  final String _baseUrl = 'https://api.tayamer.com/service';
  
  // Basic Authentication bilgileri (gerekirse güncellenir)
  final String _basicAuthUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  final String _basicAuthPassword = 'vRP4rTJAqmjtmkI17I1EVpPH57Edl0';
  
  // Basic Auth header'ı oluşturma
  String _getBasicAuthHeader() {
    final String credentials = '$_basicAuthUsername:$_basicAuthPassword';
    final String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  // Ödeme işlemini gerçekleştir
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    
    try {
      // UserId'yi SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id'); 
      
      if (userId == null) {
        print('UserID bulunamadı');
        return PaymentResponse.error('Kullanıcı kimliği bulunamadı.');
      }

      final apiUrl = '$_baseUrl/user/payment/$userId/add';
      print('Ödeme isteği gönderiliyor: $apiUrl');
      print('Gönderilen istek: ${request.toJsonString()}');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: request.toJsonString(),
      );
      
      print('Ödeme yanıtı alındı: StatusCode=${response.statusCode}');
      
      // Yanıt içeriğini al
      final responseBody = utf8.decode(response.bodyBytes);
      print('Başarılı yanıt içeriği: $responseBody');
      
      // Yanıtın HTML veya PHP hatası içerip içermediğini kontrol et
      if (responseBody.contains('<br />') || responseBody.contains('<b>') || 
          responseBody.contains('Fatal error') || responseBody.contains('Warning')) {
        // Sunucu taraflı hata
        return PaymentResponse.error('Sunucu hatası: Lütfen daha sonra tekrar deneyiniz.');
      }
      
      // JSON formatını kontrol et
      try {
        // Başarılı bir yanıt (genellikle 200 OK veya 201 Created)
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(responseBody);
          return PaymentResponse.fromJson(data);
        }
        
        // 4xx veya 5xx hata yanıtları
        if (response.statusCode >= 400) {
          // API'nin döndüğü hata mesajını almaya çalış
          try {
            final errorData = jsonDecode(responseBody);
            return PaymentResponse.error(
              errorData['message'] ?? 'Ödeme işlemi başarısız: HTTP ${response.statusCode}'
            );
          } catch (e) {
            // JSON ayrıştırma hatası, ham yanıtı kullan
            return PaymentResponse.error('Ödeme işlemi başarısız: HTTP ${response.statusCode}');
          }
        }
        
        // Diğer durum kodları
        return PaymentResponse.error('Beklenmeyen yanıt: HTTP ${response.statusCode}');
      } catch (e) {
        // JSON ayrıştırma hatası
        print('Yanıt JSON formatında değil: $e');
        return PaymentResponse.error('Sunucu yanıtı işlenemedi. Lütfen daha sonra tekrar deneyiniz.');
      }
      
    } catch (e) {
      print('Ödeme API hatası: $e');
      // Ağ veya diğer hatalar
      if (e is http.ClientException) {
        return PaymentResponse.error('Ağ hatası: ${e.message}');
      } else if (e is FormatException) {
        return PaymentResponse.error('Yanıt formatı hatası: Lütfen daha sonra tekrar deneyiniz.');
      } else {
        return PaymentResponse.error('Ödeme işlemi sırasında hata oluştu: ${e.toString()}');
      }
    }
  }
} 