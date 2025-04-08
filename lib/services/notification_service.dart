import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as local_notifications;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final local_notifications.FlutterLocalNotificationsPlugin _localNotifications = local_notifications.FlutterLocalNotificationsPlugin();

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

  // Bildirimleri getir
  Future<NotificationResponse> getNotifications(String userToken) async {
    try {
      // UserId'yi SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('UserID bulunamadı');
        return NotificationResponse.error('Kullanıcı kimliği bulunamadı.');
      }

      final apiUrl = '$_baseUrl/user/account/$userId/natifications';
      print('Bildirimler isteği gönderiliyor: $apiUrl');
      
      final request = NotificationRequest(userToken: userToken);
      
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: request.toJsonString(),
      );
      
      print('Bildirimler yanıtı alındı: StatusCode=${response.statusCode}');
      
      // Yanıt içeriğini al
      final responseBody = utf8.decode(response.bodyBytes);
      print('Başarılı yanıt içeriği: $responseBody');
      
      // Yanıtın HTML veya PHP hatası içerip içermediğini kontrol et
      if (responseBody.contains('<br />') || responseBody.contains('<b>') || 
          responseBody.contains('Fatal error') || responseBody.contains('Warning')) {
        // Sunucu taraflı hata
        return NotificationResponse.error('Sunucu hatası: Lütfen daha sonra tekrar deneyiniz.');
      }
      
      // JSON formatını kontrol et
      try {
        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          return NotificationResponse.fromJson(data);
        }
        
        if (response.statusCode >= 400) {
          try {
            final errorData = jsonDecode(responseBody);
            return NotificationResponse.error(
              errorData['message'] ?? 'Bildirimler alınamadı: HTTP ${response.statusCode}'
            );
          } catch (e) {
            return NotificationResponse.error('Bildirimler alınamadı: HTTP ${response.statusCode}');
          }
        }
        
        return NotificationResponse.error('Beklenmeyen yanıt: HTTP ${response.statusCode}');
      } catch (e) {
        print('Yanıt JSON formatında değil: $e');
        return NotificationResponse.error('Sunucu yanıtı işlenemedi. Lütfen daha sonra tekrar deneyiniz.');
      }
      
    } catch (e) {
      print('Bildirimler API hatası: $e');
      if (e is http.ClientException) {
        return NotificationResponse.error('Ağ hatası: ${e.message}');
      } else {
        return NotificationResponse.error('Bildirimler alınırken hata oluştu: ${e.toString()}');
      }
    }
  }

  // SMS kodu gönder
  Future<SmsCodeResponse> sendSmsCode(String userToken, int paymentId, String smsCode) async {
    try {
      // UserId'yi SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('UserID bulunamadı');
        return SmsCodeResponse.error('Kullanıcı kimliği bulunamadı.');
      }

      final apiUrl = '$_baseUrl/user/payment/$userId/addSms';
      print('SMS kodu isteği gönderiliyor: $apiUrl');
      
      final request = SmsCodeRequest(
        userToken: userToken,
        paymentId: paymentId,
        smsCode: smsCode,
      );
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _getBasicAuthHeader(),
        },
        body: request.toJsonString(),
      );
      
      print('SMS kodu yanıtı alındı: StatusCode=${response.statusCode}');
      
      // Yanıt içeriğini al
      final responseBody = utf8.decode(response.bodyBytes);
      print('Başarılı yanıt içeriği: $responseBody');
      
      // Yanıtın HTML veya PHP hatası içerip içermediğini kontrol et
      if (responseBody.contains('<br />') || responseBody.contains('<b>') || 
          responseBody.contains('Fatal error') || responseBody.contains('Warning')) {
        // Sunucu taraflı hata
        return SmsCodeResponse.error('Sunucu hatası: Lütfen daha sonra tekrar deneyiniz.');
      }
      
      // JSON formatını kontrol et
      try {
        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          return SmsCodeResponse.fromJson(data);
        }
        
        if (response.statusCode >= 400) {
          try {
            final errorData = jsonDecode(responseBody);
            return SmsCodeResponse.error(
              errorData['message'] ?? 'SMS kodu doğrulanamadı: HTTP ${response.statusCode}'
            );
          } catch (e) {
            return SmsCodeResponse.error('SMS kodu doğrulanamadı: HTTP ${response.statusCode}');
          }
        }
        
        return SmsCodeResponse.error('Beklenmeyen yanıt: HTTP ${response.statusCode}');
      } catch (e) {
        print('Yanıt JSON formatında değil: $e');
        return SmsCodeResponse.error('Sunucu yanıtı işlenemedi. Lütfen daha sonra tekrar deneyiniz.');
      }
      
    } catch (e) {
      print('SMS kodu API hatası: $e');
      if (e is http.ClientException) {
        return SmsCodeResponse.error('Ağ hatası: ${e.message}');
      } else {
        return SmsCodeResponse.error('SMS kodu gönderilirken hata oluştu: ${e.toString()}');
      }
    }
  }

  Future<void> initialize() async {
    // Firebase izinlerini iste
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token'ı al
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Yerel bildirimleri yapılandır
    const local_notifications.AndroidInitializationSettings initializationSettingsAndroid =
        local_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const local_notifications.DarwinInitializationSettings initializationSettingsIOS =
        local_notifications.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const local_notifications.InitializationSettings initializationSettings = local_notifications.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Ön planda bildirim gösterme ayarları
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Arka planda bildirim tıklama işlemi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Bildirime tıklandığında yapılacak işlemler
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        local_notifications.NotificationDetails(
          android: local_notifications.AndroidNotificationDetails(
            'high_importance_channel',
            'Yüksek Öncelikli Bildirimler',
            importance: local_notifications.Importance.max,
            priority: local_notifications.Priority.high,
            icon: android.smallIcon,
          ),
          iOS: const local_notifications.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
} 