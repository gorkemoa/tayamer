import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

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
  
  NotificationViewState _state = NotificationViewState.initial;
  String _errorMessage = '';
  List<PaymentNotification>? _notifications;
  PaymentNotification? _selectedNotification;
  
  // Bildirimleri otomatik olarak yenile
  Timer? _notificationTimer;
  
  // Constructor
  NotificationViewModel() {}
  
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
  
  // Bildirimleri getir
  Future<bool> getNotifications() async {
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
      
      print('API isteği yapılıyor: userToken=${userToken.substring(0, 10)}...');
      
      final response = await _notificationService.getNotifications(userToken);
      
      // API yanıtının detaylı analizi
      print('API yanıtı alındı: success=${response.success}, error=${response.error}');
      print('Gelen bildirimler: ${response.notifications?.length ?? 0} adet');
      
      if (response.success) {
        _notifications = response.notifications ?? [];
        _state = NotificationViewState.success;
        
        // Gelen bildirimlerin içeriğini kontrol et
        if (_notifications!.isEmpty) {
          print('Bildirim listesi boş geldi!');
        } else {
          print('Bildirimler başarıyla alındı: ${_notifications!.length} adet bildirim');
          // İlk birkaç bildirimin içeriğini göster
          final sampleSize = _notifications!.length > 3 ? 3 : _notifications!.length;
          for (int i = 0; i < sampleSize; i++) {
            print('Bildirim $i: ${_notifications![i].title} - ${_notifications![i].body.substring(0, _notifications![i].body.length > 30 ? 30 : _notifications![i].body.length)}...');
          }
        }
        
        notifyListeners();
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
  
  // Bildirimleri otomatik olarak yenile
  void startAutoRefresh({Duration refreshInterval = const Duration(minutes: 15)}) {
    // Eğer zaten bir zamanlayıcı varsa, önce onu iptal et
    stopAutoRefresh();
    
    print('Düzenli bildirim kontrolü başlatılıyor - Aralık: ${refreshInterval.inMinutes} dakika');
    
    // İlk kontrolü hemen yap
    Future.delayed(Duration.zero, () async {
      await getNotifications();
    });
    
    // Periyodik kontroller için zamanlayıcı oluştur
    _notificationTimer = Timer.periodic(refreshInterval, (timer) async {
      print('Otomatik bildirim kontrolü yapılıyor...');
      await getNotifications();
    });
  }
  
  // Düzenli bildirim yenilemeyi durdur
  void stopAutoRefresh() {
    if (_notificationTimer != null && _notificationTimer!.isActive) {
      _notificationTimer!.cancel();
      _notificationTimer = null;
      print('Düzenli bildirim kontrolü durduruldu');
    }
  }
  
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
} 