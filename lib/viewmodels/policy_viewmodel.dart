import 'package:flutter/material.dart';
import '../models/policy_model.dart';
import '../services/policy_service.dart';

enum PolicyLoadingStatus { initial, loading, loaded, error }

class PolicyViewModel extends ChangeNotifier {
  final PolicyService _policyService = PolicyService();
  
  List<Policy> _policies = [];
  List<Policy> _activePolicies = [];
  List<Policy> _inactivePolicies = [];
  
  PolicyLoadingStatus _status = PolicyLoadingStatus.initial;
  String _errorMessage = '';
  
  // Getter'lar
  List<Policy> get policies => _policies;
  List<Policy> get activePolicies => _activePolicies;
  List<Policy> get inactivePolicies => _inactivePolicies;
  PolicyLoadingStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get hasError => _status == PolicyLoadingStatus.error;
  bool get isLoading => _status == PolicyLoadingStatus.loading;
  bool get hasActivePolicies => _activePolicies.isNotEmpty;
  bool get hasInactivePolicies => _inactivePolicies.isNotEmpty;
  
  // Tüm poliçeleri yükle
  Future<void> loadPolicies() async {
    try {
      _status = PolicyLoadingStatus.loading;
      notifyListeners();
      
      _policies = await _policyService.getPolicies();
      _activePolicies = _policies.where((policy) => policy.isActive).toList();
      _inactivePolicies = _policies.where((policy) => !policy.isActive).toList();
      
      _status = PolicyLoadingStatus.loaded;
    } catch (e) {
      _status = PolicyLoadingStatus.error;
      _errorMessage = 'Poliçeler yüklenirken bir hata oluştu: $e';
    } finally {
      notifyListeners();
    }
  }
  
  // Aktif poliçeleri yükle
  Future<void> loadActivePolicies() async {
    try {
      _status = PolicyLoadingStatus.loading;
      notifyListeners();
      
      _activePolicies = await _policyService.getActivePolicies();
      
      _status = PolicyLoadingStatus.loaded;
    } catch (e) {
      _status = PolicyLoadingStatus.error;
      _errorMessage = 'Aktif poliçeler yüklenirken bir hata oluştu: $e';
    } finally {
      notifyListeners();
    }
  }
  
  // Pasif poliçeleri yükle
  Future<void> loadInactivePolicies() async {
    try {
      _status = PolicyLoadingStatus.loading;
      notifyListeners();
      
      _inactivePolicies = await _policyService.getInactivePolicies();
      
      _status = PolicyLoadingStatus.loaded;
    } catch (e) {
      _status = PolicyLoadingStatus.error;
      _errorMessage = 'Pasif poliçeler yüklenirken bir hata oluştu: $e';
    } finally {
      notifyListeners();
    }
  }
  
  // Yenileme işlemi
  Future<void> refreshPolicies() async {
    await loadPolicies();
  }
  
  // İlk kurulum
  void init() {
    loadPolicies();
  }
  
  // Veri formatları
  String formatAmount(double amount, String currency) {
    return '$amount $currency';
  }
  
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
} 