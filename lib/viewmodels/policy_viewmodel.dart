import 'package:flutter/material.dart';
import '../models/policy_model.dart';
import '../services/policy_service.dart';

enum PolicyViewState {
  idle,
  loading,
  loaded,
  error,
}

class PolicyViewModel with ChangeNotifier {
  final PolicyService _policyService = PolicyService();
  
  // Tüm poliçeler
  List<Policy> _policies = [];
  List<Policy> get policies => _policies;
  
  // Aktif poliçeler
  List<Policy> get activePolicies => 
      _policies.where((policy) => policy.status == 'Aktif').toList();
  
  // Pasif poliçeler
  List<Policy> get inactivePolicies => 
      _policies.where((policy) => policy.status != 'Aktif').toList();
  
  // ViewModel durumu
  PolicyViewState _state = PolicyViewState.idle;
  PolicyViewState get state => _state;
  
  // Hata mesajı
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  // Seçili sekme endeksi
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  set selectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
  
  // Belirli bir poliçenin detaylarını getirme
  Policy? _selectedPolicy;
  Policy? get selectedPolicy => _selectedPolicy;
  
  PolicyViewState _detailState = PolicyViewState.idle;
  PolicyViewState get detailState => _detailState;
  
  // Poliçeleri çekme
  Future<void> fetchPolicies() async {
    try {
      _state = PolicyViewState.loading;
      notifyListeners();
      
      final policies = await _policyService.getUserPolicies();
      
      _policies = policies;
      _state = PolicyViewState.loaded;
      
    } catch (e) {
      _state = PolicyViewState.error;
      _errorMessage = 'Poliçe bilgileri alınırken bir hata oluştu: $e';
      print(_errorMessage);
    } finally {
      notifyListeners();
    }
  }
  
  // Poliçeleri yenileme
  Future<void> refreshPolicies() async {
    await fetchPolicies();
  }
  
  // Poliçe durumuna göre filtreleme
  List<Policy> getFilteredPolicies() {
    if (_selectedTabIndex == 0) {
      return activePolicies;
    } else {
      return inactivePolicies;
    }
  }
  
  // Boş poliçe kontrolü
  bool get isPoliciesEmpty => _policies.isEmpty;
  
  // Aktif poliçe kontrolü
  bool get isActivePoliciesEmpty => activePolicies.isEmpty;
  
  // Pasif poliçe kontrolü
  bool get isInactivePoliciesEmpty => inactivePolicies.isEmpty;
  
  // Güncel seçili poliçe listesinin boş olup olmadığını kontrol etme
  bool get isCurrentTabEmpty {
    if (_selectedTabIndex == 0) {
      return isActivePoliciesEmpty;
    } else {
      return isInactivePoliciesEmpty;
    }
  }
  
  Future<void> fetchPolicyDetail(String policyId) async {
    try {
      _detailState = PolicyViewState.loading;
      notifyListeners();
      
      final policy = await _policyService.getPolicyDetail(policyId);
      
      if (policy != null) {
        _selectedPolicy = policy;
        _detailState = PolicyViewState.loaded;
      } else {
        _detailState = PolicyViewState.error;
        _errorMessage = 'Poliçe detayı bulunamadı';
      }
    } catch (e) {
      _detailState = PolicyViewState.error;
      _errorMessage = 'Poliçe detayı alınırken bir hata oluştu: $e';
      print(_errorMessage);
    } finally {
      notifyListeners();
    }
  }
} 