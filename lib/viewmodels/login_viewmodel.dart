import '../services/auth_service.dart';

class LoginViewModel {
  final AuthService _authService;

  LoginViewModel(this._authService);

  // API üzerinden giriş yapar
  Future<bool> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  // Kullanıcının giriş yapmış olup olmadığını kontrol eder
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  // Kullanıcıyı sistemden çıkarır
  Future<void> logout() async {
    await _authService.logout();
  }

  // Kullanıcı bilgilerini getirir
  Future<Map<String, dynamic>> getUserData() async {
    return await _authService.getUserData();
  }

  // Kullanıcı token'ını getirir
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  // Bu metot şu an kullanılmıyor
  Future<bool> register(String name, String email, String password) async {
    return await _authService.register(name, email, password);
  }
} 