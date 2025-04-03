import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'profile_detail_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = await _userService.getUserInfo();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Profil: Kullanıcı bilgileri alınırken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      // Ana sayfaya yönlendir ve tüm geçmişi temizle
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/', 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3567),
        title: const Text(
          'Hesabım',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Bilgileri Bölümü
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Fotoğrafı
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Kullanıcı Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adınız Soyadınız',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          width: double.infinity,
                          child: Text(
                            _user?.userFullname ?? 'Adınız Soyadınız',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Text(
                          'Kullanıcı Adınız',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          width: double.infinity,
                          child: Text(
                            _user?.username ?? 'Kullanıcı Adınız',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menü Öğeleri
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Profilim',
              onTap: () {
                if (_user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileDetailView(user: _user!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgileri yüklenemedi.')),
                  );
                }
              },
            ),
            
            _buildMenuItem(
              icon: Icons.sms_outlined,
              title: 'SMS Taleplerim',
              onTap: () {},
            ),
            
            _buildMenuItem(
              icon: Icons.public,
              title: 'Yardım',
              onTap: () {},
            ),
            
            // Alt bilgiler
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Office701 Bilgi Teknolojileri © 2025',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'v2.3.7',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _logout(context),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          icon,
          color: Colors.black54,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
} 