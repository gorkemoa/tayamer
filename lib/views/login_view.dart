import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../viewmodels/login_viewmodel.dart';
import 'home_view.dart';
import '../theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = LoginViewModel(AuthService());
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Test için kullanıcı adı ve şifre otomatik doldurulabilir
    // _emailController.text = 'gorkemozturk';
    // _passwordController.text = 'GO5235010';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        print('Giriş denemesi: ${_emailController.text.trim()}');
        final success = await _viewModel.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (success) {
          // Giriş başarılı, ana sayfaya yönlendir
          print('Giriş başarılı! Ana sayfaya yönlendiriliyor...');
          if (mounted) {
            // Kullanıcı bilgilerini önbelleğe alma işlemi zaten auth_service içinde yapıldı
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeView()),
            );
          }
        } else {
          // Giriş başarısız
          print('Giriş başarısız: Kullanıcı adı veya şifre hatalı');
          setState(() {
            _errorMessage = 'Kullanıcı adı veya şifre hatalı';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Bağlantı hatası: $e');
        setState(() {
          _errorMessage = 'Sunucuya bağlanırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
          _isLoading = false;
        });
      }
    }
  }
  
  // Logo widget'ı
  Widget _buildLogo() {
    return Image.asset(
      'assets/images/tayamer-logo.png',
      width: 280,
      height: 180,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Logo alanı - üst kısmı tamamen kaplayan turuncu arka plan
      Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: appTheme.colorScheme.secondary, // Turuncu arka plan
    borderRadius: BorderRadius.circular(24), // Köşeleri yumuşat
  ),
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 40.0),
      child: Column(
        children: [
          // Tayamer logo
          _buildLogo(),
        ],
      ),
    ),
  ),
),
          // Form alanı
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MÜŞTERİ GİRİŞİ',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0622C), // Secondary color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Lütfen size iletilen kullanıcı adı ve şifreniz ile\ngiriş yapınız.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Form başlangıcı
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Kullanıcı adı alanı
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, color: Colors.grey[700]),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        hintText: 'Kullanıcı Adınız',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Lütfen kullanıcı adınızı girin';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Şifre alanı
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, color: Colors.grey[700]),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Şifreniz',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 18),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Lütfen şifrenizi girin';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Giriş butonu
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C8BA1), // Gri-mavi buton rengi
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 