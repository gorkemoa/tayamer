import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models/notification_model.dart' as app_models;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  LocalNotificationService._internal();
  
  Future<void> initialize() async {
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
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Bildirime tıklandığında
        print('Bildirime tıklandı: ${details.payload}');
        // Burada router ile ilgili sayfaya yönlendirme yapılabilir
      },
    );
    
    // İzinleri kontrol et (iOS için)
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  }
  
  // Anlık bildirim gönder
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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
  }
  
  // API'den alınan bildirimleri yerel bildirim olarak göster
  Future<void> showApiNotifications(List<app_models.PaymentNotification> notifications) async {
    if (notifications.isEmpty) return;
    
    // En son bildirimi al
    final latestNotification = notifications.first;
    
    // Bildirimi göster
    await showNotification(
      id: int.tryParse(latestNotification.id) ?? 0,
      title: latestNotification.title,
      body: latestNotification.body,
      payload: latestNotification.typeId,
    );
  }
  
  // Zamanlanmış bildirim gönder - Bu metodu şimdilik kapalı tutalım
  /*
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    // ...
  }
  */
  
  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
} 