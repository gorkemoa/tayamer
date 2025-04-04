import 'package:flutter/material.dart';
import '../models/policy_type_model.dart';
import '../services/policy_type_service.dart';

enum PolicyTypeViewState {
  initial,
  loading,
  loaded,
  error,
}

class PolicyTypeViewModel extends ChangeNotifier {
  final PolicyTypeService _policyTypeService = PolicyTypeService();
  
  List<PolicyType> _policyTypes = [];
  PolicyType? _selectedPolicyType;
  String _errorMessage = '';
  PolicyTypeViewState _state = PolicyTypeViewState.initial;
  Map<String, String>? _qrCodeData;
  Map<String, String> _selectedOptions = {};

  // Getters
  List<PolicyType> get policyTypes => _policyTypes;
  PolicyType? get selectedPolicyType => _selectedPolicyType;
  String get errorMessage => _errorMessage;
  PolicyTypeViewState get state => _state;
  Map<String, String>? get qrCodeData => _qrCodeData;
  List<PolicyType> get activePolicyTypes => _policyTypes.where((type) => type.isActive).toList();
  Map<String, String> get selectedOptions => _selectedOptions;

  // API'den tüm poliçe tiplerini yükle
  Future<void> loadPolicyTypes() async {
    try {
      _state = PolicyTypeViewState.loading;
      notifyListeners();

      _policyTypes = await _policyTypeService.getPolicyTypes();
      _state = PolicyTypeViewState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = PolicyTypeViewState.error;
    } finally {
      notifyListeners();
    }
  }

  // Belirli bir alan için seçenekleri getir
  List<Option>? getFieldOptions(String fieldKey) {
    if (_selectedPolicyType == null) return null;
    return _policyTypeService.getFieldOptions(_selectedPolicyType!, fieldKey);
  }

  // Bir alan için seçenek seç
  void selectOption(String fieldKey, String optionValue) {
    _selectedOptions[fieldKey] = optionValue;
    notifyListeners();
  }

  // Seçilen bir seçeneğin değerini al
  String? getSelectedOption(String fieldKey) {
    return _selectedOptions[fieldKey];
  }

  // Seçilen bir seçeneğin etiketini al
  String? getSelectedOptionLabel(String fieldKey) {
    final optionValue = _selectedOptions[fieldKey];
    if (_selectedPolicyType == null || optionValue == null) return null;
    
    return _policyTypeService.getOptionLabel(_selectedPolicyType!, fieldKey, optionValue);
  }

  // Seçili poliçe tipindeki select türündeki alanları getir
  List<Field> getSelectFields() {
    if (_selectedPolicyType == null) return [];
    return _selectedPolicyType!.fields.where((field) => field.type == 'select').toList();
  }

  // Seçenekleri temizle
  void clearSelectedOptions() {
    _selectedOptions = {};
    notifyListeners();
  }

  // ID'ye göre poliçe tipi seç
  Future<void> selectPolicyTypeById(int typeId) async {
    try {
      _state = PolicyTypeViewState.loading;
      notifyListeners();

      _selectedPolicyType = await _policyTypeService.getPolicyTypeById(typeId);
      _state = PolicyTypeViewState.loaded;
      
      // Yeni poliçe tipi seçildiğinde seçenekleri temizle
      clearSelectedOptions();
    } catch (e) {
      _errorMessage = e.toString();
      _state = PolicyTypeViewState.error;
    } finally {
      notifyListeners();
    }
  }

  // Poliçe tipini seç
  void selectPolicyType(PolicyType policyType) {
    _selectedPolicyType = policyType;
    // Yeni poliçe tipi seçildiğinde seçenekleri temizle
    clearSelectedOptions();
    notifyListeners();
  }

  // QR kod verilerini işle
  void processQRCode(String qrData) {
    if (_selectedPolicyType == null) {
      _errorMessage = 'Önce bir poliçe tipi seçmelisiniz';
      _state = PolicyTypeViewState.error;
      notifyListeners();
      return;
    }

    try {
      _qrCodeData = _policyTypeService.processQRCode(qrData, _selectedPolicyType!);
      if (_qrCodeData == null || _qrCodeData!.isEmpty) {
        _errorMessage = 'QR kod işlenemedi veya uyumsuz';
        _state = PolicyTypeViewState.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = PolicyTypeViewState.error;
    } finally {
      notifyListeners();
    }
  }

  // Hata durumunu sıfırla
  void resetError() {
    _errorMessage = '';
    _state = PolicyTypeViewState.initial;
    notifyListeners();
  }

  // QR kod verilerini temizle
  void clearQRData() {
    _qrCodeData = null;
    notifyListeners();
  }
} 