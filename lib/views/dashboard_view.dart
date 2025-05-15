import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayamer/views/notifications_view.dart';
import 'package:tayamer/views/webview_screen.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../viewmodels/offer_viewmodel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final UserService _userService = UserService();
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
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard: Kullanıcı bilgileri alınırken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E3A8A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    // Kullanıcı istatistikleri veya null değerleri kullan
    final statistics = _user?.statistics;
    final totalOffer = statistics?.totalOffer.toString();
    final totalPolicy = statistics?.totalPolicy.toString();
    
    // Para formatı kaldırıldı - verileri olduğu gibi gösterme
    final monthlyAmount = statistics?.monthlyAmount ?? '';
    final totalAmount = statistics?.totalAmount ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.comments , color: Colors.white),
          onPressed: () {
            final viewModel = context.read<OfferViewModel>();
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Genel sohbet şu anda mevcut değil.')),
              );
              debugPrint("Genel sohbet offer bulunamadı: $e");
            }
          },
        ),
        title: Image.network('https://tayamer.com/img/amblem.png', height: 40, color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bell, color: Colors.white),
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
      body: Column(
        children: [
          // Profil bölümü
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: _user?.profilePhoto != null && _user!.profilePhoto.isNotEmpty
                      ? Image.network(
                          _user!.profilePhoto,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _user?.userFullname ?? 'Görkem ÖZTÜRK',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _user?.userEmail ?? 'gorkem.ozturk@office701.com',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // İstatistik kartları
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İstatistik kartları
                  Row(
                    children: [
                      // Toplam Teklif
                      Expanded(
                        child: _buildInfoCard('Toplam Teklif', totalOffer ?? '0'),
                      ),
                      const SizedBox(width: 15),
                      // Toplam Poliçe
                      Expanded(
                        child: _buildInfoCard('Toplam Poliçe', totalPolicy ?? '0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Alt satır kartları
                  Row(
                    children: [
                      // Aylık Tayamer Puanı
                      Expanded(
                        child: _buildInfoCard('Aylık Tayamer Puanı', monthlyAmount),
                      ),
                      const SizedBox(width: 15),
                      // Toplam Tayamer Puanı
                      Expanded(
                        child: _buildInfoCard('Toplam Tayamer Puanı', totalAmount),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 