import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/policy_type_model.dart';

class PolicyTypeService {
  static const String _baseUrl = 'https://tayamer-mobile.b-cdn.net';
  static const String _policyTypesEndpoint = '/tayamer-policy-types.json';

  // API'den tüm poliçe tiplerini getiren metod
  Future<List<PolicyType>> getPolicyTypes() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_policyTypesEndpoint'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((data) => PolicyType.fromJson(data)).toList();
      } else {
        throw Exception('API yanıtı başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Poliçe tipleri yüklenirken hata oluştu: $e');
    }
  }

  // ID'ye göre belirli bir poliçe tipini getiren metod
  Future<PolicyType> getPolicyTypeById(int typeId) async {
    try {
      final policyTypes = await getPolicyTypes();
      final policyType = policyTypes.firstWhere(
        (type) => type.typeId == typeId,
        orElse: () => throw Exception('$typeId ID\'li poliçe tipi bulunamadı'),
      );
      return policyType;
    } catch (e) {
      throw Exception('Poliçe tipi yüklenirken hata oluştu: $e');
    }
  }

  // QR kod verilerini işleyen metod
  Map<String, String>? processQRCode(String qrData, PolicyType policyType) {
    if (policyType.qrCode == null) return null;

    try {
      // QR koddaki regex pattern'e göre eşleştirme yap
      final RegExp regex = RegExp(policyType.qrCode!.pattern);
      final match = regex.firstMatch(qrData);

      if (match == null) return null;

      // Grupları çıkar
      Map<String, String> extractedData = {};
      policyType.qrCode!.groups.forEach((key, pattern) {
        final groupRegex = RegExp(pattern);
        final groupMatch = groupRegex.firstMatch(qrData);
        if (groupMatch != null) {
          extractedData[key] = groupMatch.group(0)!;
        }
      });

      return extractedData;
    } catch (e) {
      print('QR kodu işlenirken hata oluştu: $e');
      return null;
    }
  }
} 