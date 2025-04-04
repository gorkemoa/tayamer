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
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  
  NotificationViewState _state = NotificationViewState.initial;
  String _errorMessage = '';
  List<PaymentNotification>? _notifications;
  PaymentNotification? _selectedNotification;
  
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
    await _localNotificationService.initialize();
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
  
  // Test bildirimi göster
  Future<void> showTestNotification() async {
    await _localNotificationService.showNotification(
      id: 9999,
      title: 'Test Bildirimi',
      body: 'Bu bir test bildirimidir.',
      payload: 'test',
    );
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