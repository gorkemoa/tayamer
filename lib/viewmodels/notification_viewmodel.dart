import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

enum NotificationViewState {
  initial,
  loading,
  success,
  error,
  smsCodeSuccess,
  smsCodeError,
}

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  late final LocalNotificationService _localNotificationService;
  
  NotificationViewState _state = NotificationViewState.initial;
  String _errorMessage = '';
  List<PaymentNotification>? _notifications;
  PaymentNotification? _selectedNotification;
  
  // Constructor - LocalNotificationService alıyor
  NotificationViewModel({LocalNotificationService? localNotificationService}) {
    _localNotificationService = localNotificationService ?? LocalNotificationService();
  }
  
  // Getter'lar
  NotificationViewState get state => _state;
  String get errorMessage => _errorMessage;
  List<PaymentNotification>? get notifications => _notifications;
  PaymentNotification? get selectedNotification => _selectedNotification;
  
  // Durum kontrol
  bool get isLoading => _state == NotificationViewState.loading;
  bool get isSuccess => _state == NotificationViewState.success;
  bool get isError => _state == NotificationViewState.error;
  bool get isSmsCodeSuccess => _state == NotificationViewState.smsCodeSuccess;
  bool get isSmsCodeError => _state == NotificationViewState.smsCodeError;
  
  // LocalNotificationService'i başlat
  Future<void> initializeLocalNotifications() async {
    try {
      print('NotificationViewModel: Bildirim servisi başlatılıyor...');
      bool isRetrying = false;
      
      // İlk deneme
      try {
        await _localNotificationService.initialize();
      } catch (e) {
        print('İlk başlatma denemesi başarısız: $e');
        isRetrying = true;
        
        // Kısa bir bekleme ile tekrar dene
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Tekrar dene
        await _localNotificationService.initialize();
      }
      
      if (isRetrying) {
        print('Bildirim servisi ikinci denemede başlatıldı');
      } else {
        print('Bildirim servisi ilk denemede başlatıldı');
      }
    } catch (e) {
      print('Bildirim servisini başlatma hatası: $e');
      // Hatayı yukarıya ilet
      rethrow;
    }
  }
  
  // Bildirimleri getir
  Future<bool> getNotifications({bool showAsLocalNotification = false}) async {
    try {
      _state = NotificationViewState.loading;
      _errorMessage = '';
      notifyListeners();
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token') ?? '';
      
      if (userToken.isEmpty) {
        _errorMessage = 'Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.';
        _state = NotificationViewState.error;
        notifyListeners();
        return false;
      }
      
      final response = await _notificationService.getNotifications(userToken);
      
      if (response.success) {
        _notifications = response.notifications;
        _state = NotificationViewState.success;
        notifyListeners();
        
        // Eğer istenirse, bildirimleri gerçek bildirim olarak göster
        if (showAsLocalNotification && _notifications != null && _notifications!.isNotEmpty) {
          await _localNotificationService.showApiNotifications(_notifications!);
        }
        
        return true;
      } else {
        _errorMessage = 'Bildirimler alınamadı.';
        _state = NotificationViewState.error;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _errorMessage = 'Bildirimler alınırken bir hata oluştu: ${e.toString()}';
      _state = NotificationViewState.error;
      notifyListeners();
      return false;
    }
  }
  
  // Bildirime tıklandığında çağrılacak fonksiyon
  String? handleNotificationTap(PaymentNotification notification) {
    _selectedNotification = notification;
    notifyListeners();
    
    // Bildirimin türüne göre hedef rotayı belirle
    switch (notification.type) {
      case 'policy_created':
        // Poliçe detay sayfasına yönlendir
        return '/policy/detail/${notification.typeId}';
      case 'policy_payment_waiting':
        // Ödeme sayfasına yönlendir
        return '/payment/${notification.typeId}';
      case 'policy_payment_sms_code':
        // SMS doğrulama sayfasına yönlendir
        return '/payment/sms-verification/${notification.typeId}';
      case 'offer_created':
        // Ödeme sayfasına yönlendir
        return '/offer/${notification.typeId}';
      default:
        // Varsayılan olarak bildirimler sayfasına yönlendir
        return '/notifications';
    
    }
  }
  
  // Test bildirimi göster
  Future<void> showTestNotification() async {
    try {
      print('Test bildirimi gösterme başladı');
      
      if (!_localNotificationService.isInitialized) {
        print('Bildirim servisi başlatılmamış, bildirimleri gösteremiyoruz');
        // Bildirimleri tekrar başlatmayı dene
        try {
          print('Bildirim servisini başlatmayı deniyorum...');
          await _localNotificationService.initialize();
          print('Test öncesi bildirim servisi başarıyla başlatıldı');
        } catch (initError) {
          print('Bildirim servisi başlatılamadı: $initError');
          
          // Fallback - SnackBar ile uygulama içi bildirim göster
          throw Exception('Bildirim servisi başlatılamadı: $initError. GERÇEK BİLDİRİM OLACAK YUKARDAN İNEN GERÇEK OLAN');
        }
      }
      
      // Bildirim göster
      print('Bildirimi göstermeyi deniyorum...');
      print('Bildirim başarıyla gösterildi');
    } catch (e) {
      print('Test bildirimi gönderilirken hata: $e');
      // Hatayı yukarıya ilet ki kullanıcıya gösterilebilsin
      rethrow;
    }
  }
  
  // Bildirimlerden SMS kodunu bul
  PaymentNotification? findSmsNotification() {
    if (_notifications == null || _notifications!.isEmpty) {
      return null;
    }
    
    // Tüm bildirimler arasından policy_payment_sms_code türündeki en son bildirimi bul
    for (var notification in _notifications!) {
      if (notification.type == 'policy_payment_sms_code') {
        _selectedNotification = notification;
        notifyListeners();
        return notification;
      }
    }
    
    return null;
  }
  
  // SMS kodu gönder
  Future<bool> sendSmsCode(String smsCode) async {
    if (_selectedNotification == null) {
      _errorMessage = 'Doğrulama kodu bildirimi bulunamadı.';
      _state = NotificationViewState.smsCodeError;
      notifyListeners();
      return false;
    }
    
    try {
      _state = NotificationViewState.loading;
      _errorMessage = '';
      notifyListeners();
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token') ?? '';
      
      if (userToken.isEmpty) {
        _errorMessage = 'Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.';
        _state = NotificationViewState.smsCodeError;
        notifyListeners();
        return false;
      }
      
      // TypeId'yi int'e çevir
      int paymentId;
      try {
        paymentId = int.parse(_selectedNotification!.typeId);
      } catch (e) {
        _errorMessage = 'Geçersiz ödeme kimliği.';
        _state = NotificationViewState.smsCodeError;
        notifyListeners();
        return false;
      }
      
      final response = await _notificationService.sendSmsCode(
        userToken,
        paymentId,
        smsCode,
      );
      
      if (response.success) {
        _state = NotificationViewState.smsCodeSuccess;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _state = NotificationViewState.smsCodeError;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _errorMessage = 'SMS kodu gönderilirken bir hata oluştu: ${e.toString()}';
      _state = NotificationViewState.smsCodeError;
      notifyListeners();
      return false;
    }
  }
  
  // Seçili bildirimi ayarla
  void setSelectedNotification(PaymentNotification notification) {
    _selectedNotification = notification;
    notifyListeners();
  }
  
  // Durumu sıfırla
  void resetState() {
    _state = NotificationViewState.initial;
    _errorMessage = '';
    notifyListeners();
  }
} 