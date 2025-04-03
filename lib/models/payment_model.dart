import 'dart:convert';

class PaymentRequest {
  final String userToken;
  final int offerId;
  final int wsPriceId;
  final int companyId;
  final String holder;
  final String cardNumber;
  final String expDate;
  final int cvv;

  PaymentRequest({
    required this.userToken,
    required this.offerId,
    required this.wsPriceId,
    required this.companyId,
    required this.holder,
    required this.cardNumber,
    required this.expDate,
    required this.cvv,
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'offerID': offerId,
      'wsPriceID': wsPriceId,
      'companyID': companyId,
      'holder': holder,
      'cardNumber': cardNumber,
      'expDate': expDate,
      'cvv': cvv,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class PaymentResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  PaymentResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  factory PaymentResponse.error(String errorMessage) {
    return PaymentResponse(
      success: false,
      message: errorMessage,
    );
  }
} 