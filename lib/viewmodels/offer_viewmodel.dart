import 'package:flutter/material.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

enum OfferViewState {
  initial,
  loading,
  loaded,
  error,
  success,
}

class OfferViewModel extends ChangeNotifier {
  final OfferService _offerService = OfferService();
  
  List<Offer> _offers = [];
  Offer? _selectedOffer;
  String _errorMessage = '';
  OfferViewState _state = OfferViewState.initial;
  Map<String, dynamic>? _offerResponse;
  
  // Getters
  List<Offer> get offers => _offers;
  Offer? get selectedOffer => _selectedOffer;
  String get errorMessage => _errorMessage;
  OfferViewState get state => _state;
  Map<String, dynamic>? get offerResponse => _offerResponse;
  
  // Yeni teklif oluştur
  Future<bool> createOffer(Map<String, dynamic> offerData) async {
    try {
      _state = OfferViewState.loading;
      _offerResponse = null;
      notifyListeners();
      
      final response = await _offerService.submitOffer(offerData);
      _offerResponse = response;
      _state = OfferViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = OfferViewState.error;
      notifyListeners();
      return false;
    }
  }
  
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
  
  // PDF'i paylaş
  Future<void> openPdfUrl(String pdfUrl) async {
    if (pdfUrl.isEmpty) {
      _errorMessage = 'PDF belgesi bulunamadı';
      notifyListeners();
      return;
    }
    
    try {
      // PDF dosyasını önce indir
      final response = await http.get(Uri.parse(pdfUrl));
      final bytes = response.bodyBytes;
      
      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${path.basename(pdfUrl)}');
      await file.writeAsBytes(bytes);
      
      // Dosyayı paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'PDF Teklifim',
      );
    } catch (e) {
      _errorMessage = 'PDF paylaşılırken hata oluştu: ${e.toString()}';
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