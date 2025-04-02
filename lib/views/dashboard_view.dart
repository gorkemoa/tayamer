import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

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
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard: Kullanıcı bilgileri alınırken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
    final totalOffer = statistics?.totalOffer.toString() ?? '0';
    final totalPolicy = statistics?.totalPolicy.toString() ?? '0';
    final monthlyAmount = statistics?.monthlyAmount ?? '0,00';
    final totalAmount = statistics?.totalAmount ?? '0,00';

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'İstatistiklerim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Üst satır kartları
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
          const SizedBox(height: 30),
          // Son hareketler
          const Text(
            'Son Hareketler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: _buildEmptyActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(
            'Henüz bir hareket bulunmuyor',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
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
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 