import 'dart:convert';

class PaymentRequest {
  final String userToken;
  final int offerId;
  final int companyId;
  final String holder;
  final String cardNumber;
  final String expDate;
  final String cvv;
  final int installment;
  final String holderTC;
  final String holderBD;

  PaymentRequest({
    required this.userToken,
    required this.offerId,
    required this.companyId,
    required this.holder,
    required this.cardNumber,
    required this.expDate,
    required this.cvv,
    this.installment = 1,
    this.holderTC = '',
    this.holderBD = '',
  });

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'offerID': offerId,
      'companyID': companyId,
      'holder': holder,
      'cardNumber': cardNumber,
      'expDate': expDate,
      'cvv': cvv,
      'installment': installment,
      'holderTC': holderTC,
      'holderBD': holderBD,
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