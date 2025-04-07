import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class HttpInterceptor {
  final AuthService _authService = AuthService();
  static final HttpInterceptor _instance = HttpInterceptor._internal();
  GlobalKey<NavigatorState> navigatorKey;

  factory HttpInterceptor({required GlobalKey<NavigatorState> navigatorKey}) {
    _instance.navigatorKey = navigatorKey;
    return _instance;
  }

  HttpInterceptor._internal() : navigatorKey = GlobalKey<NavigatorState>();

  // Yanıtı işle ve hataları kontrol et
  Future<http.Response> processResponse(http.Response response) async {
    try {
      print('HttpInterceptor: İstek yanıtı alındı - URL: ${response.request?.url}, StatusCode: ${response.statusCode}');
      
      if (response.statusCode == 417) {
        print('HttpInterceptor: 417 Expectation Failed hatası alındı. Token geçersiz veya süresi dolmuş.');
        
        // Yanıt içeriğini kontrol et
        try {
          final responseBody = response.body;
          print('HttpInterceptor: 417 Yanıt içeriği: $responseBody');
          
          // JSON parse et
          final data = jsonDecode(responseBody);
          if (data['error_message'] != null) {
            print('HttpInterceptor: Hata mesajı: ${data['error_message']}');
          }
        } catch (e) {
          print('HttpInterceptor: Yanıt içeriği parse edilemedi: $e');
        }
        
        // Kullanıcıyı sistemden çıkar
        print('HttpInterceptor: Kullanıcı logout işlemi başlatılıyor...');
        await _authService.logout();
        print('HttpInterceptor: Kullanıcı logout işlemi tamamlandı.');

        // Login sayfasına yönlendir
        if (navigatorKey.currentState != null) {
          print('HttpInterceptor: Login sayfasına yönlendiriliyor...');
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login', 
            (route) => false
          );
          print('HttpInterceptor: Login sayfasına yönlendirme tamamlandı.');
        } else {
          print('HttpInterceptor: HATA - Navigator state bulunamadı, yönlendirme yapılamıyor!');
        }
      }

      return response;
    } catch (e) {
      print('HttpInterceptor: Hata oluştu: $e');
      return response;
    }
  }

  // HTTP GET isteği
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    print('HttpInterceptor: GET isteği - URL: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    return processResponse(response);
  }

  // HTTP POST isteği
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    print('HttpInterceptor: POST isteği - URL: $url');
    final response = await http.post(
      Uri.parse(url), 
      headers: headers, 
      body: body, 
      encoding: encoding
    );
    return processResponse(response);
  }

  // HTTP PUT isteği
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    print('HttpInterceptor: PUT isteği - URL: $url');
    final response = await http.put(
      Uri.parse(url), 
      headers: headers, 
      body: body, 
      encoding: encoding
    );
    return processResponse(response);
  }

  // HTTP DELETE isteği
  Future<http.Response> delete(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    print('HttpInterceptor: DELETE isteği - URL: $url');
    final response = await http.delete(
      Uri.parse(url), 
      headers: headers, 
      body: body, 
      encoding: encoding
    );
    return processResponse(response);
  }
} 