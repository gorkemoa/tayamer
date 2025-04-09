import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart' as app_models;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

  // APNS token kontrolü
  Future<String?> getAPNSToken() async {
    if (Platform.isIOS) {
      try {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        print('APNS token alındı: $apnsToken');
        return apnsToken;
      } catch (e) {
        print('APNS token alınırken hata: $e');
        return null;
      }
    }
    return null;
  }

  // Bildirimleri getir
  Future<app_models.NotificationResponse> getNotifications(String userToken) async {
    try {
      print('Bildirimler getiriliyor...');
      
      // UserId'yi SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('UserID bulunamadı');
        return app_models.NotificationResponse(
          error: true,
          success: false,
          notifications: [],
        );
      }
      
      // API endpoint
      final apiUrl = '$_baseUrl/user/account/$userId/natifications';
      
      // İstek başlıklarını ve gövdesini oluştur
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': _getBasicAuthHeader(),
      };
      final body = jsonEncode({
        'userToken': userToken,
      });
      
      // İstek detaylarını logla
      print('API İsteği: URL=$apiUrl');
      print('API İsteği: Method=POST');
      print('API İsteği: Headers=$headers');
      print('API İsteği: Body=$body');
      
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );
      
      // Yanıt kodunu ve ham yanıtı logla
      print('API yanıt kodu: ${response.statusCode}');
      print('API Ham Yanıt Gövdesi: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        print('Bildirimler başarıyla alındı: ${data.toString()}');
        
        return app_models.NotificationResponse.fromJson(data);
      } else {
        print('Bildirimler alınamadı: HTTP ${response.statusCode}');
        return app_models.NotificationResponse(
          error: true,
          success: false,
          notifications: [],
        );
      }
    } catch (e) {
      print('Bildirimler alınırken hata oluştu: $e');
      return app_models.NotificationResponse(
        error: true,
        success: false,
        notifications: [],
      );
    }
  }

  // SMS kodu gönder
  Future<app_models.SmsCodeResponse> sendSmsCode(String userToken, int paymentId, String smsCode) async {
    try {
      // UserId'yi SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      
      if (userId == null) {
        print('UserID bulunamadı');
        return app_models.SmsCodeResponse.error('Kullanıcı kimliği bulunamadı.');
      }

      final apiUrl = '$_baseUrl/user/payment/$userId/addSms';
      print('SMS kodu isteği gönderiliyor: $apiUrl');
      
      final request = app_models.SmsCodeRequest(
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
        return app_models.SmsCodeResponse.error('Sunucu hatası: Lütfen daha sonra tekrar deneyiniz.');
      }
      
      // JSON formatını kontrol et
      try {
        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          return app_models.SmsCodeResponse.fromJson(data);
        }
        
        if (response.statusCode >= 400) {
          try {
            final errorData = jsonDecode(responseBody);
            return app_models.SmsCodeResponse.error(
              errorData['message'] ?? 'SMS kodu doğrulanamadı: HTTP ${response.statusCode}'
            );
          } catch (e) {
            return app_models.SmsCodeResponse.error('SMS kodu doğrulanamadı: HTTP ${response.statusCode}');
          }
        }
        
        return app_models.SmsCodeResponse.error('Beklenmeyen yanıt: HTTP ${response.statusCode}');
      } catch (e) {
        print('Yanıt JSON formatında değil: $e');
        return app_models.SmsCodeResponse.error('Sunucu yanıtı işlenemedi. Lütfen daha sonra tekrar deneyiniz.');
      }
      
    } catch (e) {
      print('SMS kodu API hatası: $e');
      if (e is http.ClientException) {
        return app_models.SmsCodeResponse.error('Ağ hatası: ${e.message}');
      } else {
        return app_models.SmsCodeResponse.error('SMS kodu gönderilirken hata oluştu: ${e.toString()}');
      }
    }
  }

  // FCM token'ı sunucuya kaydet
  Future<bool> registerFcmToken(String userToken, String fcmToken) async {
    try {
      print('FCM token sunucuya kaydediliyor: $fcmToken');
      
      final url = Uri.parse('$_baseUrl/notifications/register-device');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
        'Authentication': _getBasicAuthHeader(),
      };
      
      final body = jsonEncode({
        'device_token': fcmToken,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      });
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('FCM token başarıyla kaydedildi: ${jsonResponse.toString()}');
        return true;
      } else {
        print('FCM token kaydedilirken hata: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('FCM token kaydedilirken istisna: $e');
      return false;
    }
  }
  
  // FCM token'ı güncelle (uygulama her açıldığında çağrılmalı)
  Future<void> updateFcmToken() async {
    try {
      // Kullanıcı oturumu kontrolü
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token');
      
      if (userToken == null || userToken.isEmpty) {
        print('Kullanıcı oturumu olmadığı için FCM token güncellenemedi');
        return;
      }
      
      // Mevcut FCM token'ı al
      String? fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token alınamadığı için sunucuya kaydedilemedi');
        return;
      }
      
      // Token'ı kaydet
      print('Güncel FCM token: $fcmToken');
      await registerFcmToken(userToken, fcmToken);
      
      // Token yenilendiğinde otomatik güncelleme için listener ekle
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM token yenilendi: $newToken');
        await registerFcmToken(userToken, newToken);
      });
      
    } catch (e) {
      print('FCM token güncellenirken hata: $e');
    }
  }

  Future<void> initialize() async {
    try {
      // Firebase App'in başlatıldığından emin ol
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Bildirim izinlerini kontrol et
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Bildirim izinleri durumu: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Bildirim izinleri reddedildi');
        return;
      }

      // iOS için özel ayarlar
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        try {
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          print('APNS token alındı: $apnsToken');
        } catch (e) {
          print('APNS token kontrolü sırasında hata: $e');
        }
      }

      // FCM token alma işlemi
      try {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM Token başarıyla alındı: $token');
          await updateFcmToken();
        } else {
          print('FCM token null, 5 saniye sonra tekrar denenecek...');
          await Future.delayed(const Duration(seconds: 5));
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            print('İkinci denemede FCM Token alındı: $token');
            await updateFcmToken();
          } else {
            throw Exception('FCM token alınamadı');
          }
        }
      } catch (e) {
        print('FCM token alma işlemi başarısız: $e');
        // Token alınamasa bile diğer işlemlere devam et
      }

      // Yerel bildirimleri yapılandır
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
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
        _handleBackgroundNotificationTap(message);
      });
      
      // Android için bildirim kanalını oluştur
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannel();
      }
      
      print('Bildirim servisi başarıyla başlatıldı');
    } catch (e, stackTrace) {
      print('Bildirim servisi başlatılırken hata: $e');
      print('Hata detayı: $stackTrace');
      
      // Hata durumunda yeniden deneme
      try {
        print('Bildirim servisi yeniden başlatılıyor...');
        await Future.delayed(const Duration(seconds: 3));
        await initialize();
      } catch (retryError) {
        print('Bildirim servisi yeniden başlatılamadı: $retryError');
      }
    }
  }
  
  // Android için özel bildirim kanalı oluştur
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tayamer_high_importance_channel', // id
      'Tayamer Bildirimleri', // title
      description: 'Tayamer uygulaması bildirimleri', // description
      importance: Importance.high,
      enableLights: true,
      ledColor: Color(0xFF1E3A8A),
      playSound: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
        
    print('Android bildirim kanalı oluşturuldu');
  }
  
  // Arka planda bildirime tıklandığında işle
  void _handleBackgroundNotificationTap(RemoteMessage message) {
    print('Bildirime tıklandı: ${message.notification?.title}');
    
    final data = message.data;
    final notificationType = data['type'];
    final notificationId = data['id'];
    
    print('Bildirim tipi: $notificationType, ID: $notificationId');
    
    // Bildirim tipine göre navigasyon işlemini yapabilir veya veriyi kaydedebilirsiniz
    // Bu işlem genellikle main.dart içerisinde veya bir navigasyon servisi üzerinden yapılır
  }
  
  // RemoteMessage'dan bildirim göster
  void _showNotification(RemoteMessage message) {
    print('Ön planda bildirim gösteriliyor: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'tayamer_high_importance_channel',
            'Tayamer Bildirimleri',
            channelDescription: 'Tayamer uygulaması bildirimleri',
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: const Color(0xFF1E3A8A),
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // API'den alınan bildirimleri yerel bildirim olarak göster
  Future<void> showApiNotifications(List<app_models.PaymentNotification> notifications) async {
    if (notifications.isEmpty) return;
    
    try {
      // En son bildirimi al
      final latestNotification = notifications.first;
      
      // Bildirimi göster
      await _localNotifications.show(
        int.tryParse(latestNotification.id) ?? 0,
        latestNotification.title,
        latestNotification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'tayamer_high_importance_channel',
            'Tayamer Bildirimleri',
            channelDescription: 'Tayamer uygulaması bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF1E3A8A),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: latestNotification.type, // Bildirim tipi ile payload gönder
      );
    } catch (e) {
      print('API bildirimleri gösterilirken hata: $e');
    }
  }
} 