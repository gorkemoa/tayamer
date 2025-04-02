import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pop(context); // Dialog'u kapat
                // Ana sayfaya yönlendir ve tüm geçmişi temizle
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/', 
                  (route) => false
                );
              }
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          // Profil Resmi ve Kullanıcı Adı
          _buildProfileHeader(),
          const SizedBox(height: 24),
          
          // Ayarlar Bölümü
          const Text(
            'Hesap Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(),
          
          const SizedBox(height: 24),
          // Destek Bölümü
          const Text(
            'Destek',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildSupportCard(),
          
          const SizedBox(height: 24),
          // Hesap İşlemleri
          const Text(
            'Hesap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildAccountCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.person,
                size: 30,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user?.userFullname ?? 'Kullanıcı Adı',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.userEmail ?? 'email@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Profil Bilgilerim',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil bilgileri yakında eklenecek')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Bildirim Ayarları',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildirim ayarları yakında eklenecek')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Güvenlik',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güvenlik ayarları yakında eklenecek')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Yardım Merkezi',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yardım merkezi yakında eklenecek')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            icon: Icons.message_outlined,
            title: 'Bize Ulaşın',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İletişim bilgileri yakında eklenecek')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'Uygulama Hakkında',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uygulama bilgileri yakında eklenecek')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Çıkış Yap',
            color: Colors.red,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 