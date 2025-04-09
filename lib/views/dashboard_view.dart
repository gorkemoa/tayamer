import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tayamer/views/notifications_view.dart';
import 'package:tayamer/views/webview_screen.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../viewmodels/offer_viewmodel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  int _selectedIndex = 0; // Alt menü için seçili indeks

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Burada farklı sayfalara yönlendirme yapılabilir
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Kullanıcı istatistikleri veya null değerleri kullan
    final statistics = _user?.statistics;
    final totalOffer = statistics?.totalOffer.toString() ?? '2';
    final totalPolicy = statistics?.totalPolicy.toString() ?? '1';
    
    // Para formatında gösterim için 
    final monthlyAmount = _formatAmount(statistics?.monthlyAmount ?? '9000.00');
    final totalAmount = _formatAmount(statistics?.totalAmount ?? '9000.00');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(250),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            color: const Color(0xFF1E3A73),
          ),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 250,
            title: Column(
              children: [
                Image.network('https://tayamer.com/img/amblem.png', height: 50),
                const SizedBox(height: 10),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: _user?.profilePhoto != null && _user!.profilePhoto.isNotEmpty
                      ? Image.network(
                          _user!.profilePhoto,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _user?.userFullname ?? 'EXAMPLE NAME',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _user?.userEmail ?? 'EXAMPLE EMAIL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İstatistik kartları
            Row(
              children: [
                // Toplam Teklif
                Expanded(
                  child: _buildInfoCard('Toplam Teklif', totalOffer),
                ),
                const SizedBox(width: 15),
                // Toplam Poliçe
                Expanded(
                  child: _buildInfoCard('Toplam Poliçe', totalPolicy),
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
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    // "9000.00" formatını "9.000,00" formatına dönüştürmek için
    try {
      // Önce noktadan ayırıp virgüle çevirelim
      var parts = amount.split('.');
      String integer = parts[0];
      String fraction = parts.length > 1 ? parts[1] : '00';
      
      // Binlik ayracı için
      String formattedInteger = '';
      int counter = 0;
      for (int i = integer.length - 1; i >= 0; i--) {
        counter++;
        formattedInteger = integer[i] + formattedInteger;
        if (counter % 3 == 0 && i > 0) {
          formattedInteger = '.' + formattedInteger;
        }
      }
      
      return '$formattedInteger,$fraction';
    } catch (e) {
      return amount;
    }
  }
} 