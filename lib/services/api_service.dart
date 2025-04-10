import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'http_interceptor.dart';

class ApiService {
  // API bağlantı adresi
  final String _baseUrl = 'https://api.tayamer.com/service';
  
  // Basic Authentication bilgileri
  final String _basicAuthUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  final String _basicAuthPassword = 'vRP4rTJAqmjtmkI17I1EVpPH57Edl0';
  
  // HTTP Interceptor
  final HttpInterceptor _httpInterceptor;
  
  ApiService(this._httpInterceptor);
  
  // Basic Auth header'ı oluşturma
  String _getBasicAuthHeader() {
    final String credentials = '$_basicAuthUsername:$_basicAuthPassword';
    final String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }
  
  // Token al
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }
  
  // Kullanıcı ID'si al
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
  
  // POST isteği gönder
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? extraHeaders}) async {
    final url = '$_baseUrl$endpoint';
    
    // Temel header'ları oluştur
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _getBasicAuthHeader(),
    };
    
    // Ek header'ları ekle
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    // İstek gönder
    return _httpInterceptor.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
  
  // GET isteği gönder
  Future<http.Response> get(String endpoint, {Map<String, String>? extraHeaders}) async {
    final url = '$_baseUrl$endpoint';
    
    // Temel header'ları oluştur
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _getBasicAuthHeader(),
      'Accept': 'application/json',
    };
    
    // Ek header'ları ekle
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    // İstek gönder
    return _httpInterceptor.get(url, headers: headers);
  }
  
  // PUT isteği gönder
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? extraHeaders}) async {
    final url = '$_baseUrl$endpoint';
    
    // Temel header'ları oluştur
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _getBasicAuthHeader(),
    };
    
    // Ek header'ları ekle
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    // İstek gönder
    return _httpInterceptor.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
  
  // DELETE isteği gönder
  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body, Map<String, String>? extraHeaders}) async {
    final url = '$_baseUrl$endpoint';
    
    // Temel header'ları oluştur
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _getBasicAuthHeader(),
    };
    
    // Ek header'ları ekle
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    
    // İstek gönder
    return _httpInterceptor.delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
  
  // Platform bilgisini al (iOS veya Android)
  String getPlatform() {
    return Platform.isIOS ? 'ios' : 'android';
  }
  // TEKRARDAN BAKILACAK
  // Uygulama sürüm bilgisini al
  Future<Map<String, String>> getPackageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // Varsayılan sürüm bilgisi
    String version = '2.3.4'; // Test için düşürüldü
    // iOS kullanıcıları için güncel sürüm
    if (Platform.isIOS) {
      version = '2.3.4'; // Test için düşürüldü (2.3.7'den)
    } 
    // Android kullanıcıları için güncel sürüm
    else if (Platform.isAndroid) {
      version = '2.3.4'; // Test için düşürüldü (2.3.5'ten)
    }
    
    return {
      'version': version
    };
  }
} 