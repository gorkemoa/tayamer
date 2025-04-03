import 'package:flutter/material.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum OfferViewState {
  initial,
  loading,
  loaded,
  error,
}

class OfferViewModel extends ChangeNotifier {
  final OfferService _offerService = OfferService();
  
  List<Offer> _offers = [];
  Offer? _selectedOffer;
  String _errorMessage = '';
  OfferViewState _state = OfferViewState.initial;
  
  // Getters
  List<Offer> get offers => _offers;
  Offer? get selectedOffer => _selectedOffer;
  String get errorMessage => _errorMessage;
  OfferViewState get state => _state;
  
  // API'den tüm teklifleri yükle
  Future<void> loadOffers() async {
    try {
      _state = OfferViewState.loading;
      notifyListeners();
      
      _offers = await _offerService.getOffers();
      _state = OfferViewState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OfferViewState.error;
    } finally {
      notifyListeners();
    }
  }
  
  // ID'ye göre teklif detayını getir
  Future<void> getOfferDetail(String offerId) async {
    try {
      _state = OfferViewState.loading;
      notifyListeners();
      
      _selectedOffer = await _offerService.getOfferDetail(offerId);
      _state = OfferViewState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OfferViewState.error;
    } finally {
      notifyListeners();
    }
  }
  
  // ChatUrl'i açma
  Future<void> openChatUrl(String chatUrl) async {
    if (chatUrl.isEmpty) {
      _errorMessage = 'Geçerli bir sohbet linki bulunamadı';
      notifyListeners();
      return;
    }
    
    final url = Uri.parse(chatUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = 'Mesajlaşma sayfası açılamadı: $chatUrl';
      notifyListeners();
    }
  }
  
  // PDF'i açma
  Future<void> openPdfUrl(String pdfUrl) async {
    if (pdfUrl.isEmpty) {
      _errorMessage = 'PDF belgesi bulunamadı';
      notifyListeners();
      return;
    }
    
    final url = Uri.parse(pdfUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = 'PDF belgesi açılamadı: $pdfUrl';
      notifyListeners();
    }
  }
  
  // Detay URL'ini açma
  Future<void> openDetailUrl(String detailUrl) async {
    if (detailUrl.isEmpty) {
      _errorMessage = 'Detay sayfası bulunamadı';
      notifyListeners();
      return;
    }
    
    final url = Uri.parse(detailUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = 'Detay sayfası açılamadı: $detailUrl';
      notifyListeners();
    }
  }
  
  // Seçili teklifi temizle
  void clearSelectedOffer() {
    _selectedOffer = null;
    notifyListeners();
  }
  
  // Hatayı temizle
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
} 