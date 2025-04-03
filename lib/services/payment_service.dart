import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentService {
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

  // Ödeme işlemini gerçekleştir
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      print('Ödeme isteği hazırlanıyor: $_baseUrl/user/payment/userid/add');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user/payment/userid/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: request.toJsonString(),
      );
      
      print('Ödeme yanıtı: StatusCode=${response.statusCode}');
      
      // Başarılı bir yanıt (genellikle 200 OK veya 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return PaymentResponse.fromJson(data);
      }
      
      // 4xx veya 5xx hata yanıtları
      if (response.statusCode >= 400) {
        // API'nin döndüğü hata mesajını almaya çalış
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
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
      print('Ödeme API hatası: $e');
      // Ağ veya diğer hatalar
      if (e is http.ClientException) {
        return PaymentResponse.error('Ağ hatası: ${e.message}');
      } else {
        return PaymentResponse.error('Ödeme işlemi sırasında hata oluştu: ${e.toString()}');
      }
    }
  }
} 