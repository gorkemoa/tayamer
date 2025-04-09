import 'dart:convert';

class NotificationRequest {
  final String userToken;

  NotificationRequest({
    required this.userToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class PaymentNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String typeId;
  final String? url;
  final String createDate;

  PaymentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.typeId,
    this.url,
    required this.createDate,
  });

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    return PaymentNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      typeId: json['type_id'] ?? '',
      url: json['url'],
      createDate: json['create_date'] ?? '',
    );
  }
}

class NotificationResponse {
  final bool error;
  final bool success;
  final List<PaymentNotification>? notifications;

  NotificationResponse({
    required this.error,
    required this.success,
    this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    List<PaymentNotification>? notificationList;
    
    // Debugging
    print('natificationsResponse.fromJson json içeriği: $json');
    
    // API yanıtında bildirim verisi var mı kontrol et
    if (json['data'] != null && json['data']['natifications'] != null) {
      // 1. durum: data.notifications şeklinde
      try {
        notificationList = (json['data']['natifications'] as List)
            .map((item) => PaymentNotification.fromJson(item))
            .toList();
        print('data.natifications içinden ${notificationList.length} bildirim işlendi');
      } catch (e) {
        print('data.natifications işlenirken hata: $e');
        notificationList = [];
      }
    } else if (json['data'] != null && json['data']['natifications'] != null) {
      // Alternatif yazım: data.natifications şeklinde
      try {
        notificationList = (json['data']['natifications'] as List)
            .map((item) => PaymentNotification.fromJson(item))
            .toList();
        print('data.natifications içinden ${notificationList.length} bildirim işlendi');
      } catch (e) {
        print('data.natifications işlenirken hata: $e');
        notificationList = [];
      }
    } else if (json['natifications'] != null) {
      // 2. durum: doğrudan notifications şeklinde
      try {
        notificationList = (json['natifications'] as List)
            .map((item) => PaymentNotification.fromJson(item))
            .toList();
        print('natifications içinden ${notificationList.length} bildirim işlendi');
      } catch (e) {
        print('natifications işlenirken hata: $e');
        notificationList = [];
      }
    } else if (json['natifications'] != null) {
      // Alternatif yazım: doğrudan natifications şeklinde
      try {
        notificationList = (json['natifications'] as List)
            .map((item) => PaymentNotification.fromJson(item))
            .toList();
        print('natifications içinden ${notificationList.length} bildirim işlendi');
      } catch (e) {
        print('natifications işlenirken hata: $e');
        notificationList = [];
      }
    } else if (json['data'] != null && json['data'] is List) {
      // 3. durum: data doğrudan liste olabilir
      try {
        notificationList = (json['data'] as List)
            .map((item) => PaymentNotification.fromJson(item))
            .toList();
        print('data listesinden ${notificationList.length} bildirim işlendi');
      } catch (e) {
        print('data listesi işlenirken hata: $e');
        notificationList = [];
      }
    } else {
      // Bildirim bulunamadı
      print('JSON içerisinde bildirim verisi bulunamadı: $json');
      notificationList = [];
    }

    return NotificationResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? (json['error'] == false || json['200'] == 'OK'), // '200: OK' durumunu başarılı kabul et
      notifications: notificationList,
    );
  }

  factory NotificationResponse.error(String errorMessage) {
    return NotificationResponse(
      error: true,
      success: false,
    );
  }
}

class SmsCodeRequest {
  final String userToken;
  final int paymentId;
  final String smsCode;

  SmsCodeRequest({
    required this.userToken,
    required this.paymentId,
    required this.smsCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'paymentID': paymentId,
      'smsCode': smsCode,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class SmsCodeResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  SmsCodeResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SmsCodeResponse.fromJson(Map<String, dynamic> json) {
    return SmsCodeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  factory SmsCodeResponse.error(String errorMessage) {
    return SmsCodeResponse(
      success: false,
      message: errorMessage,
    );
  }
} 