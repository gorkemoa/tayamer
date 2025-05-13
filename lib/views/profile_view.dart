import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'profile_detail_view.dart';
import 'notifications_view.dart';
import 'webview_screen.dart';

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

 Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.fabrikasigorta.com/iletisim');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // TODO: Hata durumunu kullanıcıya bildir (Snackbar vb.)
      print('Could not launch $url');
    }
  }


 Future<void> _office701launchURL() async {
    final Uri url = Uri.parse('https://www.office701.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // TODO: Hata durumunu kullanıcıya bildir (Snackbar vb.)
      print('Could not launch $url');
    }
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
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Hesabım',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        centerTitle: true,
        leading:  IconButton(
          icon: const Icon(FontAwesomeIcons.comments, color: Colors.white, size: 20),
          onPressed: () {
            final viewModel = context.read<OfferViewModel>();
            // Genel sohbet teklifini (id: -1) bul
            // Teklif listesi boşsa veya id -1 içermiyorsa try-catch kullan
            try {
              final generalChatOffer = viewModel.offers.firstWhere(
                (offer) => offer.id.toString() == '-1',
              );

              if (generalChatOffer.chatUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(
                      url: generalChatOffer.chatUrl,
                      title: 'Genel Sohbet',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Genel sohbet bağlantısı bulunamadı.')),
                );
              }
            } catch (e) {
              // Teklifin bulunamadığı durumları ele al
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Genel sohbet şu anda mevcut değil.')),
              );
              debugPrint("Genel sohbet offer bulunamadı: $e");
            }
          },
        ),   actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bell, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsView(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Bilgileri Bölümü
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    _user?.profilePhoto ?? 'https://via.placeholder.com/150',
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  // Kullanıcı Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adınız Soyadınız',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          width: double.infinity,
                          child: Text(
                            _user?.userFullname ?? 'Adınız Soyadınız',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Text(
                          'Kullanıcı Adınız',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          width: double.infinity,
                          child: Text(
                            _user?.username ?? 'Kullanıcı Adınız',
                            style: const TextStyle(fontSize: 14),
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
              iconSize: 22,
              titleSize: 14,
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
              icon: Icons.public,
              title: 'Yardım',
              iconSize: 22,
              titleSize: 14,
              onTap: () {
                _launchURL();
              },
            ),
            
            // Alt bilgiler
            const SizedBox(height: 16),
            Center(
             child: InkWell(
               onTap: _office701launchURL,
                child:  Text(
                  'Office701 Bilgi Teknolojileri © 2025',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${_user?.userVersion}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _logout(context),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    double iconSize = 28,
    double titleSize = 16,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 1.5,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        leading: Icon(
          icon,
          color: Colors.black54,
          size: iconSize,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
          size: 22,
        ),
        onTap: onTap,
      ),
    );
  }
} 