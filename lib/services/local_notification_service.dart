import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart' as app_models;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  LocalNotificationService._internal();
  
  // Bildirim servisi başlatıldı mı?
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    try {
      // Zaman dilimi
      tz.initializeTimeZones();
      
      // Android için ayarlar
      const AndroidInitializationSettings androidInitializationSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS için ayarlar
      const DarwinInitializationSettings iOSInitializationSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Başlangıç ayarları
      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );
      
      // Bildirimleri başlat
      final bool? result = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Bildirime tıklandığında
          print('Bildirime tıklandı: ${details.payload}');
          // Burada router ile ilgili sayfaya yönlendirme yapılabilir
        },
      );
      
      _isInitialized = result ?? false;
      print('Bildirim servisi başlatıldı: $_isInitialized');
      
      // İzinleri kontrol et (iOS için)
      if (_isInitialized) {
        await _requestPermissions();
      }
    } catch (e) {
      print('Bildirim servisi başlatılırken hata: $e');
      _isInitialized = false;
      // Hatayı bildir ki uyarılabilelim
      throw PlatformException(
        code: 'notification_init_failed',
        message: 'Bildirim servisi başlatılamadı: $e',
      );
    }
  }
  
  Future<void> _requestPermissions() async {
    try {
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
  
  // Anlık bildirim gönder
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('Bildirim servisi başlatılmamış, bildirimler gösterilemez');
      return;
    }
    
    try {
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
      );
      
      // Bildirim detayları
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      // Bildirimi göster
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Bildirim gösterilirken hata: $e');
    }
  }
  
  // API'den alınan bildirimleri yerel bildirim olarak göster
  Future<void> showApiNotifications(List<app_models.PaymentNotification> notifications) async {
    if (!_isInitialized || notifications.isEmpty) return;
    
    try {
      // En son bildirimi al
      final latestNotification = notifications.first;
      
      // Bildirimi göster
      await showNotification(
        id: int.tryParse(latestNotification.id) ?? 0,
        title: latestNotification.title,
        body: latestNotification.body,
        payload: latestNotification.typeId,
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