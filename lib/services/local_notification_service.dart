import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart' as app_models;

/// Gerçek sistem bildirimleri oluşturan servis
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Bildirim göstermek için global key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  LocalNotificationService._internal();
  
  // Bildirim servisi başlatıldı mı?
  bool get isInitialized => _isInitialized;
  
  // Bildirimleri başlat
  Future<void> initialize() async {
    try {
      // Zaten başlatılmışsa tekrar başlatma
      if (_isInitialized) {
        print('Bildirim servisi zaten başlatılmış');
        return;
      }
      
      print('Bildirim servisi başlatılma adımları:');
      
      // Zaman dilimi
      print('1. Zaman dilimi başlatılıyor...');
      tz.initializeTimeZones();
      
      // Platform kontrol - iOS vs Android
      bool isIOS = false;
      try {
        if (navigatorKey.currentContext != null) {
          isIOS = Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS;
        }
      } catch (e) {
        print('Platform kontrolü yapılamadı: $e');
      }
      print('Platform: ${isIOS ? "iOS" : "Android"}');
      
      // Android için ayarlar
      print('2. Platform-spesifik ayarlar hazırlanıyor...');
      final AndroidInitializationSettings androidInitializationSettings = 
          const AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS için ayarlar
      final DarwinInitializationSettings iOSInitializationSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Başlangıç ayarları
      print('3. Başlangıç ayarları oluşturuluyor...');
      final InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );
      
      try {
        // Bildirimleri başlat
        print('4. FlutterLocalNotificationsPlugin başlatılıyor...');
        final bool? result = await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
        
        _isInitialized = result ?? false;
        print('5. Bildirim servisi başlatıldı: $_isInitialized');
      } catch (innerException) {
        print('Plugin başlatılırken hata: $innerException');
        if (innerException is MissingPluginException) {
          print('MissingPluginException: Plugin bulunamadı veya düzgün kaydedilmedi');
          print('iOS için Info.plist, Android için AndroidManifest.xml kontrol edilmeli');
        }
        rethrow;
      }
      
      // İzinleri kontrol et
      if (_isInitialized) {
        print('6. Bildirim izinleri isteniyor...');
        await _requestPermissions();
        print('7. Bildirim izinleri tamamlandı');
      } else {
        print('Bildirim servisi başlatılamadı: flutter_local_notifications başlatma hatası');
        throw Exception('Bildirim servisi başlatılamadı');
      }
      
      return;
    } catch (e) {
      _isInitialized = false;
      print('Bildirim servisi başlatılırken hata: $e');
      
      // Eğer MissingPluginException ise, plugin'in düzgün kurulmadığını belirt
      if (e.toString().contains('MissingPluginException')) {
        print('Plugin kurulumu tamamlanmadı, lütfen projeyi yeniden build edin');
        print('İşlem: flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run');
      }
      
      // Hatayı yukarıya ilet ki bilgilendirebilelim
      throw Exception('Bildirim servisi başlatılamadı: $e');
    }
  }
  
  // Bildirime tıklandığında çağrılacak
  void _onNotificationTapped(NotificationResponse details) {
    print('Bildirime tıklandı: ${details.payload}');
    
    // Bildirime tıklandığında yapılacak işlemler
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Burada bildirimin türüne göre yönlendirme yapılabilir
      final payload = details.payload;
      if (payload != null && payload.isNotEmpty) {
        // Örneğin: SMS onayı gerektiren bildirim ise
        if (payload == 'policy_payment_sms_code') {
          // İlgili sayfaya yönlendir
          // Navigator.pushNamed(context, '/sms_verification');
        }
      }
    }
  }
  
  Future<void> _requestPermissions() async {
    try {
      // Android 13+ için bildirim izni iste
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
          
      // iOS için izinleri kontrol et
      await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    } catch (e) {
      print('Bildirim izinleri istenirken hata: $e');
    }
  }
  
  // Anlık bildirim göster
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('Bildirim servisi başlatılmamış, bildirimler gösterilemez');
      // Service'i başlatmayı dene
      try {
        print('Bildirim gösterme öncesi servisi başlatmayı deniyorum...');
        await initialize();
        print('Bildirim servisi başarıyla başlatıldı, bildirimi göstermeye devam ediyorum');
      } catch (initError) {
        print('Gösterim sırasında servis başlatılamadı: $initError');
        // Fallback olarak uygulama içi bildirimleri göster
        _showInAppNotification(title, body, payload);
        return;
      }
    }
    
    try {
      print('iOS/Android bildirimi göstermeye çalışıyorum...');
      // Android bildirim kanalı
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'tayamer_notification_channel',
        'Tayamer Bildirimleri',
        channelDescription: 'Tayamer uygulaması bildirimleri',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        enableLights: true,
        color: Color(0xFF1E3A8A),
        ledColor: Color(0xFF1E3A8A),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
      
      // iOS bildirim detayları
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default', // iOS için varsayılan ses
        interruptionLevel: InterruptionLevel.active, // iOS 15+ için bildirim kesintisi seviyesi
      );
      
      // Bildirim detayları
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      // iOS izinlerini bir kez daha kontrol et
      try {
        print('iOS izinlerini kontrol ediyorum...');
        final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        print('iOS izinleri durumu: $result');
      } catch (permissionError) {
        print('İzin kontrolü hatası: $permissionError');
      }
      
      // Bildirimi göster
      print('Bildirimi gösteriyorum: "$title" - "$body"');
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print('Bildirim gösterme isteği tamamlandı');
    } catch (e) {
      print('Bildirim gösterilirken hata: $e');
      
      // Eğer hata MissingPluginException veya PlatformException ise
      if (e is MissingPluginException || e is PlatformException) {
        print('Plugin hatası, fallback olarak uygulama içi bildirim gösteriliyor');
      }
      
      // Fallback olarak uygulama içi bildirimleri göster
      _showInAppNotification(title, body, payload);
    }
  }
  
  // Ekranda uygulama içi bildirim göster
  void _showInAppNotification(String title, String body, String? payload) {
    // Mevcut bağlamı kullanarak ekranda bildirim göster
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Ekranın üst kısmında bir SnackBar göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'KAPAT',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } else {
      print('Bildirim gösterilemiyor: context bulunamadı');
    }
  }
  
  // API'den alınan bildirimleri yerel bildirim olarak göster
  Future<void> showApiNotifications(List<app_models.PaymentNotification> notifications) async {
    if (notifications.isEmpty) return;
    
    try {
      // En son bildirimi al
      final latestNotification = notifications.first;
      
      // Bildirimi göster
      await showNotification(
        id: int.tryParse(latestNotification.id) ?? 0,
        title: latestNotification.title,
        body: latestNotification.body,
        payload: latestNotification.type, // Bildirim tipi ile payload gönder
      );
    } catch (e) {
      print('API bildirimleri gösterilirken hata: $e');
    }
  }
  
  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      print('Bildirimler iptal edilirken hata: $e');
    }
  }
  
  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print('Bildirim iptal edilirken hata: $e');
    }
  }
} 