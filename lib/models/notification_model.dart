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
    
    if (json['data'] != null && json['data']['natifications'] != null) {
      notificationList = (json['data']['natifications'] as List)
          .map((item) => PaymentNotification.fromJson(item))
          .toList();
    }

    return NotificationResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
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