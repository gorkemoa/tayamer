import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../views/card_scan_view.dart'; // CardData sınıfı için import eklendi

enum PaymentViewState {
  initial,
  loading,
  success,
  error,
}

class PaymentViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  
  PaymentViewState _state = PaymentViewState.initial;
  String _errorMessage = '';
  PaymentResponse? _paymentResponse;
  
  // Getter'lar
  PaymentViewState get state => _state;
  String get errorMessage => _errorMessage;
  PaymentResponse? get paymentResponse => _paymentResponse;
  
  // Ödeme durumunu kontrol et
  bool get isLoading => _state == PaymentViewState.loading;
  bool get isSuccess => _state == PaymentViewState.success;
  bool get isError => _state == PaymentViewState.error;
  
  // Kart bilgileri ile ödeme işlemini başlat
  Future<bool> processPayment({
    required int offerId,
    required int wsPriceId,
    required int companyId,
    required String holder,
    required String cardNumber,
    required String expDate,
    required int cvv,
  }) async {
    try {
      _state = PaymentViewState.loading;
      _errorMessage = '';
      notifyListeners();
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token');
      
      if (userToken == null || userToken.isEmpty) {
        _errorMessage = 'Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.';
        _state = PaymentViewState.error;
        notifyListeners();
        return false;
      }
      
      // Ödeme isteğini oluştur
      final paymentRequest = PaymentRequest(
        userToken: userToken,
        offerId: offerId,
        wsPriceId: wsPriceId,
        companyId: companyId,
        holder: holder,
        cardNumber: cardNumber,
        expDate: expDate,
        cvv: cvv,
      );
      
      // Ödeme işlemini başlat
      final response = await _paymentService.processPayment(paymentRequest);
      _paymentResponse = response;
      
      // Yanıtı kontrol et
      if (response.success) {
        _state = PaymentViewState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _state = PaymentViewState.error;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _errorMessage = 'Ödeme işlemi sırasında bir hata oluştu: ${e.toString()}';
      _state = PaymentViewState.error;
      notifyListeners();
      return false;
    }
  }
  
  // Manuel olarak kart bilgilerinden ödeme işlemini başlat
  Future<bool> processPaymentFromCardData(CardData cardData, {
    required int offerId,
    required int wsPriceId,
    required int companyId,
  }) async {
    return processPayment(
      offerId: offerId,
      wsPriceId: wsPriceId,
      companyId: companyId,
      holder: cardData.cardHolder,
      cardNumber: cardData.cardNumber.replaceAll(' ', ''), // Boşlukları kaldır
      expDate: cardData.expiryDate,
      cvv: int.tryParse(cardData.cvv) ?? 0,
    );
  }
  
  // Hatayı temizle ve durumu sıfırla
  void resetState() {
    _state = PaymentViewState.initial;
    _errorMessage = '';
    _paymentResponse = null;
    notifyListeners();
  }
} 